import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:gic/services/auth_service.dart';
import 'package:gic/services/supabase_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuditLogItem {
  final String id;
  final String? userId;
  final String username;
  final String fullName;
  final String actionType; // 'LOGIN', 'LOGOUT', 'CREATE', 'UPDATE', 'DELETE', 'STATUS_CHANGE', 'IMPORT', 'EXPORT', 'NOTIFY'
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
    final parsedDate = json['created_at'] != null
        ? (DateTime.tryParse(json['created_at'].toString())?.toLocal() ?? DateTime.now())
        : DateTime.now();
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
      createdAt: parsedDate,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'username': username,
      'full_name': fullName,
      'action_type': actionType,
      'module': module,
      'target_service': targetService,
      'description': description,
      'details': details ?? {},
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class AuditLogService {
  static const String _cloudAuditServiceKey = '__rbac_audit_logs_v1__';
  static const String _localAuditPrefKey = 'local_audit_logs_backup_v1';
  static const int _maxCloudLogs = 500;

  /// إخفاء أي حقول حساسة (مثل كلمات السر) من التفاصيل قبل تسجيلها في سجل الرقابة
  static Map<String, dynamic> _sanitizeDetails(Map<String, dynamic>? details) {
    if (details == null) return {};
    final copy = Map<String, dynamic>.from(details);
    copy.remove('password');
    return copy;
  }

  /// تسجيل عملية جديدة في جدول الرقابة وسجل العمليات (مع حفظ سحابي ومحلي فوري مضمون)
  static Future<void> log({
    required String actionType,
    required String module,
    String? targetService,
    String? targetId,
    String? targetName,
    required String description,
    Map<String, dynamic>? details,
  }) async {
    final user = AuthService.currentUser;
    final nowIso = DateTime.now().toIso8601String();
    final safeDetails = _sanitizeDetails(details);
    final effectiveTarget = targetService ?? targetName ?? targetId;
    final payload = {
      'id': 'log_${DateTime.now().microsecondsSinceEpoch}',
      'user_id': user?.id,
      'username': user?.username ?? 'admin',
      'full_name': user?.fullName ?? 'المدير العام',
      'action_type': actionType,
      'module': module,
      'target_service': effectiveTarget,
      'description': description,
      'details': safeDetails,
      'created_at': nowIso,
    };

    // 1. حفظ فوري في الذاكرة المحلية لضمان عدم ضياع أي حركة
    try {
      final prefs = await SharedPreferences.getInstance();
      final rawLocal = prefs.getString(_localAuditPrefKey);
      List<Map<String, dynamic>> localList = [];
      if (rawLocal != null && rawLocal.isNotEmpty) {
        final decoded = jsonDecode(rawLocal);
        if (decoded is List) {
          localList = decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        }
      }
      localList.insert(0, payload);
      if (localList.length > _maxCloudLogs) {
        localList.removeRange(_maxCloudLogs, localList.length);
      }
      await prefs.setString(_localAuditPrefKey, jsonEncode(localList));
    } catch (_) {}

    // 2. محاولة الإدراج في جدول audit_logs إن كان منشأً
    try {
      final dbPayload = Map<String, dynamic>.from(payload)..remove('id');
      await AdminSupabase.client.from('audit_logs').insert(dbPayload);
    } catch (_) {}

    // 3. الحفظ في السجل السحابي الموحد (يعمل دائماً عبر كافة أجهزة الإدارة)
    try {
      final existing = await _fetchCloudLogsRaw();
      existing.insert(0, payload);
      if (existing.length > _maxCloudLogs) {
        existing.removeRange(_maxCloudLogs, existing.length);
      }
      await AdminSupabase.client.from('system_instructions').upsert(
        {
          'service_key': _cloudAuditServiceKey,
          'title': 'سجل الرقابة والعمليات للنظام',
          'subtitle': 'Audit Activity Logs',
          'steps': jsonEncode(existing),
          'updated_at': nowIso,
        },
        onConflict: 'service_key',
      );
    } catch (e) {
      debugPrint('⚠️ تعذر حفظ سجل الرقابة سحابياً: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> _fetchCloudLogsRaw() async {
    try {
      final res = await AdminSupabase.client
          .from('system_instructions')
          .select('steps')
          .eq('service_key', _cloudAuditServiceKey)
          .maybeSingle();
      if (res != null && res['steps'] != null) {
        final raw = res['steps'];
        if (raw is List) {
          return raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        }
        if (raw is String && raw.isNotEmpty) {
          final decoded = jsonDecode(raw);
          if (decoded is List) {
            return decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
          }
        }
      }
    } catch (_) {}
    return [];
  }

  /// جلب سجل العمليات مع دمج السحابي والمحلي وإمكانية الفلترة
  static Future<List<AuditLogItem>> fetchLogs({
    String? searchQuery,
    String? actionType,
    String? module,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 250,
  }) async {
    final List<AuditLogItem> list = [];
    final Set<String> seenKeys = {};

    String makeKey(AuditLogItem item) {
      if (item.id.isNotEmpty) return item.id;
      return '${item.username}_${item.actionType}_${item.description}_${item.createdAt.millisecondsSinceEpoch ~/ 1000}';
    }

    // 1. محاولة الجلب من جدول audit_logs إن وُجد
    try {
      var filter = AdminSupabase.client.from('audit_logs').select();
      if (actionType != null && actionType.isNotEmpty && actionType != 'الكل') {
        filter = filter.eq('action_type', actionType);
      }
      if (module != null && module.isNotEmpty && module != 'الكل') {
        filter = filter.eq('module', module);
      }
      final res = await filter.order('created_at', ascending: false).limit(limit);
      for (final e in (res as List)) {
        final item = AuditLogItem.fromJson(Map<String, dynamic>.from(e));
        final k = makeKey(item);
        if (seenKeys.add(k)) list.add(item);
      }
    } catch (_) {}

    // 2. دمج السجل السحابي الموحد من system_instructions
    try {
      final cloudRaw = await _fetchCloudLogsRaw();
      for (final e in cloudRaw) {
        final item = AuditLogItem.fromJson(e);
        final k = makeKey(item);
        if (seenKeys.add(k)) list.add(item);
      }
    } catch (e) {
      debugPrint('⚠️ خطأ أثناء جلب سجل العمليات السحابي: $e');
    }

    // 3. دمج السجل المحلي الاحتياطي
    try {
      final prefs = await SharedPreferences.getInstance();
      final rawLocal = prefs.getString(_localAuditPrefKey);
      if (rawLocal != null && rawLocal.isNotEmpty) {
        final decoded = jsonDecode(rawLocal);
        if (decoded is List) {
          for (final e in decoded) {
            final item = AuditLogItem.fromJson(Map<String, dynamic>.from(e as Map));
            final k = makeKey(item);
            if (seenKeys.add(k)) list.add(item);
          }
        }
      }
    } catch (_) {}

    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    var filtered = list;
    if (actionType != null && actionType.isNotEmpty && actionType != 'الكل') {
      filtered = filtered.where((item) => item.actionType == actionType).toList();
    }

    if (module != null && module.isNotEmpty && module != 'الكل') {
      filtered = filtered.where((item) => item.module == module).toList();
    }

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final q = searchQuery.trim().toLowerCase();
      filtered = filtered.where((item) {
        return item.username.toLowerCase().contains(q) ||
            item.fullName.toLowerCase().contains(q) ||
            item.description.toLowerCase().contains(q) ||
            item.module.toLowerCase().contains(q) ||
            (item.targetService?.toLowerCase().contains(q) ?? false);
      }).toList();
    }

    if (filtered.length > limit) {
      return filtered.sublist(0, limit);
    }
    return filtered;
  }
}
