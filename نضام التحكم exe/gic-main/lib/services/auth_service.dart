import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:gic/models/admin_user.dart';
import 'package:gic/services/audit_log_service.dart';
import 'package:gic/services/supabase_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String _adminPasswordKey = 'super_admin_custom_password';
  static const String _localEmployeesKey = 'local_stored_employees_v1';

  static AdminUser? _currentUser;
  static int _failedAttempts = 0;
  static DateTime? _lockoutUntil;

  static AdminUser? get currentUser => _currentUser;
  static bool get isLoggedIn => _currentUser != null;

  static int get failedAttempts => _failedAttempts;
  static bool get isLockedOut => _lockoutUntil != null && DateTime.now().isBefore(_lockoutUntil!);
  static int get lockoutRemainingSeconds => isLockedOut ? _lockoutUntil!.difference(DateTime.now()).inSeconds : 0;

  /// تحويل الأرقام العربية إلى إنجليزية لتجنب أخطاء لوحة المفاتيح
  static String normalizeArabicNumbers(String input) {
    const arabic = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    const english = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    for (int i = 0; i < 10; i++) {
      input = input.replaceAll(arabic[i], english[i]);
    }
    return input;
  }

  /// الحصول على كلمة المرور الحالية للمدير العام (المحفوظة محلياً أو الافتراضية)
  static Future<String> getSuperAdminPassword() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_adminPasswordKey) ?? 'admin123';
  }

  /// تغيير كلمة المرور للمدير العام الحالي
  static Future<void> changeCurrentAdminPassword(String newPassword) async {
    final cleanPass = newPassword.trim();
    if (cleanPass.length < 3) {
      throw Exception('كلمة المرور يجب أن لا تقل عن 3 أحرف');
    }

    // 1. حفظ في التخزين المحلي فوراً
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_adminPasswordKey, cleanPass);

    // 2. محاولة التحديث في جدول Supabase إن وُجد
    try {
      if (_currentUser != null) {
        await AdminSupabase.client
            .from('admin_users')
            .update({'password': cleanPass})
            .eq('username', _currentUser!.username);
      }
    } catch (e) {
      debugPrint('⚠️ لم نتمكن من التحديث في Supabase (تم الحفظ محلياً): $e');
    }

    // 3. تحديث الكائن في الذاكرة
    if (_currentUser != null) {
      _currentUser = AdminUser(
        id: _currentUser!.id,
        username: _currentUser!.username,
        password: cleanPass,
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
      description: 'قام مدير النظام بتغيير كلمة المرور الخاصة بحسابه بنجاح',
    );
  }

  /// جلب الموظفين المخزنين محلياً (Fallback)
  static Future<List<AdminUser>> getLocalEmployees() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_localEmployeesKey);
      if (raw == null || raw.isEmpty) return [];
      final list = jsonDecode(raw) as List;
      return list.map((e) => AdminUser.fromJson(Map<String, dynamic>.from(e))).toList();
    } catch (e) {
      debugPrint('Error reading local employees: $e');
      return [];
    }
  }

  /// حفظ موظف في التخزين المحلي
  static Future<void> saveLocalEmployee(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    final employees = await getLocalEmployees();

    final id = data['id'] ?? 'loc_${DateTime.now().millisecondsSinceEpoch}';
    data['id'] = id;

    final existingIndex = employees.indexWhere((e) => e.id == id || e.username == data['username']);
    final newEmp = AdminUser.fromJson(data);

    if (existingIndex >= 0) {
      employees[existingIndex] = newEmp;
    } else {
      employees.insert(0, newEmp);
    }

    final raw = jsonEncode(employees.map((e) => e.toJson()).toList());
    await prefs.setString(_localEmployeesKey, raw);
  }

  /// حذف موظف من التخزين المحلي
  static Future<void> deleteLocalEmployee(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final employees = await getLocalEmployees();
    employees.removeWhere((e) => e.id == id);
    final raw = jsonEncode(employees.map((e) => e.toJson()).toList());
    await prefs.setString(_localEmployeesKey, raw);
  }

  /// تبديل حالة موظف محلياً
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
      final raw = jsonEncode(employees.map((e) => e.toJson()).toList());
      await prefs.setString(_localEmployeesKey, raw);
    }
  }

  /// تسجيل الدخول والتحقق من حساب الموظف أو المدير مع حماية ضد هجمات التخمين
  static Future<bool> login(String username, String password) async {
    if (isLockedOut) {
      final secs = lockoutRemainingSeconds;
      throw Exception('تم قفل تسجيل الدخول مؤقتاً لحماية النظام بسبب تكرار المحاولات الخاطئة. يرجى الانتظار $secs ثانية');
    }

    final cleanUsername = normalizeArabicNumbers(username.trim());
    final cleanPassword = normalizeArabicNumbers(password.trim());

    if (cleanUsername.isEmpty || cleanPassword.isEmpty) {
      throw Exception('يرجى إدخال اسم المستخدم وكلمة المرور');
    }

    void recordFailedAttempt() {
      _failedAttempts++;
      if (_failedAttempts >= 5) {
        _lockoutUntil = DateTime.now().add(const Duration(seconds: 60));
        _failedAttempts = 0;
      }
    }

    // 1. التحقق من حساب المدير العام (الافتراضي أو المخصص)
    final superAdminPass = await getSuperAdminPassword();
    if (cleanUsername.toLowerCase() == 'admin') {
      if (cleanPassword == superAdminPass) {
        _failedAttempts = 0;
        _lockoutUntil = null;
        _currentUser = AdminUser.defaultSuperAdmin(password: superAdminPass);

        await AuditLogService.log(
          actionType: 'LOGIN',
          module: 'النظام',
          description: 'تسجيل دخول ناجح لمدير النظام العام',
        );

        return true;
      } else {
        recordFailedAttempt();
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
        if (res['password'] != cleanPassword) {
          recordFailedAttempt();
          if (isLockedOut) {
            throw Exception('تم قفل تسجيل الدخول لمدة 60 ثانية بسبب تكرار المحاولات الخاطئة');
          }
          throw Exception('اسم المستخدم أو كلمة المرور غير صحيحة');
        }

        final user = AdminUser.fromJson(res);
        if (!user.isActive) {
          throw Exception('هذا الحساب معطل حالياً من قبل مدير النظام');
        }

        _failedAttempts = 0;
        _lockoutUntil = null;
        _currentUser = user;

        await AuditLogService.log(
          actionType: 'LOGIN',
          module: 'النظام',
          description: 'تسجيل دخول ناجح للموظف: ${user.fullName} (${user.username})',
        );

        return true;
      }
    } catch (e) {
      debugPrint('⚠️ استعلام Supabase: $e');
      if (e.toString().contains('غير صحيحة') || e.toString().contains('معطل') || e.toString().contains('قفل')) {
        rethrow;
      }
    }

    // 3. التحقق من الموظفين المخزنين محلياً (Local Fallback)
    final localList = await getLocalEmployees();
    final matched = localList.where((e) => e.username.toLowerCase() == cleanUsername.toLowerCase()).toList();
    if (matched.isNotEmpty) {
      final emp = matched.first;
      if (emp.password != cleanPassword) {
        recordFailedAttempt();
        if (isLockedOut) {
          throw Exception('تم قفل تسجيل الدخول لمدة 60 ثانية بسبب تكرار المحاولات الخاطئة');
        }
        throw Exception('اسم المستخدم أو كلمة المرور غير صحيحة');
      }
      if (!emp.isActive) {
        throw Exception('هذا الحساب معطل حالياً من قبل مدير النظام');
      }

      _failedAttempts = 0;
      _lockoutUntil = null;
      _currentUser = emp;

      await AuditLogService.log(
        actionType: 'LOGIN',
        module: 'النظام',
        description: 'تسجيل دخول ناجح للموظف (محلياً): ${emp.fullName}',
      );

      return true;
    }

    recordFailedAttempt();
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
