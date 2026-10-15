import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/app_models.dart';

class AuthService {
  static const String _sessionKey = 'current_student_session';
  static const String _lockoutKey = 'student_lockout_data';

  // 1. القواعد الصارمة على الحقول
  static String? validateAcademicId(String? id) {
    if (id == null || id.trim().isEmpty) {
      return 'الرقم الأكاديمي إجباري';
    }
    final trimmed = id.trim();
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

  // قاعدة بيانات وهمية تجريبية للطلاب (مطابقة لجدول الإكسل المطلوب)
  static final List<StudentProfileModel> _mockStudents = [
    const StudentProfileModel(
      academicId: '2024000001',
      fullName: 'عبد الله أحمد الطالب',
      password: 'studentpassword',
      email: 'abdallah@alghad.edu.ye',
      specialty: 'علوم مختبرات طبية',
      level: 'المستوى الثاني',
      batch: 'الدفعة الخامسة',
      semester: 'الفصل الأول',
      group: 'المجموعة الأولى',
      studyShift: 'الفترة الصباحية',
    ),
    const StudentProfileModel(
      academicId: '2024000002',
      fullName: 'فاطمة محمد العبسي',
      password: 'fatimapassword',
      email: 'fatima@alghad.edu.ye',
      specialty: 'صيدلة سريرية',
      level: 'المستوى الثالث',
      batch: 'الدفعة الخامسة',
      semester: 'الفصل الأول',
      group: 'المجموعة الثانية',
      studyShift: 'الفترة الصباحية',
    ),
    const StudentProfileModel(
      academicId: '2024000003',
      fullName: 'مهندس النظام',
      password: 'password',
      email: 'figmacrazy@gmail.com',
      specialty: 'أمن سيبراني',
      level: 'المستوى الأول',
      batch: 'الدفعة الأولى',
      semester: 'الفصل الأول',
      group: 'المجموعة الأولى',
      studyShift: 'الفترة الصباحية',
    ),
  ];

  // 2. فحص نظام الحظر التراكمي للمحاولات الخاطئة
  static Future<Map<String, dynamic>> checkLockoutStatus(String academicId) async {
    final prefs = await SharedPreferences.getInstance();
    final String? rawData = prefs.getString('${_lockoutKey}_$academicId');
    if (rawData == null) {
      return {'isLocked': false, 'attempts': 0, 'lockedUntil': null, 'isPermanent': false};
    }

    final Map<String, dynamic> data = jsonDecode(rawData);
    final int attempts = data['attempts'] ?? 0;
    final bool isPermanent = data['isPermanent'] ?? false;
    final String? lockedUntilStr = data['lockedUntil'];

    if (isPermanent) {
      return {'isLocked': true, 'attempts': attempts, 'lockedUntil': null, 'isPermanent': true};
    }

    if (lockedUntilStr != null) {
      final DateTime lockedUntil = DateTime.parse(lockedUntilStr);
      if (DateTime.now().isBefore(lockedUntil)) {
        return {
          'isLocked': true,
          'attempts': attempts,
          'lockedUntil': lockedUntil,
          'isPermanent': false,
          'remainingSeconds': lockedUntil.difference(DateTime.now()).inSeconds,
        };
      }
    }

    return {'isLocked': false, 'attempts': attempts, 'lockedUntil': null, 'isPermanent': false};
  }

  static Future<Map<String, dynamic>> registerFailedAttempt(String academicId) async {
    final prefs = await SharedPreferences.getInstance();
    final status = await checkLockoutStatus(academicId);
    int currentAttempts = (status['attempts'] as int) + 1;

    DateTime? lockedUntil;
    bool isPermanent = false;

    if (currentAttempts == 3) {
      // 3 محاولات خروج ⬅️ حظر لمدة دقيقة واحدة
      lockedUntil = DateTime.now().add(const Duration(minutes: 1));
    } else if (currentAttempts == 6) {
      // 3 محاولات أخرى ⬅️ حظر لمدة ساعة واحدة
      lockedUntil = DateTime.now().add(const Duration(hours: 1));
    } else if (currentAttempts >= 9) {
      // 3 محاولات إضافية ⬅️ حظر دائم للحساب وتوجيه للدعم الفني
      isPermanent = true;
    }

    final Map<String, dynamic> newLockoutData = {
      'attempts': currentAttempts,
      'lockedUntil': lockedUntil?.toIso8601String(),
      'isPermanent': isPermanent,
    };

    await prefs.setString('${_lockoutKey}_$academicId', jsonEncode(newLockoutData));
    return newLockoutData;
  }

  static Future<void> resetLockout(String academicId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('${_lockoutKey}_$academicId');
  }

  // 3. التحقق من مطابقة البيانات في قاعدة البيانات
  static Future<StudentProfileModel?> verifyCredentials({
    required String academicId,
    required String password,
    required String email,
  }) async {
    final trimmedId = academicId.trim();
    final trimmedPass = password.trim();
    final trimmedEmail = email.trim();

    try {
      final response = await Supabase.instance.client
          .from('students')
          .select()
          .eq('academic_id', trimmedId)
          .eq('password', trimmedPass)
          .eq('email', trimmedEmail)
          .maybeSingle();

      if (response != null) {
        return StudentProfileModel(
          academicId: response['academic_id']?.toString() ?? '',
          fullName: response['full_name'] ?? '',
          password: response['password'] ?? '',
          email: response['email'] ?? '',
          specialty: response['specialty'] ?? '',
          level: response['level'] ?? 'المستوى الأول',
          batch: response['batch'] ?? '',
          semester: response['semester'] ?? '',
          group: response['group_name'] ?? '',
          studyShift: response['study_shift'] ?? '',
          isPermanentlyBlocked: response['is_blocked'] ?? false,
        );
      }
    } catch (_) {}

    for (var student in _mockStudents) {
      if (student.academicId == trimmedId &&
          student.password == trimmedPass &&
          student.email.toLowerCase() == trimmedEmail.toLowerCase()) {
        return student;
      }
    }
    return null;
  }

  // 4. حفظ واسترجاع الجلسة للمستخدم (Session Persistence)
  static Future<void> saveStudentSession(StudentProfileModel student) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sessionKey, jsonEncode(student.toJson()));
  }

  static Future<StudentProfileModel?> getSavedSession() async {
    final prefs = await SharedPreferences.getInstance();
    final String? rawJson = prefs.getString(_sessionKey);
    if (rawJson != null) {
      return StudentProfileModel.fromJson(jsonDecode(rawJson));
    }
    return null;
  }

  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionKey);
  }

  // 5. فحص ما إذا كان حساب الطالب موقوفاً / غير نشط في قاعدة البيانات
  static Future<bool> isStudentBlocked(String academicId) async {
    final trimmedId = academicId.trim();
    if (trimmedId.isEmpty) return false;
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
