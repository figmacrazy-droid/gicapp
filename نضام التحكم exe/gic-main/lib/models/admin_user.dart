class AdminUser {
  final String id;
  final String username;
  final String fullName;
  final String role; // 'super_admin' or 'employee'
  final String? phone;
  final bool isActive;
  final Map<String, dynamic> permissions;
  final DateTime createdAt;

  AdminUser({
    required this.id,
    required this.username,
    required this.fullName,
    required this.role,
    this.phone,
    required this.isActive,
    required this.permissions,
    required this.createdAt,
  });

  bool get isSuperAdmin => role == 'super_admin';

  factory AdminUser.fromJson(Map<String, dynamic> json) {
    return AdminUser(
      id: json['id']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      fullName: json['full_name']?.toString() ?? json['username']?.toString() ?? 'مستخدم',
      role: json['role']?.toString() ?? 'employee',
      phone: json['phone']?.toString(),
      isActive: json['is_active'] == true || json['is_active'] == 1,
      permissions: (json['permissions'] is Map)
          ? Map<String, dynamic>.from(json['permissions'])
          : {},
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'full_name': fullName,
      'role': role,
      'phone': phone,
      'is_active': isActive,
      'permissions': permissions,
    };
  }

  // مستخدم المدير العام الافتراضي (للطوارئ أو قبل تشغيل السكربت)
  factory AdminUser.defaultSuperAdmin() {
    return AdminUser(
      id: '00000000-0000-0000-0000-000000000001',
      username: 'admin',
      fullName: 'مدير النظام العام',
      role: 'super_admin',
      phone: '777000000',
      isActive: true,
      permissions: {},
      createdAt: DateTime.now(),
    );
  }
}
