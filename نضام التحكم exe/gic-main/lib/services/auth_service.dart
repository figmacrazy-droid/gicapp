import 'package:flutter/foundation.dart';
import 'package:gic/models/admin_user.dart';
import 'package:gic/services/audit_log_service.dart';
import 'package:gic/services/supabase_service.dart';

class AuthService {
  static AdminUser? _currentUser;

  static AdminUser? get currentUser => _currentUser;
  static bool get isLoggedIn => _currentUser != null;

  /// تسجيل الدخول والتحقق من حساب الموظف أو المدير
  static Future<bool> login(String username, String password) async {
    final cleanUsername = username.trim();
    final cleanPassword = password.trim();

    if (cleanUsername.isEmpty || cleanPassword.isEmpty) {
      throw Exception('يرجى إدخال اسم المستخدم وكلمة المرور');
    }

    try {
      // 1. محاولة الاستعلام من جدول admin_users
      final res = await AdminSupabase.client
          .from('admin_users')
          .select()
          .eq('username', cleanUsername)
          .maybeSingle();

      if (res != null) {
        if (res['password'] != cleanPassword) {
          throw Exception('كلمة المرور غير صحيحة');
        }

        final user = AdminUser.fromJson(res);
        if (!user.isActive) {
          throw Exception('هذا الحساب معطل حالياً من قبل مدير النظام');
        }

        _currentUser = user;

        // تسجيل العملية في سجل الرقابة
        await AuditLogService.log(
          actionType: 'LOGIN',
          module: 'النظام',
          description: 'تسجيل دخول ناجح للمستخدم: ${user.fullName} (${user.username})',
        );

        return true;
      }
    } catch (e) {
      debugPrint('⚠️ التحقق عبر قاعدة البيانات: $e');
      // إذا كان الخطأ متعلقاً بكلمة المرور أو الحساب المعطل، نعيد إطلاقه مباشرة
      if (e.toString().contains('كلمة المرور') || e.toString().contains('معطل')) {
        rethrow;
      }
    }

    // 2. التحقق من حساب المدير العام الافتراضي للطوارئ (Super Admin Fallback)
    if (cleanUsername.toLowerCase() == 'admin' && (cleanPassword == 'admin' || cleanPassword == 'admin123')) {
      _currentUser = AdminUser.defaultSuperAdmin();

      await AuditLogService.log(
        actionType: 'LOGIN',
        module: 'النظام',
        description: 'تسجيل دخول بحساب المدير العام الرئيسي (الطوارئ)',
      );

      return true;
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
