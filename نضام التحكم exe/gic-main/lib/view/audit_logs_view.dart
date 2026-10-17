import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:gic/services/audit_log_service.dart';

class AuditLogsView extends StatefulWidget {
  final Function(String path)? onPathChanged;

  const AuditLogsView({
    Key? key,
    this.onPathChanged,
  }) : super(key: key);

  @override
  State<AuditLogsView> createState() => _AuditLogsViewState();
}

class _AuditLogsViewState extends State<AuditLogsView> {
  static const Color primaryNavy = Color(0xFF0E1B4D);
  static const Color accentGold = Color(0xFFC5A059);

  bool _isLoading = true;
  List<AuditLogItem> _logs = [];

  String _searchQuery = '';
  String _selectedAction = 'الكل';
  String _selectedModule = 'الكل';

  @override
  void initState() {
    super.initState();
    _loadLogs();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onPathChanged?.call('سجل الرقابة وتتبع عمليات الموظفين');
    });
  }

  Future<void> _loadLogs() async {
    setState(() => _isLoading = true);
    final logs = await AuditLogService.fetchLogs(
      searchQuery: _searchQuery,
      actionType: _selectedAction,
      module: _selectedModule,
      limit: 250,
    );
    if (mounted) {
      setState(() {
        _logs = logs;
        _isLoading = false;
      });
    }
  }

  Color _getActionColor(String actionType) {
    switch (actionType.toUpperCase()) {
      case 'CREATE':
        return Colors.green.shade700;
      case 'UPDATE':
        return Colors.orange.shade800;
      case 'DELETE':
        return Colors.red.shade700;
      case 'LOGIN':
        return Colors.blue.shade700;
      case 'LOGOUT':
        return Colors.grey.shade700;
      case 'STATUS_CHANGE':
        return Colors.purple.shade700;
      case 'IMPORT':
        return Colors.teal.shade700;
      default:
        return primaryNavy;
    }
  }

  String _getActionArabicText(String actionType) {
    switch (actionType.toUpperCase()) {
      case 'CREATE':
        return 'إضافة جديد ➕';
      case 'UPDATE':
        return 'تعديل بيانات ✏️';
      case 'DELETE':
        return 'حذف سجل 🗑️';
      case 'LOGIN':
        return 'تسجيل دخول 🔑';
      case 'LOGOUT':
        return 'تسجيل خروج 🚪';
      case 'STATUS_CHANGE':
        return 'تغيير حالة 🔄';
      case 'IMPORT':
        return 'استيراد إكسل 📥';
      default:
        return actionType;
    }
  }

  String _formatDateTime(DateTime dt) {
    final y = dt.year;
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'م' : 'ص';
    return '$y/$m/$d - $hour:$minute $period';
  }

  void _showDetailsDialog(AuditLogItem log) {
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: Row(
            children: [
              Icon(Icons.info_outline, color: _getActionColor(log.actionType)),
              const SizedBox(width: 8),
              Text(
                'تفاصيل العملية: ${_getActionArabicText(log.actionType)}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          content: Container(
            width: 500,
            constraints: const BoxConstraints(maxHeight: 400),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailRow('الموظف المنفذ:', '${log.fullName} (@${log.username})'),
                  _buildDetailRow('التوقيت الدقيق:', _formatDateTime(log.createdAt)),
                  _buildDetailRow('القسم / الموديول:', log.module),
                  if (log.targetService != null) _buildDetailRow('الخدمة المستهدفة:', log.targetService!),
                  _buildDetailRow('البيان التوضيحي:', log.description),
                  const Divider(height: 24),
                  const Text('البيانات التقنية المخزنة (Payload):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E1E),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      log.details != null && log.details!.isNotEmpty
                          ? const JsonEncoder.withIndent('  ').convert(log.details)
                          : 'لا توجد بيانات تفصيلية إضافية',
                      textDirection: TextDirection.ltr,
                      style: const TextStyle(
                        color: Color(0xFF6A9955),
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              style: ElevatedButton.styleFrom(backgroundColor: primaryNavy),
              child: const Text('إغلاق', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600, color: primaryNavy)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // إحصائيات سريعة
    final totalCount = _logs.length;
    final createCount = _logs.where((l) => l.actionType == 'CREATE').length;
    final updateCount = _logs.where((l) => l.actionType == 'UPDATE').length;
    final deleteCount = _logs.where((l) => l.actionType == 'DELETE').length;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // شريط العنوان
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
                      child: const Icon(Icons.history_edu_outlined, size: 28, color: primaryNavy),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'سجل الرقابة والعمليات وتتبع الموظفين (Audit Logs)',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: primaryNavy),
                        ),
                        Text(
                          'رصد ومتابعة كافة العمليات التي يُجريها الموظفون لحظة بلحظة (من دخل، ماذا عدّل، وماذا حذف)',
                          style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: _loadLogs,
                  icon: const Icon(Icons.refresh, size: 18, color: Colors.white),
                  label: const Text('تحديث السجل فورا', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryNavy,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // كروت الإحصائيات السريعة
            Row(
              children: [
                _buildMetricCard('إجمالي الحركات المرصودة', '$totalCount', Icons.list_alt, Colors.blue),
                const SizedBox(width: 14),
                _buildMetricCard('عمليات الإضافة', '$createCount', Icons.add_box_outlined, Colors.green),
                const SizedBox(width: 14),
                _buildMetricCard('عمليات التعديل', '$updateCount', Icons.edit_note, Colors.orange),
                const SizedBox(width: 14),
                _buildMetricCard('عمليات الحذف', '$deleteCount', Icons.delete_sweep_outlined, Colors.red),
              ],
            ),
            const SizedBox(height: 20),

            // شريط الفلاتر والبحث
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
                    flex: 3,
                    child: TextField(
                      onChanged: (val) {
                        _searchQuery = val;
                        _loadLogs();
                      },
                      decoration: const InputDecoration(
                        hintText: 'ابحث باسم الموظف أو نص العملية أو الخدمة...',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    flex: 2,
                    child: DropdownButtonFormField<String>(
                      value: _selectedAction,
                      decoration: const InputDecoration(
                        labelText: 'نوع العملية',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        isDense: true,
                      ),
                      items: const [
                        DropdownMenuItem(value: 'الكل', child: Text('كافة العمليات')),
                        DropdownMenuItem(value: 'LOGIN', child: Text('تسجيل دخول')),
                        DropdownMenuItem(value: 'CREATE', child: Text('إضافة جديد')),
                        DropdownMenuItem(value: 'UPDATE', child: Text('تعديل')),
                        DropdownMenuItem(value: 'DELETE', child: Text('حذف')),
                        DropdownMenuItem(value: 'STATUS_CHANGE', child: Text('تغيير حالة')),
                        DropdownMenuItem(value: 'IMPORT', child: Text('استيراد إكسل')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          _selectedAction = val;
                          _loadLogs();
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    flex: 2,
                    child: DropdownButtonFormField<String>(
                      value: _selectedModule,
                      decoration: const InputDecoration(
                        labelText: 'القسم المستهدف',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        isDense: true,
                      ),
                      items: const [
                        DropdownMenuItem(value: 'الكل', child: Text('كافة الأقسام')),
                        DropdownMenuItem(value: 'الخدمات والطلبات', child: Text('الخدمات والطلبات')),
                        DropdownMenuItem(value: 'الهيكل الأكاديمي والشجرة', child: Text('الهيكل والشجرة الأكاديمية')),
                        DropdownMenuItem(value: 'الإشعارات والتنبيهات', child: Text('الإشعارات والتنبيهات')),
                        DropdownMenuItem(value: 'الموظفين والصلاحيات', child: Text('الموظفين والصلاحيات')),
                        DropdownMenuItem(value: 'النظام', child: Text('النظام وتسجيل الدخول')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          _selectedModule = val;
                          _loadLogs();
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // جدول السجلات
            if (_isLoading)
              const Center(child: Padding(padding: EdgeInsets.all(50), child: CircularProgressIndicator()))
            else if (_logs.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(40),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.assignment_turned_in_outlined, size: 56, color: Colors.grey),
                    SizedBox(height: 12),
                    Text('لا توجد عمليات مسجلة تطابق خيارات الفلترة المحددة',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.grey)),
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
                      DataColumn(label: Text('وقت وتاريخ الحركة')),
                      DataColumn(label: Text('الموظف المنفذ')),
                      DataColumn(label: Text('نوع الإجراء')),
                      DataColumn(label: Text('القسم / الموديول')),
                      DataColumn(label: Text('تفاصيل الإجراء والبيان')),
                      DataColumn(label: Text('معاينة')),
                    ],
                    rows: _logs.map((log) {
                      final badgeColor = _getActionColor(log.actionType);
                      return DataRow(cells: [
                        DataCell(
                          Text(
                            _formatDateTime(log.createdAt),
                            style: const TextStyle(fontFamily: 'monospace', fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ),
                        DataCell(
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 14,
                                backgroundColor: primaryNavy.withOpacity(0.1),
                                child: const Icon(Icons.person, size: 16, color: primaryNavy),
                              ),
                              const SizedBox(width: 8),
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(log.fullName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                                  Text('@${log.username}', style: TextStyle(color: Colors.grey.shade600, fontSize: 11)),
                                ],
                              ),
                            ],
                          ),
                        ),
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: badgeColor.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: badgeColor.withOpacity(0.4)),
                            ),
                            child: Text(
                              _getActionArabicText(log.actionType),
                              style: TextStyle(color: badgeColor, fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ),
                        ),
                        DataCell(
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(log.module, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                              if (log.targetService != null)
                                Text(log.targetService!, style: TextStyle(color: Colors.grey.shade600, fontSize: 11)),
                            ],
                          ),
                        ),
                        DataCell(
                          SizedBox(
                            width: 320,
                            child: Text(
                              log.description,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 12.5),
                            ),
                          ),
                        ),
                        DataCell(
                          IconButton(
                            icon: const Icon(Icons.visibility_outlined, size: 20, color: primaryNavy),
                            tooltip: 'عرض تفاصيل العملية والبيانات المخزنة',
                            onPressed: () => _showDetailsDialog(log),
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

  Widget _buildMetricCard(String title, String count, IconData icon, Color color) {
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
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600)),
                const SizedBox(height: 4),
                Text(count, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryNavy)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
