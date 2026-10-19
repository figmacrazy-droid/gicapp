import 'package:flutter/material.dart';
import 'package:gic/models/admin_user.dart';
import 'package:gic/services/auth_service.dart';

enum PermissionAction {
  read,
  create,
  update,
  delete,
}

class ServiceItemDef {
  final String key;
  final String title;
  final IconData? icon;

  const ServiceItemDef({
    required this.key,
    required this.title,
    this.icon,
  });
}

class ModuleDef {
  final String key;
  final String title;
  final IconData icon;
  final List<ServiceItemDef> services;

  const ModuleDef({
    required this.key,
    required this.title,
    required this.icon,
    required this.services,
  });
}

class PermissionService {
  // القائمة الموحدة والكاملة لجميع أقسام وخدمات لوحة التحكم
  static const List<ModuleDef> systemModules = [
    ModuleDef(
      key: 'services',
      title: 'الخدمات والطلبات',
      icon: Icons.diamond_outlined,
      services: [
        ServiceItemDef(key: 'admission', title: 'القبول والتسجيل'),
        ServiceItemDef(key: 'academic', title: 'الأكاديمية (الكادر والتخصصات)'),
        ServiceItemDef(key: 'student_affairs', title: 'شؤون الطلاب (الجداول والطلبات)'),
        ServiceItemDef(key: 'graduates', title: 'شؤون الخريجين والوثائق'),
        ServiceItemDef(key: 'control', title: 'الكنترول والنتائج وأرقام الجلوس'),
        ServiceItemDef(key: 'finance', title: 'المالية والإشعارات المالية'),
        ServiceItemDef(key: 'college_info', title: 'معلومات الكلية والدعم'),
        ServiceItemDef(key: 'banners_achieve', title: 'الإعلانات والإنجازات والتقويم'),
      ],
    ),
    ModuleDef(
      key: 'academic_tree',
      title: 'الهيكل الأكاديمي والشجرة',
      icon: Icons.account_tree_outlined,
      services: [
        ServiceItemDef(key: 'tree_structure', title: 'إدارة فروع الشجرة الأكاديمية'),
        ServiceItemDef(key: 'tree_students', title: 'بيانات طلاب الفروع والتنقلات'),
      ],
    ),
    ModuleDef(
      key: 'notifications',
      title: 'الإشعارات والتنبيهات',
      icon: Icons.notifications_active_outlined,
      services: [
        ServiceItemDef(key: 'send_notifications', title: 'إرسال إشعارات جماعية ومخصصة'),
        ServiceItemDef(key: 'notifications_history', title: 'سجل واستعراض الإشعارات المرسلة'),
      ],
    ),
    ModuleDef(
      key: 'accounts',
      title: 'بيانات الطلاب ودليل الجامعة',
      icon: Icons.people_outline,
      services: [
        ServiceItemDef(key: 'social_links', title: 'حسابات التواصل الاجتماعي'),
        ServiceItemDef(key: 'student_guide', title: 'دليل الطالب الجامعي'),
      ],
    ),
    ModuleDef(
      key: 'advertisements',
      title: 'الإعلانات',
      icon: Icons.tv,
      services: [
        ServiceItemDef(key: 'ads_management', title: 'إدارة وتحديث الإعلانات'),
      ],
    ),
  ];

  /// فحص إذا كان للمستخدم صلاحية دخول للقسم ككل (يملك صلاحية قراءة لخدمة واحدة على الأقل داخله)
  static bool canAccessModule(String moduleKey) {
    final user = AuthService.currentUser;
    if (user == null) return false;
    if (user.isSuperAdmin) return true;

    final modulePerms = user.permissions[moduleKey];
    if (modulePerms == null || modulePerms is! Map) return false;

    // البحث عن أي خدمة يملك فيها الموظف صلاحية قراءة
    for (final serviceKey in modulePerms.keys) {
      final servicePerms = modulePerms[serviceKey];
      if (servicePerms is Map && servicePerms['read'] == true) {
        return true;
      }
    }
    return false;
  }

  /// فحص الصلاحية الدقيقة (CRUD) على خدمة معينة داخل قسم معين
  static bool can(
    String moduleKey,
    String serviceKey,
    PermissionAction action,
  ) {
    final user = AuthService.currentUser;
    if (user == null) return false;
    if (user.isSuperAdmin) return true;

    final modulePerms = user.permissions[moduleKey];
    if (modulePerms == null || modulePerms is! Map) return false;

    final servicePerms = modulePerms[serviceKey];
    if (servicePerms == null || servicePerms is! Map) return false;

    final actionKey = action.name; // 'read', 'create', 'update', 'delete'
    return servicePerms[actionKey] == true;
  }

  /// إنشاء قالب صلاحيات فارغ بالكامل عند إنشاء موظف جديد
  static Map<String, dynamic> generateEmptyPermissions() {
    final Map<String, dynamic> perms = {};
    for (final mod in systemModules) {
      final Map<String, dynamic> modMap = {};
      for (final srv in mod.services) {
        modMap[srv.key] = {
          'read': false,
          'create': false,
          'update': false,
          'delete': false,
        };
      }
      perms[mod.key] = modMap;
    }
    return perms;
  }

  /// توليد قالب صلاحيات كامل (Super Admin)
  static Map<String, dynamic> generateFullPermissions() {
    final Map<String, dynamic> perms = {};
    for (final mod in systemModules) {
      final Map<String, dynamic> modMap = {};
      for (final srv in mod.services) {
        modMap[srv.key] = {
          'read': true,
          'create': true,
          'update': true,
          'delete': true,
        };
      }
      perms[mod.key] = modMap;
    }
    return perms;
  }
}
