import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:gic/models/admin_user.dart';
import 'package:gic/services/audit_log_service.dart';
import 'package:gic/services/password_security.dart';
import 'package:gic/services/supabase_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String _adminPasswordKey = 'super_admin_custom_password_hash_v2';
  static const String _legacyAdminPasswordKey = 'super_admin_custom_password';
  static const String _localEmployeesKey = 'local_stored_employees_v1';
  static const String _lockoutPrefKey = 'cp_login_lockout_state_v1';
  static const String _cloudRbacServiceKey = '__rbac_admin_users_v1__';

  static AdminUser? _currentUser;
  static int _failedAttempts = 0;
  static DateTime? _lockoutUntil;

  static AdminUser? get currentUser => _currentUser;
  static bool get isLoggedIn => _currentUser != null;

  static int get failedAttempts => _failedAttempts;
  static bool get isLockedOut =>
      _lockoutUntil != null && DateTime.now().isBefore(_lockoutUntil!);
  static int get lockoutRemainingSeconds =>
      isLockedOut ? _lockoutUntil!.difference(DateTime.now()).inSeconds : 0;

  /// استرجاع حالة القفل من التخزين المحلي لمنع التجاوز بإعادة تشغيل البرنامج
  static Future<void> loadLockoutState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_lockoutPrefKey);
      if (raw != null && raw.isNotEmpty) {
        final data = jsonDecode(raw) as Map<String, dynamic>;
        _failedAttempts = (data['attempts'] as num?)?.toInt() ?? 0;
        final untilStr = data['lockedUntil']?.toString();
        if (untilStr != null && untilStr.isNotEmpty) {
          final parsed = DateTime.tryParse(untilStr);
          if (parsed != null && DateTime.now().isBefore(parsed)) {
            _lockoutUntil = parsed;
          } else {
            _lockoutUntil = null;
          }
        }
      }
    } catch (_) {}
  }

  static Future<void> _saveLockoutState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _lockoutPrefKey,
        jsonEncode({
          'attempts': _failedAttempts,
          'lockedUntil': _lockoutUntil?.toIso8601String(),
        }),
      );
    } catch (_) {}
  }

  /// تحويل الأرقام العربية إلى إنجليزية لتجنب أخطاء لوحة المفاتيح
  static String normalizeArabicNumbers(String input) {
    const arabic = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    const english = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    for (int i = 0; i < 10; i++) {
      input = input.replaceAll(arabic[i], english[i]);
    }
    return input;
  }

  /// الحصول على هاش كلمة المرور الحالية للمدير العام (من السحابة أو المحلي أو الافتراضي المشفر)
  static Future<String> getSuperAdminPasswordHash() async {
    final prefs = await SharedPreferences.getInstance();

    // 1. ترحيل أي كلمة سر نصية قديمة محفوظة محلياً إلى هاش مشفر وحذف النص الصريح
    final legacyPlain = prefs.getString(_legacyAdminPasswordKey);
    if (legacyPlain != null && legacyPlain.isNotEmpty) {
      final migratedHash = PasswordSecurity.hashPassword(legacyPlain);
      await prefs.setString(_adminPasswordKey, migratedHash);
      await prefs.remove(_legacyAdminPasswordKey);
    }

    // 2. محاولة جلب الهاش المحدث من السحابة لتوحيد كلمة سر المدير عبر الأجهزة
    try {
      final cloudStore = await _fetchCloudRbacStore();
      final cloudAdminHash = cloudStore['super_admin_password_hash']?.toString();
      if (cloudAdminHash != null && cloudAdminHash.isNotEmpty) {
        await prefs.setString(_adminPasswordKey, cloudAdminHash);
        return cloudAdminHash;
      }
    } catch (_) {}

    final storedHash = prefs.getString(_adminPasswordKey);
    if (storedHash != null && storedHash.isNotEmpty) {
      return storedHash;
    }

    final defaultHash = PasswordSecurity.hashPassword('admin123');
    await prefs.setString(_adminPasswordKey, defaultHash);
    return defaultHash;
  }

  /// تغيير كلمة المرور للمدير العام الحالي (تُحفظ مشفرة بـ Salted HMAC-SHA256)
  static Future<void> changeCurrentAdminPassword(String newPassword) async {
    final cleanPass = newPassword.trim();
    if (cleanPass.length < 6) {
      throw Exception('كلمة المرور يجب أن لا تقل عن 6 أحرف أو أرقام');
    }

    final hashedPass = PasswordSecurity.hashPassword(cleanPass);

    // 1. حفظ الهاش المشفر في التخزين المحلي فوراً
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_adminPasswordKey, hashedPass);
    await prefs.remove(_legacyAdminPasswordKey);

    // 2. حفظ في السجل السحابي الموحد
    try {
      final store = await _fetchCloudRbacStore();
      store['super_admin_password_hash'] = hashedPass;
      await _saveCloudRbacStore(store);
    } catch (_) {}

    // 3. محاولة التحديث في جدول admin_users إن وُجد
    try {
      if (_currentUser != null) {
        await AdminSupabase.client
            .from('admin_users')
            .update({'password': hashedPass})
            .eq('username', _currentUser!.username);
      }
    } catch (e) {
      debugPrint('⚠️ تم حفظ كلمة المرور المشفرة سحابياً ومحلياً: $e');
    }

    // 4. تحديث الكائن في الذاكرة بدون كلمة سر نصية
    if (_currentUser != null) {
      _currentUser = AdminUser(
        id: _currentUser!.id,
        username: _currentUser!.username,
        password: null,
        fullName: _currentUser!.fullName,
        role: _currentUser!.role,
        phone: _currentUser!.phone,
        isActive: _currentUser!.isActive,
        permissions: _currentUser!.permissions,
        createdAt: _currentUser!.createdAt,
      );
    }

    await AuditLogService.log(
      actionType: 'UPDATE',
      module: 'النظام',
      targetService: 'كلمة المرور',
      description: 'قام مدير النظام بتغيير وتشفير كلمة المرور الخاصة بحسابه بنجاح',
    );
  }

  /// قراءة مخزن الموظفين السحابي الموحد من system_instructions
  static Future<Map<String, dynamic>> _fetchCloudRbacStore() async {
    try {
      final res = await AdminSupabase.client
          .from('system_instructions')
          .select('steps')
          .eq('service_key', _cloudRbacServiceKey)
          .maybeSingle();
      if (res != null && res['steps'] != null) {
        final raw = res['steps'];
        if (raw is Map) return Map<String, dynamic>.from(raw);
        if (raw is String && raw.isNotEmpty) {
          final decoded = jsonDecode(raw);
          if (decoded is Map) return Map<String, dynamic>.from(decoded);
        }
      }
    } catch (_) {}
    return {'employees': <dynamic>[]};
  }

  /// حفظ مخزن الموظفين السحابي الموحد في system_instructions
  static Future<void> _saveCloudRbacStore(Map<String, dynamic> store) async {
    try {
      await AdminSupabase.client.from('system_instructions').upsert(
        {
          'service_key': _cloudRbacServiceKey,
          'title': 'بيانات وصلاحيات موظفي النظام (مشفر)',
          'subtitle': 'RBAC Encrypted Store',
          'steps': jsonEncode(store),
          'updated_at': DateTime.now().toIso8601String(),
        },
        onConflict: 'service_key',
      );
    } catch (e) {
      debugPrint('Cloud RBAC sync note: $e');
    }
  }

  /// جلب الموظفين المخزنين (دمج السحابي + المحلي مع تشفير أي كلمات سر قديمة)
  static Future<List<AdminUser>> getLocalEmployees() async {
    final Map<String, AdminUser> byUsername = {};

    // 1. الجلب من المخزن السحابي الموحد أولاً
    try {
      final store = await _fetchCloudRbacStore();
      final cloudList = store['employees'];
      if (cloudList is List) {
        for (final item in cloudList) {
          if (item is Map) {
            final map = Map<String, dynamic>.from(item);
            if (map['password'] != null &&
                map['password'].toString().isNotEmpty &&
                !PasswordSecurity.isHashed(map['password'].toString())) {
              map['password'] = PasswordSecurity.hashPassword(map['password'].toString());
            }
            final emp = AdminUser.fromJson(map);
            if (emp.username.isNotEmpty) {
              byUsername[emp.username.toLowerCase()] = emp;
            }
          }
        }
      }
    } catch (_) {}

    // 2. دمج المخزون المحلي وترقية أي كلمات سر غير مشفرة
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_localEmployeesKey);
      if (raw != null && raw.isNotEmpty) {
        bool migrated = false;
        final list = jsonDecode(raw) as List;
        for (final item in list) {
          if (item is Map) {
            final map = Map<String, dynamic>.from(item);
            final pw = map['password']?.toString() ?? '';
            if (pw.isNotEmpty && !PasswordSecurity.isHashed(pw)) {
              map['password'] = PasswordSecurity.hashPassword(pw);
              migrated = true;
            }
            final emp = AdminUser.fromJson(map);
            final key = emp.username.toLowerCase();
            if (emp.username.isNotEmpty && !byUsername.containsKey(key)) {
              byUsername[key] = emp;
            }
          }
        }
        if (migrated) {
          final updatedRaw = jsonEncode(byUsername.values.map((e) => e.toJson()).toList());
          await prefs.setString(_localEmployeesKey, updatedRaw);
        }
      }
    } catch (e) {
      debugPrint('Error reading local employees: $e');
    }

    return byUsername.values.toList();
  }

  /// حفظ موظف (مع تشفير كلمة المرور ومزامنتها سحابياً ومحلياً)
  static Future<void> saveLocalEmployee(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    final employees = await getLocalEmployees();

    final id = data['id'] ?? 'emp_${DateTime.now().millisecondsSinceEpoch}';
    data['id'] = id;

    final existingIndex = employees.indexWhere(
      (e) =>
          e.id == id ||
          e.username.toLowerCase() == (data['username']?.toString().toLowerCase() ?? ''),
    );

    // إذا تم تمرير كلمة مرور جديدة نشفرها، وإلا نحتفظ بالهاش السابق للموظف عند التعديل
    final rawPass = data['password']?.toString().trim() ?? '';
    if (rawPass.isNotEmpty) {
      data['password'] = PasswordSecurity.hashPassword(rawPass);
    } else if (existingIndex >= 0) {
      data['password'] = employees[existingIndex].password;
    }

    final newEmp = AdminUser.fromJson(data);

    if (existingIndex >= 0) {
      employees[existingIndex] = newEmp;
    } else {
      employees.insert(0, newEmp);
    }

    final serialized = employees.map((e) => e.toJson()).toList();
    await prefs.setString(_localEmployeesKey, jsonEncode(serialized));

    try {
      final store = await _fetchCloudRbacStore();
      store['employees'] = serialized;
      await _saveCloudRbacStore(store);
    } catch (_) {}
  }

  /// حذف موظف من التخزين السحابي والمحلي
  static Future<void> deleteLocalEmployee(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final employees = await getLocalEmployees();
    employees.removeWhere((e) => e.id == id);
    final serialized = employees.map((e) => e.toJson()).toList();
    await prefs.setString(_localEmployeesKey, jsonEncode(serialized));

    try {
      final store = await _fetchCloudRbacStore();
      store['employees'] = serialized;
      await _saveCloudRbacStore(store);
    } catch (_) {}
  }

  /// تبديل حالة موظف سحابياً ومحلياً
  static Future<void> toggleLocalEmployeeStatus(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final employees = await getLocalEmployees();
    final index = employees.indexWhere((e) => e.id == id);
    if (index >= 0) {
      final cur = employees[index];
      employees[index] = AdminUser(
        id: cur.id,
        username: cur.username,
        password: cur.password,
        fullName: cur.fullName,
        role: cur.role,
        phone: cur.phone,
        isActive: !cur.isActive,
        permissions: cur.permissions,
        createdAt: cur.createdAt,
      );
      final serialized = employees.map((e) => e.toJson()).toList();
      await prefs.setString(_localEmployeesKey, jsonEncode(serialized));

      try {
        final store = await _fetchCloudRbacStore();
        store['employees'] = serialized;
        await _saveCloudRbacStore(store);
      } catch (_) {}
    }
  }

  /// تسجيل الدخول والتحقق المشفر من حساب الموظف أو المدير مع حماية ضد هجمات التخمين
  static Future<bool> login(String username, String password) async {
    await loadLockoutState();
    if (isLockedOut) {
      final secs = lockoutRemainingSeconds;
      throw Exception(
        'تم قفل تسجيل الدخول مؤقتاً لحماية النظام بسبب تكرار المحاولات الخاطئة. يرجى الانتظار $secs ثانية',
      );
    }

    final cleanUsername = normalizeArabicNumbers(username.trim());
    final cleanPassword = normalizeArabicNumbers(password.trim());

    if (cleanUsername.isEmpty || cleanPassword.isEmpty) {
      throw Exception('يرجى إدخال اسم المستخدم وكلمة المرور');
    }

    Future<void> recordFailedAttempt() async {
      _failedAttempts++;
      if (_failedAttempts >= 5) {
        _lockoutUntil = DateTime.now().add(const Duration(seconds: 60));
        _failedAttempts = 0;
      }
      await _saveLockoutState();
    }

    Future<void> clearFailedAttempts() async {
      _failedAttempts = 0;
      _lockoutUntil = null;
      await _saveLockoutState();
    }

    // 1. التحقق المشفر من حساب المدير العام
    final superAdminHash = await getSuperAdminPasswordHash();
    if (cleanUsername.toLowerCase() == 'admin') {
      if (PasswordSecurity.verifyPassword(cleanPassword, superAdminHash)) {
        await clearFailedAttempts();
        _currentUser = AdminUser.defaultSuperAdmin(password: '');

        await AuditLogService.log(
          actionType: 'LOGIN',
          module: 'النظام',
          description: 'تسجيل دخول ناجح لمدير النظام العام',
        );

        return true;
      } else {
        await recordFailedAttempt();
        if (isLockedOut) {
          throw Exception('تم قفل تسجيل الدخول لمدة 60 ثانية بسبب تكرار المحاولات الخاطئة');
        }
        throw Exception('اسم المستخدم أو كلمة المرور غير صحيحة');
      }
    }

    // 2. التحقق من جدول admin_users في Supabase إن كان متاحاً
    try {
      final res = await AdminSupabase.client
          .from('admin_users')
          .select()
          .eq('username', cleanUsername)
          .maybeSingle();

      if (res != null) {
        final storedPw = res['password']?.toString() ?? '';
        if (!PasswordSecurity.verifyPassword(cleanPassword, storedPw)) {
          await recordFailedAttempt();
          if (isLockedOut) {
            throw Exception('تم قفل تسجيل الدخول لمدة 60 ثانية بسبب تكرار المحاولات الخاطئة');
          }
          throw Exception('اسم المستخدم أو كلمة المرور غير صحيحة');
        }

        // ترقية كلمة سر الموظف في القاعدة إلى مشفرة إن كانت نصية
        if (!PasswordSecurity.isHashed(storedPw)) {
          try {
            await AdminSupabase.client
                .from('admin_users')
                .update({'password': PasswordSecurity.hashPassword(cleanPassword)})
                .eq('id', res['id']);
          } catch (_) {}
        }

        final user = AdminUser.fromJson(res);
        if (!user.isActive) {
          throw Exception('هذا الحساب معطل حالياً من قبل مدير النظام');
        }

        await clearFailedAttempts();
        _currentUser = user;

        await AuditLogService.log(
          actionType: 'LOGIN',
          module: 'النظام',
          description: 'تسجيل دخول ناجح للموظف: ${user.fullName} (${user.username})',
        );

        return true;
      }
    } catch (e) {
      if (e.toString().contains('غير صحيحة') ||
          e.toString().contains('معطل') ||
          e.toString().contains('قفل')) {
        rethrow;
      }
    }

    // 3. التحقق من الموظفين في المخزن السحابي/المحلي المشفر
    final localList = await getLocalEmployees();
    final matched = localList
        .where((e) => e.username.toLowerCase() == cleanUsername.toLowerCase())
        .toList();
    if (matched.isNotEmpty) {
      final emp = matched.first;
      if (!PasswordSecurity.verifyPassword(cleanPassword, emp.password)) {
        await recordFailedAttempt();
        if (isLockedOut) {
          throw Exception('تم قفل تسجيل الدخول لمدة 60 ثانية بسبب تكرار المحاولات الخاطئة');
        }
        throw Exception('اسم المستخدم أو كلمة المرور غير صحيحة');
      }
      if (!emp.isActive) {
        throw Exception('هذا الحساب معطل حالياً من قبل مدير النظام');
      }

      await clearFailedAttempts();
      _currentUser = emp;

      await AuditLogService.log(
        actionType: 'LOGIN',
        module: 'النظام',
        description: 'تسجيل دخول ناجح للموظف: ${emp.fullName} (${emp.username})',
      );

      return true;
    }

    await recordFailedAttempt();
    if (isLockedOut) {
      throw Exception('تم قفل تسجيل الدخول لمدة 60 ثانية بسبب تكرار المحاولات الخاطئة');
    }
    throw Exception('اسم المستخدم أو كلمة المرور غير صحيحة');
  }

  /// تسجيل الخروج
  static Future<void> logout() async {
    if (_currentUser != null) {
      await AuditLogService.log(
        actionType: 'LOGOUT',
        module: 'النظام',
        description: 'تسجيل خروج المستخدم: ${_currentUser!.fullName}',
      );
    }
    _currentUser = null;
  }
}
