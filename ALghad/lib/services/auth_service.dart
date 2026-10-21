import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/app_models.dart';
import 'password_security.dart';

class AuthService {
  static const String _sessionKey = 'current_student_session';
  static const String _lockoutKey = 'student_lockout_data';

  /// تحويل الأرقام العربية إلى إنجليزية
  static String normalizeDigits(String input) {
    const arabic = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    const english = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    for (int i = 0; i < 10; i++) {
      input = input.replaceAll(arabic[i], english[i]);
    }
    return input;
  }

  // 1. القواعد الصارمة على الحقول
  static String? validateAcademicId(String? id) {
    if (id == null || id.trim().isEmpty) {
      return 'الرقم الأكاديمي إجباري';
    }
    final trimmed = normalizeDigits(id.trim());
    if (trimmed.length != 10 || !RegExp(r'^\d{10}$').hasMatch(trimmed)) {
      return 'الرقم الأكاديمي يجب أن يتكون من 10 أرقام بالضبط';
    }
    return null;
  }

  static String? validatePassword(String? password) {
    if (password == null || password.trim().isEmpty) {
      return 'كلمة السر إجبارية';
    }
    return null;
  }

  static String? validateUniversityEmail(String? email) {
    if (email == null || email.trim().isEmpty) {
      return 'البريد الإلكتروني إجباري';
    }
    final trimmed = email.trim();
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(trimmed)) {
      return 'يرجى إدخال بريد إلكتروني صحيح';
    }
    return null;
  }

  // 2. فحص نظام الحظر التراكمي للمحاولات الخاطئة (الخادم + الجهاز معاً)
  static Future<Map<String, dynamic>> checkLockoutStatus(String academicId) async {
    final cleanId = normalizeDigits(academicId.trim());
    final prefs = await SharedPreferences.getInstance();
    final String? rawData = prefs.getString('${_lockoutKey}_$cleanId');

    int localAttempts = 0;
    bool localPermanent = false;
    DateTime? localLockedUntil;

    if (rawData != null) {
      try {
        final Map<String, dynamic> data = jsonDecode(rawData);
        localAttempts = data['attempts'] ?? 0;
        localPermanent = data['isPermanent'] ?? false;
        final String? lockedUntilStr = data['lockedUntil'];
        if (lockedUntilStr != null) {
          localLockedUntil = DateTime.tryParse(lockedUntilStr);
        }
      } catch (_) {}
    }

    // فحص حالة الحظر على الخادم أيضاً لمنع التحايل بمسح بيانات التطبيق
    int serverAttempts = 0;
    bool serverBlocked = false;
    DateTime? serverLockedUntil;
    try {
      final res = await Supabase.instance.client
          .from('students')
          .select('is_blocked, failed_attempts, locked_until')
          .eq('academic_id', cleanId)
          .maybeSingle();
      if (res != null) {
        serverBlocked = (res['is_blocked'] ?? false) == true;
        serverAttempts = (res['failed_attempts'] as num?)?.toInt() ?? 0;
        if (res['locked_until'] != null) {
          serverLockedUntil = DateTime.tryParse(res['locked_until'].toString())?.toLocal();
        }
      }
    } catch (_) {}

    final int effectiveAttempts = serverAttempts > localAttempts ? serverAttempts : localAttempts;
    final bool isPermanent = localPermanent || (serverBlocked && effectiveAttempts >= 9);

    if (isPermanent) {
      return {
        'isLocked': true,
        'attempts': effectiveAttempts,
        'lockedUntil': null,
        'isPermanent': true,
      };
    }

    DateTime? effectiveLock = localLockedUntil;
    if (serverLockedUntil != null) {
      if (effectiveLock == null || serverLockedUntil.isAfter(effectiveLock)) {
        effectiveLock = serverLockedUntil;
      }
    }

    if (effectiveLock != null && DateTime.now().isBefore(effectiveLock)) {
      return {
        'isLocked': true,
        'attempts': effectiveAttempts,
        'lockedUntil': effectiveLock,
        'isPermanent': false,
        'remainingSeconds': effectiveLock.difference(DateTime.now()).inSeconds,
      };
    }

    return {
      'isLocked': false,
      'attempts': effectiveAttempts,
      'lockedUntil': null,
      'isPermanent': false,
    };
  }

  static Future<Map<String, dynamic>> registerFailedAttempt(String academicId) async {
    final cleanId = normalizeDigits(academicId.trim());
    final prefs = await SharedPreferences.getInstance();
    final status = await checkLockoutStatus(cleanId);
    int currentAttempts = (status['attempts'] as int) + 1;

    DateTime? lockedUntil;
    bool isPermanent = false;

    if (currentAttempts == 3) {
      // 3 محاولات خاطئة ⬅️ حظر لمدة دقيقة واحدة
      lockedUntil = DateTime.now().add(const Duration(minutes: 1));
    } else if (currentAttempts == 6) {
      // 3 محاولات أخرى (6 إجمالاً) ⬅️ حظر لمدة ساعة واحدة
      lockedUntil = DateTime.now().add(const Duration(hours: 1));
    } else if (currentAttempts >= 9) {
      // 3 محاولات إضافية (9 إجمالاً) ⬅️ حظر الحساب وتوجيه للدعم الفني
      isPermanent = true;
    }

    final Map<String, dynamic> newLockoutData = {
      'attempts': currentAttempts,
      'lockedUntil': lockedUntil?.toIso8601String(),
      'isPermanent': isPermanent,
      'remainingSeconds': lockedUntil != null
          ? lockedUntil.difference(DateTime.now()).inSeconds
          : 0,
    };

    await prefs.setString('${_lockoutKey}_$cleanId', jsonEncode(newLockoutData));

    // مزامنة الحظر والمحاولات الخاطئة على الخادم
    try {
      final Map<String, dynamic> serverUpdate = {
        'failed_attempts': currentAttempts,
        'locked_until': lockedUntil?.toUtc().toIso8601String(),
      };
      if (isPermanent) {
        serverUpdate['is_blocked'] = true;
      }
      await Supabase.instance.client
          .from('students')
          .update(serverUpdate)
          .eq('academic_id', cleanId);
    } catch (_) {}

    return newLockoutData;
  }

  static Future<void> resetLockout(String academicId) async {
    final cleanId = normalizeDigits(academicId.trim());
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('${_lockoutKey}_$cleanId');
    try {
      await Supabase.instance.client
          .from('students')
          .update({'failed_attempts': 0, 'locked_until': null})
          .eq('academic_id', cleanId);
    } catch (_) {}
  }

  // 3. التحقق من مطابقة البيانات في قاعدة البيانات (RPC آمن + تشفير Salted SHA-256)
  static Future<StudentProfileModel?> verifyCredentials({
    required String academicId,
    required String password,
    String? email,
  }) async {
    final trimmedId = normalizeDigits(academicId.trim());
    final trimmedPass = password.trim();

    // 3.1 محاولة الدخول عبر الدالة الآمنة على الخادم (app_login) إن كانت مفعلة
    try {
      final rpcRes = await Supabase.instance.client.rpc(
        'app_login',
        params: {
          'p_academic_id': trimmedId,
          'p_password': trimmedPass,
        },
      );
      if (rpcRes is Map) {
        final status = rpcRes['status']?.toString();
        if (status == 'ok' && rpcRes['profile'] is Map) {
          final p = Map<String, dynamic>.from(rpcRes['profile'] as Map);
          final token = rpcRes['token']?.toString() ?? PasswordSecurity.generateSessionToken();
          await resetLockout(trimmedId);
          final sem = p['semester']?.toString() ?? '';
          final rawLvl = p['level']?.toString();
          return StudentProfileModel(
            academicId: p['academic_id']?.toString() ?? trimmedId,
            fullName: p['full_name']?.toString() ?? '',
            password: '',
            email: p['email']?.toString() ?? '',
            specialty: p['specialty']?.toString() ?? '',
            level: StudentProfileModel.resolveAcademicLevel(sem, rawLvl),
            batch: p['batch']?.toString() ?? '',
            semester: sem,
            group: p['group_name']?.toString() ?? '',
            studyShift: p['study_shift']?.toString() ?? '',
            isPermanentlyBlocked: (p['is_blocked'] ?? false) == true,
            sessionToken: token,
          );
        } else if (status == 'blocked') {
          return StudentProfileModel(
            academicId: trimmedId,
            fullName: '',
            password: '',
            email: '',
            specialty: '',
            level: '',
            batch: '',
            semester: '',
            group: '',
            studyShift: '',
            isPermanentlyBlocked: true,
          );
        } else if (status == 'invalid' || status == 'locked') {
          return null;
        }
      }
    } catch (_) {
      // في حال لم تكن دالة app_login منشأة بعد، ننتقل للتحقق المشفر المباشر
    }

    // 3.2 التحقق المشفر المباشر مع الترقية التلقائية لكلمات المرور
    try {
      final response = await Supabase.instance.client
          .from('students')
          .select()
          .eq('academic_id', trimmedId)
          .maybeSingle();

      if (response != null) {
        final storedPassword = response['password']?.toString() ?? '';
        final isMatch = PasswordSecurity.verifyPassword(trimmedPass, storedPassword);

        if (!isMatch) {
          return null;
        }

        // ترقية كلمة المرور تلقائياً إلى هاش مشفر إذا كانت نصية قديمة، وتصفير عداد الأخطاء
        final Map<String, dynamic> secUpdates = {
          'failed_attempts': 0,
          'locked_until': null,
        };
        if (!PasswordSecurity.isHashed(storedPassword)) {
          secUpdates['password'] = PasswordSecurity.hashPassword(trimmedPass);
        }
        try {
          await Supabase.instance.client
              .from('students')
              .update(secUpdates)
              .eq('academic_id', trimmedId);
        } catch (_) {}

        await resetLockout(trimmedId);

        final sem = response['semester']?.toString() ?? '';
        final rawLvl = response['level']?.toString();
        return StudentProfileModel(
          academicId: response['academic_id']?.toString() ?? '',
          fullName: response['full_name'] ?? '',
          password: '',
          email: response['email'] ?? '',
          specialty: response['specialty'] ?? '',
          level: StudentProfileModel.resolveAcademicLevel(sem, rawLvl),
          batch: response['batch'] ?? '',
          semester: sem,
          group: response['group_name'] ?? '',
          studyShift: response['study_shift'] ?? '',
          isPermanentlyBlocked: response['is_blocked'] ?? false,
          sessionToken: PasswordSecurity.generateSessionToken(),
        );
      }
    } catch (_) {}

    return null;
  }

  /// تغيير كلمة سر الطالب بأمان مع تشفير الكلمة الجديدة
  static Future<String?> changeStudentPassword({
    required String academicId,
    required String oldPassword,
    required String newPassword,
  }) async {
    final cleanId = normalizeDigits(academicId.trim());
    final cleanOld = oldPassword.trim();
    final cleanNew = newPassword.trim();

    if (cleanNew.length < 6) {
      return 'كلمة السر الجديدة يجب ألا تقل عن 6 أحرف أو أرقام';
    }

    // 1. محاولة التغيير عبر RPC الآمن إن كان مفعلاً
    final session = await getSavedSession();
    if (session?.sessionToken != null && session!.sessionToken!.isNotEmpty) {
      try {
        final rpcRes = await Supabase.instance.client.rpc(
          'app_change_password',
          params: {
            'p_token': session.sessionToken,
            'p_old': cleanOld,
            'p_new': cleanNew,
          },
        );
        if (rpcRes is Map) {
          final st = rpcRes['status']?.toString();
          if (st == 'ok') return null;
          if (st == 'wrong_old') return 'كلمة السر الحالية غير صحيحة';
          if (st == 'weak') return 'كلمة السر الجديدة ضعيفة جداً';
        }
      } catch (_) {}
    }

    // 2. التحقق المشفر المباشر وتحديث الهاش
    try {
      final studentRes = await Supabase.instance.client
          .from('students')
          .select('academic_id, password')
          .eq('academic_id', cleanId)
          .maybeSingle();

      if (studentRes == null) {
        return 'لم يتم العثور على حساب الطالب في قاعدة البيانات';
      }

      final dbPassword = (studentRes['password'] ?? '').toString();
      if (!PasswordSecurity.verifyPassword(cleanOld, dbPassword)) {
        return 'كلمة السر الحالية غير صحيحة';
      }

      final hashedNew = PasswordSecurity.hashPassword(cleanNew);
      await Supabase.instance.client
          .from('students')
          .update({'password': hashedNew})
          .eq('academic_id', cleanId);

      return null; // نجاح بدون أخطاء
    } catch (_) {
      return 'حدث خطأ أثناء تحديث كلمة السر، يرجى المحاولة لاحقاً';
    }
  }

  // 4. حفظ واسترجاع الجلسة للمستخدم (Session Persistence) بدون حفظ كلمة السر النصية
  static StudentProfileModel? _cachedSession;

  static Future<void> saveStudentSession(StudentProfileModel student) async {
    final safeStudent = student.copyWith(
      password: '',
      sessionToken: student.sessionToken ?? PasswordSecurity.generateSessionToken(),
    );
    _cachedSession = safeStudent;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sessionKey, jsonEncode(safeStudent.toJson()));
  }

  static Future<StudentProfileModel?> getSavedSession() async {
    if (_cachedSession != null) return _cachedSession;
    final prefs = await SharedPreferences.getInstance();
    final String? rawJson = prefs.getString(_sessionKey);
    if (rawJson != null) {
      try {
        _cachedSession = StudentProfileModel.fromJson(jsonDecode(rawJson));
        return _cachedSession;
      } catch (_) {
        await prefs.remove(_sessionKey);
      }
    }
    return null;
  }

  /// مزامنة بيانات موقع الطالب الحالي (الفصل، المستوى، التخصص، الدفعة) مباشرة من قاعدة البيانات حسب الرقم الأكاديمي
  static Future<StudentProfileModel?> refreshSessionFromServer() async {
    final current = await getSavedSession();
    if (current == null || current.academicId.trim().isEmpty) return current;

    try {
      final res = await Supabase.instance.client
          .from('students')
          .select()
          .eq('academic_id', current.academicId.trim())
          .maybeSingle();

      if (res != null) {
        final sem = res['semester']?.toString() ?? current.semester;
        final rawLvl = res['level']?.toString();
        final resolvedLevel = StudentProfileModel.resolveAcademicLevel(sem, rawLvl);

        final updated = current.copyWith(
          fullName: res['full_name']?.toString() ?? current.fullName,
          email: res['email']?.toString() ?? current.email,
          specialty: res['specialty']?.toString() ?? current.specialty,
          batch: res['batch']?.toString() ?? current.batch,
          semester: sem,
          level: resolvedLevel,
          group: res['group_name']?.toString() ?? current.group,
          studyShift: res['study_shift']?.toString() ?? current.studyShift,
          isPermanentlyBlocked: (res['is_blocked'] ?? false) == true,
        );
        await saveStudentSession(updated);
        return updated;
      }
    } catch (_) {}

    return current;
  }

  static Future<void> clearSession() async {
    final token = _cachedSession?.sessionToken;
    _cachedSession = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionKey);
    if (token != null && token.isNotEmpty) {
      try {
        await Supabase.instance.client.rpc('app_logout', params: {'p_token': token});
      } catch (_) {}
    }
  }

  // 5. فحص ما إذا كان حساب الطالب موقوفاً / غير نشط في قاعدة البيانات
  static Future<bool> isStudentBlocked(String academicId) async {
    final trimmedId = normalizeDigits(academicId.trim());
    if (trimmedId.isEmpty) return false;

    final session = await getSavedSession();
    if (session?.sessionToken != null && session!.sessionToken!.isNotEmpty) {
      try {
        final rpcRes = await Supabase.instance.client.rpc(
          'app_session_status',
          params: {'p_token': session.sessionToken},
        );
        if (rpcRes is Map) {
          if (rpcRes['status'] == 'blocked') return true;
          if (rpcRes['status'] == 'ok') return false;
        }
      } catch (_) {}
    }

    try {
      final res = await Supabase.instance.client
          .from('students')
          .select('is_blocked')
          .eq('academic_id', trimmedId)
          .maybeSingle();
      if (res != null) {
        return (res['is_blocked'] ?? false) == true;
      }
    } catch (_) {}
    return false;
  }
}
