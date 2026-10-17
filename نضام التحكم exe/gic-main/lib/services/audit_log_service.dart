import 'package:flutter/foundation.dart';
import 'package:gic/models/admin_user.dart';
import 'package:gic/services/auth_service.dart';
import 'package:gic/services/supabase_service.dart';

class AuditLogItem {
  final String id;
  final String? userId;
  final String username;
  final String fullName;
  final String actionType; // 'LOGIN', 'LOGOUT', 'CREATE', 'UPDATE', 'DELETE', 'STATUS_CHANGE', 'IMPORT'
  final String module;
  final String? targetService;
  final String description;
  final Map<String, dynamic>? details;
  final DateTime createdAt;

  AuditLogItem({
    required this.id,
    this.userId,
    required this.username,
    required this.fullName,
    required this.actionType,
    required this.module,
    this.targetService,
    required this.description,
    this.details,
    required this.createdAt,
  });

  factory AuditLogItem.fromJson(Map<String, dynamic> json) {
    return AuditLogItem(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString(),
      username: json['username']?.toString() ?? 'غير معروف',
      fullName: json['full_name']?.toString() ?? json['username']?.toString() ?? 'غير معروف',
      actionType: json['action_type']?.toString() ?? 'UNKNOWN',
      module: json['module']?.toString() ?? 'النظام',
      targetService: json['target_service']?.toString(),
      description: json['description']?.toString() ?? '',
      details: json['details'] is Map ? Map<String, dynamic>.from(json['details']) : null,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

class AuditLogService {
  /// تسجيل عملية جديدة في جدول الرقابة وسجل العمليات
  static Future<void> log({
    required String actionType,
    required String module,
    String? targetService,
    required String description,
    Map<String, dynamic>? details,
  }) async {
    try {
      final user = AuthService.currentUser;
      final payload = {
        'user_id': user?.id,
        'username': user?.username ?? 'نظام/مدير',
        'full_name': user?.fullName ?? 'المدير العام',
        'action_type': actionType,
        'module': module,
        'target_service': targetService,
        'description': description,
        'details': details ?? {},
        'created_at': DateTime.now().toIso8601String(),
      };

      await AdminSupabase.client.from('audit_logs').insert(payload);
    } catch (e) {
      debugPrint('⚠️ تعذر حفظ سجل الرقابة audit_log: $e');
      // لا نوقف عمل البرنامج إطلاقاً في حال كان الجدول لم يُنشأ بعد
    }
  }

  /// جلب سجل العمليات مع إمكانية الفلترة
  static Future<List<AuditLogItem>> fetchLogs({
    String? searchQuery,
    String? actionType,
    String? module,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 100,
  }) async {
    try {
      var filter = AdminSupabase.client.from('audit_logs').select();

      if (actionType != null && actionType.isNotEmpty && actionType != 'الكل') {
        filter = filter.eq('action_type', actionType);
      }

      if (module != null && module.isNotEmpty && module != 'الكل') {
        filter = filter.eq('module', module);
      }

      final res = await filter.order('created_at', ascending: false).limit(limit);
      final list = (res as List).map((e) => AuditLogItem.fromJson(e)).toList();

      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        final q = searchQuery.trim().toLowerCase();
        return list.where((item) {
          return item.username.toLowerCase().contains(q) ||
              item.fullName.toLowerCase().contains(q) ||
              item.description.toLowerCase().contains(q) ||
              (item.targetService?.toLowerCase().contains(q) ?? false);
        }).toList();
      }

      return list;
    } catch (e) {
      debugPrint('⚠️ خطأ أثناء جلب سجل العمليات: $e');
      return [];
    }
  }
}
