import 'package:flutter/material.dart';
import 'package:gic/models/admin_user.dart';
import 'package:gic/services/auth_service.dart';
import 'package:gic/services/audit_log_service.dart';
import 'package:gic/services/permission_service.dart';
import 'package:gic/services/supabase_service.dart';

class EmployeesManagementView extends StatefulWidget {
  final Function(String path)? onPathChanged;

  const EmployeesManagementView({
    Key? key,
    this.onPathChanged,
  }) : super(key: key);

  @override
  State<EmployeesManagementView> createState() => _EmployeesManagementViewState();
}

class _EmployeesManagementViewState extends State<EmployeesManagementView> {
  static const Color primaryNavy = Color(0xFF0E1B4D);
  static const Color accentGold = Color(0xFFC5A059);

  bool _isLoading = true;
  List<AdminUser> _employees = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadEmployees();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onPathChanged?.call('إدارة الموظفين وتوزيع الصلاحيات');
    });
  }

  Future<void> _loadEmployees() async {
    setState(() => _isLoading = true);
    final List<AdminUser> combined = [];

    // 1. محاولة الجلب من Supabase
    try {
      final res = await AdminSupabase.client
          .from('admin_users')
          .select()
          .order('created_at', ascending: false);

      final list = (res as List).map((e) => AdminUser.fromJson(e)).toList();
      combined.addAll(list);
    } catch (e) {
      debugPrint('⚠️ جدول Supabase غير متوفر حالياً: $e');
    }

    // 2. دمج الموظفين من التخزين المحلي (Local Fallback)
    final localList = await AuthService.getLocalEmployees();
    for (final loc in localList) {
      if (!combined.any((e) => e.username.toLowerCase() == loc.username.toLowerCase())) {
        combined.add(loc);
      }
    }

    if (mounted) {
      setState(() {
        _employees = combined;
        _isLoading = false;
      });
    }
  }

  void _showNotification(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, textDirection: TextDirection.rtl),
        backgroundColor: isError ? Colors.red.shade700 : Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _openEmployeeDialog({AdminUser? employee}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _EmployeeFormDialog(
        employee: employee,
        onSaved: () {
          _loadEmployees();
          _showNotification(employee == null ? 'تم إنشاء حساب الموظف بنجاح' : 'تم تحديث بيانات وصلاحيات الموظف');
        },
      ),
    );
  }

  Future<void> _toggleEmployeeStatus(AdminUser emp) async {
    final newStatus = !emp.isActive;
    try {
      await AdminSupabase.client
          .from('admin_users')
          .update({'is_active': newStatus})
          .eq('id', emp.id);
    } catch (_) {}

    await AuthService.toggleLocalEmployeeStatus(emp.id);

    await AuditLogService.log(
      actionType: 'STATUS_CHANGE',
      module: 'الموظفين والصلاحيات',
      targetService: emp.fullName,
      description: 'قام المدير بتغيير حالة الموظف ${emp.fullName} إلى: ${newStatus ? "نشط" : "معطل"}',
    );

    _showNotification('تم تحديث حالة الموظف');
    _loadEmployees();
  }

  Future<void> _deleteEmployee(AdminUser emp) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('تأكيد الحذف', style: TextStyle(color: primaryNavy, fontWeight: FontWeight.bold)),
          content: Text('هل أنت متأكد من رغبتك في حذف حساب الموظف "${emp.fullName}" نهائياً من النظام؟'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('حذف نهائي', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );

    if (confirm != true) return;

    try {
      await AdminSupabase.client.from('admin_users').delete().eq('id', emp.id);
    } catch (_) {}

    await AuthService.deleteLocalEmployee(emp.id);

    await AuditLogService.log(
      actionType: 'DELETE',
      module: 'الموظفين والصلاحيات',
      targetService: emp.fullName,
      description: 'قام المدير بحذف حساب الموظف: ${emp.fullName} (${emp.username})',
    );

    _showNotification('تم حذف حساب الموظف');
    _loadEmployees();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _employees.where((emp) {
      final q = _searchQuery.trim().toLowerCase();
      if (q.isEmpty) return true;
      return emp.fullName.toLowerCase().contains(q) ||
          emp.username.toLowerCase().contains(q);
    }).toList();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // شريط العنوان العلوي
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: primaryNavy.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.manage_accounts, size: 28, color: primaryNavy),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'إدارة الموظفين وتوزيع الصلاحيات (RBAC)',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: primaryNavy),
                        ),
                        Text(
                          'إنشاء حسابات الموظفين وتحديد صلاحيات الوصول والعمليات (قراءة / إضافة / تعديل / حذف)',
                          style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () => _openEmployeeDialog(),
                  icon: const Icon(Icons.person_add_alt_1, size: 20, color: Colors.white),
                  label: const Text(
                    'إنشاء حساب موظف جديد',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryNavy,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // بطاقات الإحصائيات السريعة
            Row(
              children: [
                _buildStatCard('إجمالي الحسابات', '${_employees.length}', Icons.people, Colors.blue),
                const SizedBox(width: 16),
                _buildStatCard(
                  'الموظفون النشطون',
                  '${_employees.where((e) => e.isActive && !e.isSuperAdmin).length}',
                  Icons.check_circle_outline,
                  Colors.green,
                ),
                const SizedBox(width: 16),
                _buildStatCard(
                  'حسابات المدراء العامين',
                  '${_employees.where((e) => e.isSuperAdmin).length}',
                  Icons.shield_outlined,
                  accentGold,
                ),
                const SizedBox(width: 16),
                _buildStatCard(
                  'الحسابات المعطلة',
                  '${_employees.where((e) => !e.isActive).length}',
                  Icons.block,
                  Colors.red,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // شريط البحث
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      onChanged: (val) => setState(() => _searchQuery = val),
                      decoration: const InputDecoration(
                        hintText: 'ابحث بالاسم أو اسم المستخدم...',
                        prefixIcon: Icon(Icons.search),
                        border: InputBorder.none,
                        isDense: true,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _loadEmployees,
                    icon: const Icon(Icons.refresh, color: primaryNavy),
                    tooltip: 'تحديث القائمة',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // جدول الموظفين
            if (_isLoading)
              const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()))
            else if (filtered.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(40),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  children: [
                    Icon(Icons.badge_outlined, size: 60, color: Colors.grey.shade400),
                    const SizedBox(height: 12),
                    const Text('لا يوجد موظفون مطابقون لبحثك أو لم يتم إضافة موظفين بعد',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.grey)),
                    const SizedBox(height: 8),
                    const Text('اضغط على "إنشاء حساب موظف جديد" للبدء في منح الصلاحيات.',
                        style: TextStyle(fontSize: 13, color: Colors.black54)),
                  ],
                ),
              )
            else
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade300),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 2)),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: DataTable(
                    headingRowColor: MaterialStateProperty.all(const Color(0xFFF1F4F9)),
                    headingTextStyle: const TextStyle(fontWeight: FontWeight.bold, color: primaryNavy, fontSize: 13),
                    dataRowMinHeight: 52,
                    dataRowMaxHeight: 64,
                    columns: const [
                      DataColumn(label: Text('اسم الموظف الكامل')),
                      DataColumn(label: Text('اسم المستخدم')),
                      DataColumn(label: Text('الدور الوظيفي')),
                      DataColumn(label: Text('الحالة')),
                      DataColumn(label: Text('نطاق الصلاحيات')),
                      DataColumn(label: Text('الإجراءات')),
                    ],
                    rows: filtered.map((emp) {
                      return DataRow(cells: [
                        DataCell(
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 16,
                                backgroundColor: emp.isSuperAdmin ? accentGold.withOpacity(0.2) : primaryNavy.withOpacity(0.1),
                                child: Icon(
                                  emp.isSuperAdmin ? Icons.star : Icons.person,
                                  size: 18,
                                  color: emp.isSuperAdmin ? accentGold : primaryNavy,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(emp.fullName, style: const TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                        DataCell(Text(emp.username, style: const TextStyle(fontFamily: 'monospace', color: primaryNavy))),
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: emp.isSuperAdmin ? accentGold.withOpacity(0.15) : Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              emp.isSuperAdmin ? 'مدير عام للنظام' : 'موظف محدد الصلاحيات',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                                color: emp.isSuperAdmin ? Colors.brown.shade800 : Colors.blue.shade900,
                              ),
                            ),
                          ),
                        ),
                        DataCell(
                          Switch(
                            value: emp.isActive,
                            activeColor: Colors.green,
                            onChanged: (_) => _toggleEmployeeStatus(emp),
                          ),
                        ),
                        DataCell(
                          emp.isSuperAdmin
                              ? const Text('كامل صلاحيات النظام 👑', style: TextStyle(fontWeight: FontWeight.bold, color: accentGold))
                              : _buildPermissionsSummaryChip(emp),
                        ),
                        DataCell(
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, size: 20, color: primaryNavy),
                                tooltip: 'تعديل البيانات والصلاحيات',
                                onPressed: () => _openEmployeeDialog(employee: emp),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                                tooltip: 'حذف الحساب',
                                onPressed: () => _deleteEmployee(emp),
                              ),
                            ],
                          ),
                        ),
                      ]);
                    }).toList(),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionsSummaryChip(AdminUser emp) {
    int allowedServicesCount = 0;
    emp.permissions.forEach((mod, services) {
      if (services is Map) {
        services.forEach((srv, perms) {
          if (perms is Map && perms['read'] == true) {
            allowedServicesCount++;
          }
        });
      }
    });

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Text(
        'مسموح له بـ ($allowedServicesCount) خدمة',
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black87),
      ),
    );
  }

  Widget _buildStatCard(String title, String count, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                const SizedBox(height: 4),
                Text(count, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: primaryNavy)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// نافذة نموذج إضافة وتعديل الموظف والشجرة المنسدلة للصلاحيات الدقيقة
class _EmployeeFormDialog extends StatefulWidget {
  final AdminUser? employee;
  final VoidCallback onSaved;

  const _EmployeeFormDialog({
    Key? key,
    this.employee,
    required this.onSaved,
  }) : super(key: key);

  @override
  State<_EmployeeFormDialog> createState() => _EmployeeFormDialogState();
}

class _EmployeeFormDialogState extends State<_EmployeeFormDialog> {
  static const Color primaryNavy = Color(0xFF0E1B4D);
  static const Color accentGold = Color(0xFFC5A059);

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  String _role = 'employee';
  bool _isActive = true;
  bool _isSaving = false;

  Map<String, dynamic> _permissions = {};

  @override
  void initState() {
    super.initState();
    if (widget.employee != null) {
      final emp = widget.employee!;
      _fullNameController.text = emp.fullName;
      _usernameController.text = emp.username;
      _role = emp.role;
      _isActive = emp.isActive;
      // استنساخ عميق للصلاحيات
      _permissions = Map<String, dynamic>.from(
        emp.permissions.map((k, v) => MapEntry(k, v is Map ? Map<String, dynamic>.from(v) : v)),
      );
    } else {
      _permissions = PermissionService.generateEmptyPermissions();
    }
  }

  void _setModulePermissions(String moduleKey, {required bool read, required bool create, required bool update, required bool delete}) {
    setState(() {
      final modMap = (_permissions[moduleKey] is Map)
          ? Map<String, dynamic>.from(_permissions[moduleKey])
          : <String, dynamic>{};

      for (final srv in PermissionService.systemModules.firstWhere((m) => m.key == moduleKey).services) {
        modMap[srv.key] = {
          'read': read,
          'create': create,
          'update': update,
          'delete': delete,
        };
      }
      _permissions[moduleKey] = modMap;
    });
  }

  void _updatePerm(String moduleKey, String serviceKey, String action, bool value) {
    setState(() {
      final modMap = (_permissions[moduleKey] is Map)
          ? Map<String, dynamic>.from(_permissions[moduleKey])
          : <String, dynamic>{};

      final srvMap = (modMap[serviceKey] is Map)
          ? Map<String, dynamic>.from(modMap[serviceKey])
          : {'read': false, 'create': false, 'update': false, 'delete': false};

      srvMap[action] = value;

      // منطق ذكي: إذا تم تفعيل الإضافة أو التعديل أو الحذف، يجب أن تكون القراءة مفعلة تلقائياً
      if ((action == 'create' || action == 'update' || action == 'delete') && value == true) {
        srvMap['read'] = true;
      }
      // إذا تم إيقاف القراءة، يتم إيقاف الإضافة والتعديل والحذف
      if (action == 'read' && value == false) {
        srvMap['create'] = false;
        srvMap['update'] = false;
        srvMap['delete'] = false;
      }

      modMap[serviceKey] = srvMap;
      _permissions[moduleKey] = modMap;
    });
  }

  bool _getPerm(String moduleKey, String serviceKey, String action) {
    try {
      return _permissions[moduleKey]?[serviceKey]?[action] == true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final payload = {
        'full_name': _fullNameController.text.trim(),
        'username': _usernameController.text.trim(),
        'role': _role,
        'is_active': _isActive,
        'permissions': _role == 'super_admin' ? {} : _permissions,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (_passwordController.text.trim().isNotEmpty) {
        payload['password'] = _passwordController.text.trim();
      } else if (widget.employee == null) {
        throw Exception('كلمة المرور مطلوبة للموظف الجديد');
      }

      // 1. محاولة الحفظ في Supabase
      try {
        if (widget.employee == null) {
          payload['created_at'] = DateTime.now().toIso8601String();
          await AdminSupabase.client.from('admin_users').insert(payload);
        } else {
          await AdminSupabase.client.from('admin_users').update(payload).eq('id', widget.employee!.id);
        }
      } catch (e) {
        debugPrint('⚠️ جدول Supabase غير متوفر حالياً، سيتم الحفظ محلياً: $e');
      }

      // 2. الحفظ المحلي المضمون (يعمل في كافة الظروف فوراً)
      if (widget.employee != null) {
        payload['id'] = widget.employee!.id;
      }
      await AuthService.saveLocalEmployee(payload);

      await AuditLogService.log(
        actionType: widget.employee == null ? 'CREATE' : 'UPDATE',
        module: 'الموظفين والصلاحيات',
        targetService: payload['full_name']?.toString(),
        description: 'قام المدير بحفظ بيانات الموظف: ${payload['full_name']} (${payload['username']})',
        details: payload,
      );

      Navigator.of(context).pop();
      widget.onSaved();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تنبيه: $e', textDirection: TextDirection.rtl),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
        child: Container(
          width: 950,
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
          child: Column(
            children: [
              // رأس النافذة
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                decoration: const BoxDecoration(
                  color: primaryNavy,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.security, color: Colors.white, size: 24),
                        const SizedBox(width: 10),
                        Text(
                          widget.employee == null ? 'إنشاء حساب موظف جديد وتحديد صلاحياته' : 'تعديل بيانات وصلاحيات: ${widget.employee!.fullName}',
                          style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),

              // محتوى النموذج
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // الحقول الأساسية
                        const Text('البيانات الأساسية للموظف:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: primaryNavy)),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: TextFormField(
                                controller: _fullNameController,
                                decoration: const InputDecoration(
                                  labelText: 'الاسم الكامل للموظف *',
                                  hintText: 'مثال: أحمد محمد علي',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.person),
                                ),
                                validator: (v) => (v == null || v.trim().isEmpty) ? 'مطلوب' : null,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              flex: 2,
                              child: TextFormField(
                                controller: _usernameController,
                                decoration: const InputDecoration(
                                  labelText: 'اسم المستخدم للدخول *',
                                  hintText: 'مثال: ahmed_service',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.badge),
                                ),
                                validator: (v) => (v == null || v.trim().isEmpty) ? 'مطلوب' : null,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              flex: 2,
                              child: TextFormField(
                                controller: _passwordController,
                                obscureText: true,
                                decoration: InputDecoration(
                                  labelText: widget.employee == null ? 'كلمة المرور *' : 'تغيير كلمة المرور (اختياري)',
                                  hintText: '••••••••',
                                  border: const OutlineInputBorder(),
                                  prefixIcon: const Icon(Icons.lock_outline),
                                ),
                                validator: (v) {
                                  if (widget.employee == null && (v == null || v.trim().isEmpty)) {
                                    return 'مطلوب للموظف الجديد';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: DropdownButtonFormField<String>(
                                value: _role,
                                decoration: const InputDecoration(
                                  labelText: 'الدور الوظيفي والصلاحيات العامة',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.admin_panel_settings_outlined),
                                ),
                                items: const [
                                  DropdownMenuItem(value: 'employee', child: Text('موظف محدد الصلاحيات (حسب الجدول أدناه)')),
                                  DropdownMenuItem(value: 'super_admin', child: Text('مدير نظام عام (Super Admin - كامل الصلاحيات)')),
                                ],
                                onChanged: (val) {
                                  if (val != null) setState(() => _role = val);
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Row(
                              children: [
                                Switch(
                                  value: _isActive,
                                  activeColor: Colors.green,
                                  onChanged: (val) => setState(() => _isActive = val),
                                ),
                                Text(_isActive ? 'الحساب مفعل' : 'الحساب معطل', style: const TextStyle(fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        const Divider(thickness: 1.5),
                        const SizedBox(height: 12),

                        // شجرة ومصفوفة الصلاحيات
                        if (_role == 'super_admin')
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: accentGold.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: accentGold),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.shield, color: accentGold, size: 32),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'تم تعيين هذا الحساب كـ "مدير عام للنظام"',
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: primaryNavy),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        'يحصل المدير العام تلقائياً على كافة صلاحيات القراءة، الإضافة، التعديل، والحذف عبر جميع أقسام وخدمات النظام وسجلات الرقابة.',
                                        style: TextStyle(fontSize: 13, color: Colors.black87),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          )
                        else ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'شجرة تحديد الصلاحيات حسب الأقسام والخدمات (CRUD):',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: primaryNavy),
                                  ),
                                  Text(
                                    'انقر على أي قسم لفتحه وتحديد الصلاحيات المسموحة لهذا الموظف (قراءة، إضافة، تعديل، حذف):',
                                    style: TextStyle(fontSize: 12.5, color: Colors.black54),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  OutlinedButton.icon(
                                    onPressed: () {
                                      setState(() {
                                        _permissions = PermissionService.generateFullPermissions();
                                      });
                                    },
                                    icon: const Icon(Icons.select_all, size: 16),
                                    label: const Text('تحديد الكل للنظام', style: TextStyle(fontSize: 12)),
                                  ),
                                  const SizedBox(width: 8),
                                  OutlinedButton.icon(
                                    onPressed: () {
                                      setState(() {
                                        _permissions = PermissionService.generateEmptyPermissions();
                                      });
                                    },
                                    icon: const Icon(Icons.deselect, size: 16),
                                    label: const Text('إلغاء الكل', style: TextStyle(fontSize: 12)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // قائمة الأقسام القابلة للتوسيع (Accordion Modules)
                          ...PermissionService.systemModules.map((module) {
                            return _buildModuleAccordion(module);
                          }).toList(),
                        ],
                      ],
                    ),
                  ),
                ),
              ),

              // أزرار الحفظ والإلغاء السفلية
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  border: Border(top: BorderSide(color: Colors.grey.shade300)),
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('إلغاء التراجع', style: TextStyle(fontSize: 14)),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      onPressed: _isSaving ? null : _submit,
                      icon: _isSaving
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.check_circle, size: 20, color: Colors.white),
                      label: Text(
                        _isSaving ? 'جاري الحفظ...' : (widget.employee == null ? 'إنشاء وتطبيق الصلاحيات' : 'حفظ التعديلات'),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryNavy,
                        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModuleAccordion(ModuleDef module) {
    // التحقق هل لدى الموظف أي صلاحية في هذا القسم
    int activeCount = 0;
    for (final srv in module.services) {
      if (_getPerm(module.key, srv.key, 'read')) activeCount++;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: activeCount > 0 ? primaryNavy.withOpacity(0.4) : Colors.grey.shade300),
      ),
      child: ExpansionTile(
        key: PageStorageKey(module.key),
        initiallyExpanded: activeCount > 0,
        leading: Icon(module.icon, color: activeCount > 0 ? primaryNavy : Colors.grey),
        title: Row(
          children: [
            Text(
              module.title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: activeCount > 0 ? primaryNavy : Colors.black87,
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: activeCount > 0 ? primaryNavy.withOpacity(0.1) : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$activeCount / ${module.services.length} خدمة مفعلة',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: activeCount > 0 ? primaryNavy : Colors.grey.shade700),
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextButton(
              onPressed: () => _setModulePermissions(module.key, read: true, create: true, update: true, delete: true),
              style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
              child: const Text('تحديد الكل', style: TextStyle(fontSize: 12)),
            ),
            TextButton(
              onPressed: () => _setModulePermissions(module.key, read: true, create: false, update: false, delete: false),
              style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
              child: const Text('قراءة فقط', style: TextStyle(fontSize: 12)),
            ),
            TextButton(
              onPressed: () => _setModulePermissions(module.key, read: false, create: false, update: false, delete: false),
              style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
              child: const Text('إلغاء', style: TextStyle(fontSize: 12, color: Colors.red)),
            ),
          ],
        ),
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            color: const Color(0xFFF9FAFC),
            child: Table(
              columnWidths: const {
                0: FlexColumnWidth(3),
                1: FixedColumnWidth(110),
                2: FixedColumnWidth(110),
                3: FixedColumnWidth(110),
                4: FixedColumnWidth(110),
              },
              defaultVerticalAlignment: TableCellVerticalAlignment.middle,
              children: [
                // ترويسة الجدول
                TableRow(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  children: const [
                    Padding(padding: EdgeInsets.all(10), child: Text('الخدمة أو الصفحة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                    Center(child: Text('👁️ قراءة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5))),
                    Center(child: Text('➕ إضافة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5))),
                    Center(child: Text('✏️ تعديل', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5))),
                    Center(child: Text('🗑️ حذف', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5))),
                  ],
                ),
                // صفوف الخدمات
                ...module.services.map((srv) {
                  final read = _getPerm(module.key, srv.key, 'read');
                  final create = _getPerm(module.key, srv.key, 'create');
                  final update = _getPerm(module.key, srv.key, 'update');
                  final del = _getPerm(module.key, srv.key, 'delete');

                  return TableRow(
                    decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        child: Text(srv.title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      ),
                      Center(
                        child: Checkbox(
                          value: read,
                          activeColor: primaryNavy,
                          onChanged: (val) => _updatePerm(module.key, srv.key, 'read', val ?? false),
                        ),
                      ),
                      Center(
                        child: Checkbox(
                          value: create,
                          activeColor: Colors.green.shade700,
                          onChanged: (val) => _updatePerm(module.key, srv.key, 'create', val ?? false),
                        ),
                      ),
                      Center(
                        child: Checkbox(
                          value: update,
                          activeColor: Colors.orange.shade800,
                          onChanged: (val) => _updatePerm(module.key, srv.key, 'update', val ?? false),
                        ),
                      ),
                      Center(
                        child: Checkbox(
                          value: del,
                          activeColor: Colors.red.shade700,
                          onChanged: (val) => _updatePerm(module.key, srv.key, 'delete', val ?? false),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
