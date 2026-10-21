import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart' as xl;
import 'package:gic/services/supabase_service.dart';
import 'package:gic/services/fcm_sender_service.dart';
import 'package:gic/services/auth_service.dart';
import 'package:gic/services/password_security.dart';
import 'package:gic/services/permission_service.dart';
import 'package:gic/utils/file_exporter.dart';
import 'package:gic/widgets/desktop_scroll_view.dart';

class TreeNodeData {
  final String id;
  final String title;
  final String nodeType; // 'year', 'specialty', 'batch', 'semester', 'group'
  final String? parentId;
  final bool isFolder;
  final String? addLabel;
  final List<TreeNodeData> children;

  TreeNodeData({
    required this.id,
    required this.title,
    required this.nodeType,
    this.parentId,
    this.isFolder = true,
    this.addLabel,
    this.children = const [],
  });

  TreeNodeData copyWith({
    String? id,
    String? title,
    String? nodeType,
    String? parentId,
    bool? isFolder,
    String? addLabel,
    List<TreeNodeData>? children,
  }) {
    return TreeNodeData(
      id: id ?? this.id,
      title: title ?? this.title,
      nodeType: nodeType ?? this.nodeType,
      parentId: parentId ?? this.parentId,
      isFolder: isFolder ?? this.isFolder,
      addLabel: addLabel ?? this.addLabel,
      children: children ?? this.children,
    );
  }
}

class AcademicTreeView extends StatefulWidget {
  final Function(String action, TreeNodeData node)? onNodeAction;

  const AcademicTreeView({
    Key? key,
    this.onNodeAction,
  }) : super(key: key);

  @override
  State<AcademicTreeView> createState() => _AcademicTreeViewState();
}

class _AcademicTreeViewState extends State<AcademicTreeView> {
  static const Color accentGold = Color(0xFFC5A059);
  static const Color primaryNavy = Color(0xFF0E1B4D);

  String? selectedNodeId;
  List<TreeNodeData> treeData = [];
  bool isLoading = true;

  // طلاب المجموعة المحددة
  List<Map<String, dynamic>> studentsList = [];
  bool isLoadingStudents = false;
  String studentSearchQuery = '';
  Set<String> selectedStudentIds = {};
  final TextEditingController _genTitleCtrl = TextEditingController(text: 'إشعار أكاديمي هام');
  final TextEditingController _genBodyCtrl = TextEditingController();
  bool _isSendingGenNotif = false;

  SupabaseClient get supabase => AdminSupabase.client;

  bool _canTree(String serviceKey, PermissionAction action) {
    return PermissionService.can('academic_tree', serviceKey, action);
  }

  bool get _isTreeStructureReadOnly =>
      !_canTree('tree_structure', PermissionAction.create) &&
      !_canTree('tree_structure', PermissionAction.update) &&
      !_canTree('tree_structure', PermissionAction.delete);

  bool get _isTreeStudentsReadOnly =>
      !_canTree('tree_students', PermissionAction.create) &&
      !_canTree('tree_students', PermissionAction.update) &&
      !_canTree('tree_students', PermissionAction.delete);

  void _showNoPermissionSnack([String msg = '⚠️ عذراً، حسابك يملك صلاحية قراءة فقط في هذا القسم.']) {
    _showSnackbar(msg, isError: true);
  }

  Widget _buildTreeReadOnlyBanner(String message) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.amber.shade400, width: 1.2),
      ),
      child: Row(
        children: [
          Icon(Icons.lock_outline, color: Colors.amber.shade900, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: Colors.amber.shade900,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadTreeFromSupabase();
  }

  // --- تحميل الشجرة الأكاديمية بالكامل من Supabase ---
  Future<void> _loadTreeFromSupabase() async {
    setState(() => isLoading = true);
    try {
      final response = await supabase
          .from('academic_tree')
          .select()
          .order('created_at', ascending: true);

      final List<dynamic> rows = response as List<dynamic>;

      if (rows.isEmpty) {
        // إذا كان الجدول فارغاً، نضع بيانات افتراضية ونحفظها في Supabase
        await _seedDefaultTree();
        return;
      }

      // بناء الشجرة هرمياً من الصفوف
      final builtTree = _buildTreeFromFlatList(rows);
      setState(() {
        treeData = builtTree;
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading academic tree: $e');
      setState(() => isLoading = false);
      _showSnackbar('حدث خطأ في تحميل الشجرة الأكاديمية: $e', isError: true);
    }
  }

  // ملء الشجرة بالهيكل الأكاديمي الجديد المطابق للصورة
  Future<void> _seedDefaultTree() async {
    try {
      // المستوى 1: كلية الغد الدولية
      final collegeRes = await supabase.from('academic_tree').insert({
        'title': 'كلية الغد الدولية',
        'node_type': 'year',
        'parent_id': null,
      }).select().single();
      final String collegeId = collegeRes['id'];

      // المستوى 2: GIC
      final gicRes = await supabase.from('academic_tree').insert({
        'title': 'GIC',
        'node_type': 'specialty',
        'parent_id': collegeId,
      }).select().single();
      final String gicId = gicRes['id'];

      // المستوى 3 (أ): قسم العلوم الصحية
      final healthRes = await supabase.from('academic_tree').insert({
        'title': 'قسم العلوم الصحية',
        'node_type': 'batch',
        'parent_id': gicId,
      }).select().single();
      final String healthId = healthRes['id'];

      // المستوى 4: فني صيدلة
      final pharmacyRes = await supabase.from('academic_tree').insert({
        'title': 'فني صيدلة',
        'node_type': 'semester',
        'parent_id': healthId,
      }).select().single();
      final String pharmacyId = pharmacyRes['id'];

      // المستوى 5: الدفعة 1
      final batch1Res = await supabase.from('academic_tree').insert({
        'title': 'الدفعة 1',
        'node_type': 'group_shift',
        'parent_id': pharmacyId,
      }).select().single();
      final String batch1Id = batch1Res['id'];

      // المستوى 6: الفصول الدراسية تحت الدفعة 1
      final semNames = [
        'الفصل الأول 2020/2019 (1)',
        'الفصل الثاني 2020/2019 (2)',
        'الفصل الثالث 2021/2020 (1)',
        'الفصل الرابع 2021/2020 (2)',
        'الفصل الخامس 2022/2021 (1)',
        'الفصل السادس 2022/2021 (2)',
      ];
      for (final sem in semNames) {
        await supabase.from('academic_tree').insert({
          'title': sem,
          'node_type': 'group_shift',
          'parent_id': batch1Id,
        });
      }

      // المستوى 3 (ب): القسم التقني
      final techRes = await supabase.from('academic_tree').insert({
        'title': 'القسم التقني',
        'node_type': 'batch',
        'parent_id': gicId,
      }).select().single();
      final String techId = techRes['id'];

      // المستوى 4: تقنية المعلومات
      await supabase.from('academic_tree').insert({
        'title': 'تقنية المعلومات',
        'node_type': 'semester',
        'parent_id': techId,
      });

      await _loadTreeFromSupabase();
    } catch (e) {
      debugPrint('Error seeding default tree: $e');
      setState(() => isLoading = false);
    }
  }

  List<TreeNodeData> _buildTreeFromFlatList(List<dynamic> rows) {
    Map<String?, List<dynamic>> childrenMap = {};
    for (var row in rows) {
      final pId = row['parent_id'] as String?;
      childrenMap.putIfAbsent(pId, () => []).add(row);
    }

    List<TreeNodeData> buildNodes(String? parentId) {
      final list = childrenMap[parentId] ?? [];
      return list.map((item) {
        final id = item['id'].toString();
        final title = item['title'].toString();
        final nodeType = item['node_type'].toString();

        final titleClean = title.trim();
        final isBatch = titleClean.contains('دفع') || nodeType == 'batch_node' || nodeType == 'group';
        final isSemester = (titleClean.contains('فصل') || titleClean.contains('الفصل') || titleClean.contains('خريج')) && !isBatch;
        final isFolder = isBatch || (!isSemester && nodeType != 'group_shift') || (childrenMap[id]?.isNotEmpty ?? false);

        String? addLabel;
        if (nodeType == 'year') addLabel = 'إضافة فرع / مبنى';
        if (nodeType == 'specialty') addLabel = 'إضافة قسم جديد';
        if (nodeType == 'batch') addLabel = 'إضافة تخصص جديد';
        if (nodeType == 'semester') addLabel = 'إضافة دفعة جديدة';
        if (isBatch) addLabel = 'إضافة فصل دراسي';

        return TreeNodeData(
          id: id,
          title: title,
          nodeType: nodeType,
          parentId: parentId,
          isFolder: isFolder,
          addLabel: addLabel,
          children: buildNodes(id),
        );
      }).toList();
    }

    return buildNodes(null);
  }

  TreeNodeData? _findNodeById(List<TreeNodeData> nodes, String id) {
    for (var node in nodes) {
      if (node.id == id) return node;
      if (node.children.isNotEmpty) {
        final found = _findNodeById(node.children, id);
        if (found != null) return found;
      }
    }
    return null;
  }

  // استخراج مسار الشجرة الكامل لمعرفة (الكلية، الفرع، القسم، التخصص، الدفعة، الفصل)
  Map<String, String> _getHierarchyContext(String targetId) {
    Map<String, String> context = {
      'college': 'كلية الغد الدولية',
      'branch': 'GIC',
      'department': 'قسم العلوم الصحية',
      'specialty': 'فني صيدلة',
      'batch': 'الدفعة 1',
      'semester': 'الفصل الأول 2020/2019 (1)',
      'academic_year': '2020/2019',
      'group_name': 'الدفعة 1',
      'study_shift': 'صباحية',
    };

    List<TreeNodeData> path = [];
    bool findPath(List<TreeNodeData> nodes) {
      for (var node in nodes) {
        path.add(node);
        if (node.id == targetId) return true;
        if (findPath(node.children)) return true;
        path.removeLast();
      }
      return false;
    }

    findPath(treeData);

    for (var node in path) {
      final clean = node.title.replaceFirst(RegExp(r'^[^:]+:\s*'), '').trim();
      if (node.nodeType == 'year') context['college'] = clean;
      if (node.nodeType == 'specialty') context['branch'] = clean;
      if (node.nodeType == 'batch') context['department'] = clean;
      if (node.nodeType == 'semester') context['specialty'] = clean;
      if (node.nodeType == 'group_shift' || node.nodeType == 'group' || node.nodeType == 'batch_node' || node.nodeType == 'semester_node') {
        if (clean.contains('دفع')) {
          context['batch'] = clean;
          context['group_name'] = clean;
        } else if (clean.contains('فصل') || clean.contains('الفصل') || clean.contains('خريج') || node.nodeType == 'group_shift' || node.nodeType == 'semester_node') {
          context['semester'] = clean;
          final match = RegExp(r'(\d{4}/\d{4}|\d{4}-\d{4})').firstMatch(clean);
          if (match != null) {
            context['academic_year'] = match.group(1)!;
          }
        }
      }
    }

    return context;
  }

  /// حساب المستوى الدراسي تلقائياً بناءً على الفصل الدراسي الحالي للطالب
  /// - الفصل الأول أو الثاني -> المستوى الأول
  /// - الفصل الثالث أو الرابع -> المستوى الثاني
  /// - الفصل الخامس أو السادس -> المستوى الثالث
  /// - الفصل السابع أو الثامن -> المستوى الرابع
  /// - فصل الخريجين -> خريج
  String _resolveLevelFromSemester(String? semester) {
    final rawSem = (semester ?? '').trim();
    if (rawSem.contains('خريج')) return 'خريج';
    if (rawSem.contains('سابع') || rawSem.contains('السابع') || rawSem.contains('ثامن') || rawSem.contains('الثامن')) {
      return 'المستوى الرابع';
    }
    if (rawSem.contains('خامس') || rawSem.contains('الخامس') || rawSem.contains('سادس') || rawSem.contains('السادس')) {
      return 'المستوى الثالث';
    }
    if (rawSem.contains('ثالث') || rawSem.contains('الثالث') || rawSem.contains('رابع') || rawSem.contains('الرابع')) {
      return 'المستوى الثاني';
    }
    if (rawSem.contains('أول') || rawSem.contains('اول') || rawSem.contains('الأول') || rawSem.contains('الاول') ||
        rawSem.contains('ثاني') || rawSem.contains('الثاني')) {
      return 'المستوى الأول';
    }

    final cleanedNumbers = rawSem
        .replaceAll(RegExp(r'\d{4}\s*[/\-]\s*\d{4}'), '')
        .replaceAll(RegExp(r'\b20\d{2}\b'), '')
        .replaceAll(RegExp(r'\(\s*\d+\s*\)'), '');

    if (RegExp(r'(?:^|\D)[78](?:\D|$)').hasMatch(cleanedNumbers)) return 'المستوى الرابع';
    if (RegExp(r'(?:^|\D)[56](?:\D|$)').hasMatch(cleanedNumbers)) return 'المستوى الثالث';
    if (RegExp(r'(?:^|\D)[34](?:\D|$)').hasMatch(cleanedNumbers)) return 'المستوى الثاني';
    return 'المستوى الأول';
  }

  // --- تحميل طلاب الفصل الدراسي / الدفعة المحددة ---
  Future<void> _loadStudentsForGroup(String groupId) async {
    final node = _findNodeById(treeData, groupId);
    if (node == null || node.isFolder) return;

    setState(() => isLoadingStudents = true);
    final ctx = _getHierarchyContext(groupId);

    try {
      var query = supabase.from('students').select().eq('specialty', ctx['specialty']!);
      if (ctx.containsKey('semester') && ctx['semester']!.isNotEmpty) {
        query = query.eq('semester', ctx['semester']!);
      }
      final res = await query.order('academic_id', ascending: true);
      final list = List<Map<String, dynamic>>.from(res as List);

      // فحص حالة حجب النتيجة لكل طالب من student_results
      try {
        final ids = list.map((s) => s['academic_id']?.toString().trim() ?? '').where((id) => id.isNotEmpty).toList();
        if (ids.isNotEmpty) {
          final resultsRes = await supabase.from('student_results').select('academic_id, subjects').filter('academic_id', 'in', ids);
          final Map<String, bool> hiddenMap = {};
          for (var r in resultsRes as List) {
            final aid = r['academic_id']?.toString().trim() ?? '';
            final subs = r['subjects'];
            if (subs is Map && (subs['is_result_hidden'] == true || subs['is_hidden'] == true)) {
              hiddenMap[aid] = true;
            }
          }
          for (var st in list) {
            final aid = st['academic_id']?.toString().trim() ?? '';
            if (hiddenMap[aid] == true) {
              st['is_result_hidden'] = true;
            }
          }
        }
      } catch (e) {
        debugPrint('Error mapping hidden results: $e');
      }

      setState(() {
        studentsList = list;
        isLoadingStudents = false;
      });
    } catch (e) {
      debugPrint('Error loading students: $e');
      setState(() => isLoadingStudents = false);
    }
  }

  void _showSnackbar(String msg, {bool isError = false}) {
    if (!mounted) return;
    String cleanMsg = msg;
    if (isError) {
      debugPrint('[AdminTree Error]: $msg');
      if (cleanMsg.contains('PostgrestException') ||
          cleanMsg.contains('Exception') ||
          cleanMsg.contains('SocketException') ||
          cleanMsg.contains('code:')) {
        if (cleanMsg.contains('duplicate') || cleanMsg.contains('23505') || cleanMsg.contains('already exists')) {
          cleanMsg = 'هذا السجل أو الرقم مسجل مسبقاً في النظام';
        } else if (cleanMsg.contains('SocketException') || cleanMsg.contains('Failed host lookup') || cleanMsg.contains('timed out')) {
          cleanMsg = 'تعذر الاتصال بالخادم، يرجى التحقق من اتصال الإنترنت';
        } else {
          final colonIdx = cleanMsg.indexOf(':');
          if (colonIdx > 0 && colonIdx < 40) {
            cleanMsg = cleanMsg.substring(0, colonIdx).trim() + '، يرجى المحاولة مجدداً أو التحقق من البيانات';
          } else {
            cleanMsg = 'حدث خطأ أثناء تنفيذ العملية، يرجى التحقق وإعادة المحاولة';
          }
        }
      }
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(cleanMsg, textDirection: TextDirection.rtl),
        backgroundColor: isError ? Colors.red.shade700 : Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ==========================================
  // النوافذ المنبثقة للعمليات (Dialogs)
  // ==========================================

  // 1. إضافة كلية / مؤسسة جديدة (جذر الشجرة)
  void _showAddYearDialog() {
    if (!_canTree('tree_structure', PermissionAction.create)) {
      _showNoPermissionSnack('⚠️ عذراً، حسابك لا يملك صلاحية إضافة فروع للشجرة الأكاديمية.');
      return;
    }
    final controller = TextEditingController(text: 'كلية الغد الدولية');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('إضافة كلية / مؤسسة جديدة', textDirection: TextDirection.rtl, style: TextStyle(fontWeight: FontWeight.bold, color: primaryNavy)),
        content: TextField(
          controller: controller,
          textDirection: TextDirection.rtl,
          decoration: const InputDecoration(
            labelText: 'اسم الكلية / المؤسسة',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: accentGold),
            onPressed: () async {
              final val = controller.text.trim();
              if (val.isEmpty) return;
              Navigator.pop(ctx);
              try {
                await supabase.from('academic_tree').insert({
                  'title': val,
                  'node_type': 'year',
                  'parent_id': null,
                });
                _showSnackbar('تمت إضافة الكلية بنجاح');
                await _loadTreeFromSupabase();
              } catch (e) {
                _showSnackbar('فشلت الإضافة: $e', isError: true);
              }
            },
            child: const Text('إضافة', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // 2. إضافة عنصر فرعي في الشجرة (فرع، قسم، تخصص، دفعة، فصل)
  void _showAddChildDialog(TreeNodeData parent) {
    if (!_canTree('tree_structure', PermissionAction.create)) {
      _showNoPermissionSnack('⚠️ عذراً، حسابك لا يملك صلاحية إضافة فروع للشجرة الأكاديمية.');
      return;
    }
    String childType = '';
    String labelText = '';
    bool isAddingSemester = false;

    final pTitle = parent.title.trim();
    final bool parentIsBatch = pTitle.contains('دفع') || parent.nodeType == 'batch_node' || parent.nodeType == 'group';

    if (parentIsBatch) {
      childType = 'group_shift';
      labelText = 'الفصل الدراسي مع السنة (مثال: الفصل الأول 2024/2025)';
      isAddingSemester = true;
    } else if (parent.nodeType == 'year') {
      childType = 'specialty';
      labelText = 'اسم الفرع / المركز (مثال: GIC)';
    } else if (parent.nodeType == 'specialty') {
      childType = 'batch';
      labelText = 'اسم القسم (مثال: قسم العلوم الصحية)';
    } else if (parent.nodeType == 'batch') {
      childType = 'semester';
      labelText = 'اسم التخصص (مثال: فني صيدلة)';
    } else if (parent.nodeType == 'semester') {
      childType = 'group_shift';
      labelText = 'اسم أو رقم الدفعة (مثال: الدفعة 1)';
    } else {
      childType = 'group_shift';
      labelText = 'عنصر جديد';
    }

    final nameController = TextEditingController();
    final yearStr = '${DateTime.now().year}/${DateTime.now().year - 1}';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          title: Text(
            isAddingSemester ? 'إضافة فصل دراسي للدفعة (${parent.title})' : 'إضافة $labelText',
            textDirection: TextDirection.rtl,
            style: const TextStyle(fontWeight: FontWeight.bold, color: primaryNavy),
          ),
          content: SizedBox(
            width: 480,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isAddingSemester) ...[
                  const Text('خيارات سريعة لاختيار الفصل الدراسي:', style: TextStyle(fontSize: 13, color: Colors.black54)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      'الفصل الأول',
                      'الفصل الثاني',
                      'الفصل الثالث',
                      'الفصل الرابع',
                      'الفصل الخامس',
                      'الفصل السادس',
                    ].map((term) {
                      return ActionChip(
                        label: Text(term, style: const TextStyle(fontSize: 12)),
                        backgroundColor: Colors.blue.shade50,
                        onPressed: () {
                          setModalState(() {
                            nameController.text = '$term $yearStr';
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                ],
                TextField(
                  controller: nameController,
                  textDirection: TextDirection.rtl,
                  decoration: InputDecoration(
                    labelText: labelText,
                    border: const OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: accentGold),
              onPressed: () async {
                final input = nameController.text.trim();
                if (input.isEmpty) return;
                Navigator.pop(ctx);

                try {
                  await supabase.from('academic_tree').insert({
                    'title': input,
                    'node_type': childType,
                    'parent_id': parent.id,
                  });
                  _showSnackbar('تمت إضافة ($input) بنجاح');
                  await _loadTreeFromSupabase();
                } catch (e) {
                  _showSnackbar('فشلت الإضافة: $e', isError: true);
                }
              },
              child: const Text('إضافة', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  // 3. تعديل اسم العنصر
  void _showEditTitleDialog(TreeNodeData node) {
    if (!_canTree('tree_structure', PermissionAction.update)) {
      _showNoPermissionSnack('⚠️ عذراً، حسابك لا يملك صلاحية تعديل فروع الشجرة الأكاديمية.');
      return;
    }
    final controller = TextEditingController(text: node.title);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تعديل الاسم', textDirection: TextDirection.rtl, style: TextStyle(fontWeight: FontWeight.bold, color: primaryNavy)),
        content: TextField(
          controller: controller,
          textDirection: TextDirection.rtl,
          decoration: const InputDecoration(
            labelText: 'الاسم الجديد',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade700),
            onPressed: () async {
              final newTitle = controller.text.trim();
              if (newTitle.isEmpty) return;
              Navigator.pop(ctx);
              try {
                await supabase
                    .from('academic_tree')
                    .update({'title': newTitle})
                    .eq('id', node.id);
                _showSnackbar('تم تعديل الاسم بنجاح');
                await _loadTreeFromSupabase();
              } catch (e) {
                _showSnackbar('فشل التعديل: $e', isError: true);
              }
            },
            child: const Text('حفظ التعديل', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // 4. حذف عنصر من الشجرة
  void _showDeleteNodeDialog(TreeNodeData node) {
    if (!_canTree('tree_structure', PermissionAction.delete)) {
      _showNoPermissionSnack('⚠️ عذراً، حسابك لا يملك صلاحية حذف فروع الشجرة الأكاديمية.');
      return;
    }
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تأكيد الحذف', textDirection: TextDirection.rtl, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
        content: Text('هل أنت متأكد من حذف "${node.title}" وجميع العناصر المتفرعة منها؟', textDirection: TextDirection.rtl),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await supabase.from('academic_tree').delete().eq('id', node.id);
                setState(() => selectedNodeId = null);
                _showSnackbar('تم حذف العنصر بنجاح');
                await _loadTreeFromSupabase();
              } catch (e) {
                _showSnackbar('فشل الحذف: $e', isError: true);
              }
            },
            child: const Text('حذف', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // 5. إضافة طالب يدوياً
  void _showAddStudentManualDialog(TreeNodeData groupNode) {
    if (!_canTree('tree_students', PermissionAction.create)) {
      _showNoPermissionSnack('⚠️ عذراً، حسابك لا يملك صلاحية إضافة طلاب في الشجرة الأكاديمية.');
      return;
    }
    final ctx = _getHierarchyContext(groupNode.id);

    final idController = TextEditingController();
    final nameController = TextEditingController();
    final passController = TextEditingController(text: 'password');
    final emailController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('إضافة طالب يدوياً', textDirection: TextDirection.rtl, style: TextStyle(fontWeight: FontWeight.bold, color: primaryNavy)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Text(
                  'المسار: ${ctx['academic_year']} > ${ctx['specialty']} > ${ctx['batch']} > ${ctx['group_name']} (${ctx['study_shift']})',
                  style: const TextStyle(fontSize: 12, color: primaryNavy, fontWeight: FontWeight.bold),
                  textDirection: TextDirection.rtl,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: idController,
                textDirection: TextDirection.ltr,
                decoration: const InputDecoration(
                  labelText: 'الرقم الأكاديمي (Primary Key الفريد)',
                  hintText: 'مثال: 2024000005',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.badge_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nameController,
                textDirection: TextDirection.rtl,
                decoration: const InputDecoration(
                  labelText: 'اسم الطالب رباعي',
                  hintText: 'مثال: محمد أحمد علي صالح',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: passController,
                textDirection: TextDirection.ltr,
                decoration: const InputDecoration(
                  labelText: 'كلمة السر',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock_outline),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailController,
                textDirection: TextDirection.ltr,
                decoration: const InputDecoration(
                  labelText: 'البريد الإلكتروني',
                  hintText: 'مثال: student@gmail.com',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email_outlined),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: primaryNavy),
            onPressed: () async {
              final academicId = idController.text.trim();
              final fullName = nameController.text.trim();
              final password = passController.text.trim();
              final email = emailController.text.trim();

              if (academicId.isEmpty || fullName.isEmpty || password.isEmpty || email.isEmpty) {
                _showSnackbar('يرجى ملء جميع الحقول المطلوبة', isError: true);
                return;
              }

              Navigator.pop(dialogCtx);

              try {
                await supabase.from('students').insert({
                  'academic_id': academicId,
                  'full_name': fullName,
                  'password': PasswordSecurity.hashPassword(password),
                  'email': email,
                  'academic_year': ctx['academic_year']!,
                  'specialty': ctx['specialty']!,
                  'batch': ctx['batch']!,
                  'semester': ctx['semester']!,
                  'group_name': ctx['group_name']!,
                  'study_shift': ctx['study_shift']!,
                  'level': _resolveLevelFromSemester(ctx['semester']),
                  'is_blocked': false,
                  'failed_attempts': 0,
                });

                _showSnackbar('تمت إضافة الطالب ($fullName) بنجاح');
                await _loadStudentsForGroup(groupNode.id);
              } catch (e) {
                _showSnackbar('فشلت إضافة الطالب: $e', isError: true);
              }
            },
            child: const Text('إضافة الطالب', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // 6. استيراد الطلاب من ملف Excel
  Future<void> _importStudentsFromExcel(TreeNodeData groupNode) async {
    if (!_canTree('tree_students', PermissionAction.create)) {
      _showNoPermissionSnack('⚠️ عذراً، حسابك لا يملك صلاحية استيراد طلاب من Excel.');
      return;
    }
    final ctx = _getHierarchyContext(groupNode.id);

    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
        withData: true,
      );

      if (result == null || result.files.single.bytes == null) return;

      final Uint8List bytes = result.files.single.bytes!;
      final excel = xl.Excel.decodeBytes(bytes);

      List<Map<String, dynamic>> studentsToInsert = [];

      for (var table in excel.tables.keys) {
        final rows = excel.tables[table]!.rows;
        if (rows.isEmpty) continue;

        // نفترض أن الصف الأول رؤوس أعمدة: الرقم الأكاديمي، الاسم، كلمة السر، الإيميل
        for (int i = 1; i < rows.length; i++) {
          final row = rows[i];
          if (row.isEmpty || row[0] == null) continue;

          final academicId = row[0]?.value?.toString().trim() ?? '';
          final fullName = (row.length > 1 ? row[1]?.value?.toString().trim() : '') ?? '';
          final password = (row.length > 2 ? row[2]?.value?.toString().trim() : 'password') ?? 'password';
          final email = (row.length > 3 ? row[3]?.value?.toString().trim() : '') ?? '';

          if (academicId.isNotEmpty && fullName.isNotEmpty) {
            studentsToInsert.add({
              'academic_id': academicId,
              'full_name': fullName,
              'password': PasswordSecurity.hashPassword(password.isEmpty ? 'password' : password),
              'email': email.isEmpty ? '$academicId@student.gic.edu' : email,
              'academic_year': ctx['academic_year']!,
              'specialty': ctx['specialty']!,
              'batch': ctx['batch']!,
              'semester': ctx['semester']!,
              'group_name': ctx['group_name']!,
              'study_shift': ctx['study_shift']!,
              'level': _resolveLevelFromSemester(ctx['semester']),
              'is_blocked': false,
              'failed_attempts': 0,
            });
          }
        }
      }

      if (studentsToInsert.isEmpty) {
        _showSnackbar('لم يتم العثور على بيانات طلاب صالحة في ملف Excel', isError: true);
        return;
      }

      // إرسال الطلاب إلى Supabase
      await supabase.from('students').upsert(studentsToInsert);

      _showSnackbar('تم بنجاح استيراد ${studentsToInsert.length} طالب إلى ${ctx['group_name']}');
      await _loadStudentsForGroup(groupNode.id);
    } catch (e) {
      debugPrint('Error importing Excel: $e');
      _showSnackbar('حدث خطأ أثناء قراءة ملف Excel: $e', isError: true);
    }
  }

  // 7. تعديل بيانات طالب (يشمل الرقم الأكاديمي، الاسم، كلمة السر، الإيميل)
  void _showEditStudentDialog(Map<String, dynamic> student, TreeNodeData groupNode) {
    if (!_canTree('tree_students', PermissionAction.update)) {
      _showNoPermissionSnack('⚠️ عذراً، حسابك لا يملك صلاحية تعديل بيانات الطلاب.');
      return;
    }
    final oldAcademicId = student['academic_id']?.toString() ?? '';
    final idController = TextEditingController(text: oldAcademicId);
    final nameController = TextEditingController(text: student['full_name']);
    final passController = TextEditingController(text: student['password']);
    final emailController = TextEditingController(text: student['email']);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('تعديل الطالب: $oldAcademicId', textDirection: TextDirection.rtl, style: const TextStyle(fontWeight: FontWeight.bold, color: primaryNavy)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: idController,
                textDirection: TextDirection.ltr,
                decoration: const InputDecoration(labelText: 'الرقم الأكاديمي (ID)', border: OutlineInputBorder(), prefixIcon: Icon(Icons.badge_outlined)),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nameController,
                textDirection: TextDirection.rtl,
                decoration: const InputDecoration(labelText: 'الاسم الرباعي', border: OutlineInputBorder(), prefixIcon: Icon(Icons.person_outline)),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: passController,
                textDirection: TextDirection.ltr,
                decoration: const InputDecoration(labelText: 'كلمة السر الجديدة (اتركه فارغاً للإبقاء على الحالية)', border: OutlineInputBorder(), prefixIcon: Icon(Icons.lock_outline)),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailController,
                textDirection: TextDirection.ltr,
                decoration: const InputDecoration(labelText: 'البريد الإلكتروني', border: OutlineInputBorder(), prefixIcon: Icon(Icons.email_outlined)),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade700),
            onPressed: () async {
              final newId = idController.text.trim();
              if (newId.isEmpty) {
                _showSnackbar('لا يمكن ترك الرقم الأكاديمي فارغاً', isError: true);
                return;
              }
              Navigator.pop(ctx);
              try {
                await supabase.from('students').update({
                  'academic_id': newId,
                  'full_name': nameController.text.trim(),
                  'password': passController.text.trim(),
                  'email': emailController.text.trim(),
                }).eq('academic_id', oldAcademicId);

                _showSnackbar('تم تعديل بيانات الطالب بنجاح');
                await _loadStudentsForGroup(groupNode.id);
              } catch (e) {
                _showSnackbar('فشل التعديل: $e', isError: true);
              }
            },
            child: const Text('حفظ التعديل', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // 8. توقيف أو تنشيط حساب الطالب
  Future<void> _toggleBlockStudent(Map<String, dynamic> student, TreeNodeData groupNode) async {
    if (!_canTree('tree_students', PermissionAction.update)) {
      _showNoPermissionSnack('⚠️ عذراً، حسابك لا يملك صلاحية إيقاف أو تنشيط حسابات الطلاب.');
      return;
    }
    final String acadId = (student['academic_id'] ?? '').toString().trim();
    if (acadId.isEmpty) return;
    final bool currentBlocked = student['is_blocked'] ?? false;
    final bool newBlocked = !currentBlocked;

    setState(() {
      student['is_blocked'] = newBlocked;
    });

    try {
      await supabase
          .from('students')
          .update({'is_blocked': newBlocked})
          .eq('academic_id', acadId);

      _showSnackbar(newBlocked ? 'تم إيقاف حساب الطالب ($acadId) بنجاح' : 'تم تنشيط حساب الطالب ($acadId) بنجاح');
      await _loadStudentsForGroup(groupNode.id);
    } catch (e) {
      setState(() {
        student['is_blocked'] = currentBlocked;
      });
      _showSnackbar('فشلت العملية: $e', isError: true);
    }
  }

  // 9. ترقية طلاب هذا الفصل إلى الفصل التالي (إفراغ هذا الفصل ونقل الطلاب إلى الفصل المختار)
  void _showPromoteSemesterDialog(TreeNodeData currentSemesterNode) {
    if (!_canTree('tree_students', PermissionAction.update)) {
      _showNoPermissionSnack('⚠️ عذراً، حسابك لا يملك صلاحية ترقية طلاب الفصل.');
      return;
    }
    final ctx = _getHierarchyContext(currentSemesterNode.id);
    final currentSemTitle = currentSemesterNode.title;

    // البحث عن الفصول المجاورة داخل نفس الدفعة لاختيار الفصل المستهدف
    TreeNodeData? batchParent;
    if (currentSemesterNode.parentId != null) {
      batchParent = _findNodeById(treeData, currentSemesterNode.parentId!);
    }

    final targetSemesters = batchParent?.children.where((c) => c.id != currentSemesterNode.id).toList() ?? [];

    if (targetSemesters.isEmpty) {
      _showSnackbar('لا يوجد فصول دراسية أخرى داخل هذه الدفعة للترقية إليها. يرجى إنشاء الفصل التالي أولاً.', isError: true);
      return;
    }

    TreeNodeData selectedTarget = targetSemesters.first;

    showDialog(
      context: context,
      builder: (ctxDialog) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          title: Row(
            children: const [
              Icon(Icons.upgrade, color: Colors.blueAccent),
              SizedBox(width: 8),
              Text('ترقية طلاب الفصل الدراسي', style: TextStyle(fontWeight: FontWeight.bold, color: primaryNavy)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'سيتم نقل جميع طلاب "$currentSemTitle" (${studentsList.length} طالب) إلى الفصل الجديد وإفراغ هذا الفصل.',
                style: const TextStyle(fontSize: 14, height: 1.4),
              ),
              const SizedBox(height: 16),
              const Text('اختر الفصل الدراسي المستهدف للترقية إليه:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 8),
              DropdownButtonFormField<TreeNodeData>(
                value: selectedTarget,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                items: targetSemesters.map((s) {
                  return DropdownMenuItem<TreeNodeData>(
                    value: s,
                    child: Text(s.title, style: const TextStyle(fontSize: 13)),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setModalState(() => selectedTarget = val);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctxDialog),
              child: const Text('إلغاء'),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade800,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              ),
              onPressed: () async {
                Navigator.pop(ctxDialog);
                await _executePromoteSemester(
                  fromSemester: currentSemTitle,
                  toSemester: selectedTarget.title,
                  specialty: ctx['specialty']!,
                  batch: ctx['batch']!,
                  targetNodeId: selectedTarget.id,
                );
              },
              icon: const Icon(Icons.check, color: Colors.white, size: 18),
              label: const Text('تأكيد الترقية', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _executePromoteSemester({
    required String fromSemester,
    required String toSemester,
    required String specialty,
    required String batch,
    String? targetNodeId,
  }) async {
    setState(() => isLoadingStudents = true);
    try {
      final newLevel = _resolveLevelFromSemester(toSemester);
      // تحديث حقل الفصل الدراسي والمستوى المقابل له لجميع طلاب هذا الفصل
      await supabase
          .from('students')
          .update({
            'semester': toSemester,
            'level': newLevel,
          })
          .eq('specialty', specialty)
          .eq('semester', fromSemester);

      _showSnackbar('تمت ترقية الطلاب بنجاح من ($fromSemester) إلى ($toSemester - $newLevel)');

      // إعادة تحميل القائمة
      if (selectedNodeId != null) {
        await _loadStudentsForGroup(selectedNodeId!);
      }
    } catch (e) {
      _showSnackbar('فشلت عملية الترقية: $e', isError: true);
      setState(() => isLoadingStudents = false);
    }
  }

  // 9.2 ترقية طالب مفرد إلى فصل دراسي مختار مع تحديث مستواه تلقائياً
  void _showPromoteSingleStudentDialog(Map<String, dynamic> student, TreeNodeData currentSemesterNode) {
    if (!_canTree('tree_students', PermissionAction.update)) {
      _showNoPermissionSnack('⚠️ عذراً، حسابك لا يملك صلاحية ترقية الطالب.');
      return;
    }
    final academicId = (student['academic_id'] ?? '').toString().trim();
    final fullName = (student['full_name'] ?? '').toString().trim();
    if (academicId.isEmpty) return;

    TreeNodeData? batchParent;
    if (currentSemesterNode.parentId != null) {
      batchParent = _findNodeById(treeData, currentSemesterNode.parentId!);
    }

    final targetSemesters = batchParent?.children.where((c) => c.id != currentSemesterNode.id).toList() ?? [];
    if (targetSemesters.isEmpty) {
      _showSnackbar('لا يوجد فصول دراسية أخرى داخل هذه الدفعة للترقية إليها. يرجى إنشاء الفصل التالي أولاً.', isError: true);
      return;
    }

    TreeNodeData selectedTarget = targetSemesters.first;

    showDialog(
      context: context,
      builder: (ctxDialog) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          title: Row(
            children: const [
              Icon(Icons.upgrade, color: Colors.blueAccent),
              SizedBox(width: 8),
              Text('ترقية الطالب إلى فصل دراسي', style: TextStyle(fontWeight: FontWeight.bold, color: primaryNavy)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ترقية الطالب "$fullName" ($academicId) من "${currentSemesterNode.title}" إلى الفصل المختار:',
                style: const TextStyle(fontSize: 14, height: 1.4),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<TreeNodeData>(
                value: selectedTarget,
                decoration: const InputDecoration(
                  labelText: 'الفصل الدراسي الجديد',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                items: targetSemesters.map((s) {
                  return DropdownMenuItem<TreeNodeData>(
                    value: s,
                    child: Text('${s.title} (${_resolveLevelFromSemester(s.title)})', style: const TextStyle(fontSize: 13)),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setModalState(() => selectedTarget = val);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctxDialog),
              child: const Text('إلغاء'),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade800,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              ),
              onPressed: () async {
                Navigator.pop(ctxDialog);
                setState(() => isLoadingStudents = true);
                try {
                  final toSem = selectedTarget.title.replaceFirst(RegExp(r'^[^:]+:\s*'), '').trim();
                  final newLevel = _resolveLevelFromSemester(toSem);
                  await supabase
                      .from('students')
                      .update({
                        'semester': toSem,
                        'level': newLevel,
                      })
                      .eq('academic_id', academicId);
                  _showSnackbar('تمت ترقية الطالب ($fullName) إلى ($toSem - $newLevel) بنجاح');
                  if (selectedNodeId != null) {
                    await _loadStudentsForGroup(selectedNodeId!);
                  }
                } catch (e) {
                  _showSnackbar('فشلت عملية ترقية الطالب: $e', isError: true);
                  setState(() => isLoadingStudents = false);
                }
              },
              icon: const Icon(Icons.check, color: Colors.white, size: 18),
              label: const Text('تأكيد الترقية', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  // 10. ترقية الكل: ترقية جميع فصول الدفعة خطوة للأمام
  void _showPromoteAllSemestersDialog(TreeNodeData semesterNode) {
    if (!_canTree('tree_students', PermissionAction.update)) {
      _showNoPermissionSnack('⚠️ عذراً، حسابك لا يملك صلاحية ترقية فصول الدفعة.');
      return;
    }
    TreeNodeData? batchParent;
    if (semesterNode.parentId != null) {
      batchParent = _findNodeById(treeData, semesterNode.parentId!);
    }

    if (batchParent == null || batchParent.children.length < 2) {
      _showSnackbar('يجب أن تحتوي الدفعة على فصلين على الأقل لتنفيذ ترقية شاملة.', isError: true);
      return;
    }

    final allSemesters = batchParent.children;
    final ctx = _getHierarchyContext(semesterNode.id);

    showDialog(
      context: context,
      builder: (ctxDialog) => AlertDialog(
        title: Row(
          children: const [
            Icon(Icons.published_with_changes, color: Colors.orange),
            SizedBox(width: 8),
            Text('ترقية كل الفصول في الدفعة', style: TextStyle(fontWeight: FontWeight.bold, color: primaryNavy)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'هل أنت متأكد من ترحيل وترقية جميع الفصول الدراسية في "${batchParent!.title}" بالترتيب؟',
              style: const TextStyle(fontSize: 14, height: 1.4),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.shade300),
              ),
              child: const Text(
                'ملاحظة: سيتم نقل طلاب كل فصل إلى الفصل التالي له مباشرة ضمن الدفعة بالترتيب التصاعدي.',
                style: TextStyle(fontSize: 12, color: Colors.black87),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctxDialog),
            child: const Text('إلغاء'),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange.shade800),
            onPressed: () async {
              Navigator.pop(ctxDialog);
              setState(() => isLoadingStudents = true);
              try {
                // ترقية من الأخير إلى الأول حتى لا تتداخل البيانات
                for (int i = allSemesters.length - 2; i >= 0; i--) {
                  final fromSem = allSemesters[i].title;
                  final toSem = allSemesters[i + 1].title;
                  final newLevel = _resolveLevelFromSemester(toSem);
                  await supabase
                      .from('students')
                      .update({
                        'semester': toSem,
                        'level': newLevel,
                      })
                      .eq('specialty', ctx['specialty']!)
                      .eq('semester', fromSem);
                }
                _showSnackbar('تمت ترقية جميع فصول الدفعة بنجاح');
                if (selectedNodeId != null) {
                  await _loadStudentsForGroup(selectedNodeId!);
                }
              } catch (e) {
                _showSnackbar('حدث خطأ أثناء ترقية الفصول: $e', isError: true);
                setState(() => isLoadingStudents = false);
              }
            },
            icon: const Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
            label: const Text('تأكيد ترقية الكل', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // 11. إرسال إشعار للطالب
  void _showSendNotificationDialog(List<String> studentIds, String studentName) {
    final canNotify = PermissionService.can('notifications', 'send_notifications', PermissionAction.create) ||
        _canTree('tree_students', PermissionAction.create);
    if (!canNotify) {
      _showNoPermissionSnack('⚠️ عذراً، حسابك لا يملك صلاحية إرسال إشعارات للطلاب.');
      return;
    }
    final titleController = TextEditingController(text: 'إشعار من الكلية');
    final messageController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(studentIds.length == 1 ? 'إرسال إشعار للطالب: $studentName' : 'إرسال إشعار للطلاب المحددين (${studentIds.length})', textDirection: TextDirection.rtl, style: const TextStyle(fontWeight: FontWeight.bold, color: primaryNavy)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              textDirection: TextDirection.rtl,
              decoration: const InputDecoration(labelText: 'عنوان الإشعار', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: messageController,
              textDirection: TextDirection.rtl,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'نص الإشعار', border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: accentGold),
            onPressed: () async {
              final title = titleController.text.trim();
              final msg = messageController.text.trim();
              if (msg.isEmpty) {
                _showSnackbar('يرجى كتابة نص الإشعار', isError: true);
                return;
              }
              Navigator.pop(ctx);
              try {
                final inserts = studentIds.map((id) => {
                  'academic_id': id.trim(),
                  'title': title.isEmpty ? 'إشعار من الكلية' : title,
                  'body': msg,
                  'notification_type': 'academic',
                  'route_name': 'notifications',
                  'is_read': false,
                  'created_at': DateTime.now().toIso8601String(),
                }).toList();
                await supabase.from('notifications').insert(inserts);

                // إرسال تنبيه سحابي فوري عبر Firebase لهواتف الطلاب والتطبيق مغلق
                for (final id in studentIds) {
                  FcmSenderService.sendToTopic(
                    topic: 'student_${id.trim()}',
                    title: title.isEmpty ? 'إشعار من الكلية' : title,
                    body: msg,
                    routeName: 'notifications',
                  );
                }

                _showSnackbar('تم إرسال الإشعار بنجاح إلى ${studentIds.length} طالب');
              } catch (e) {
                _showSnackbar('فشل إرسال الإشعار: $e', isError: true);
              }
            },
            icon: const Icon(Icons.send, color: Colors.white, size: 18),
            label: const Text('إرسال', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // 12. نقل الطالب / الطلاب من تخصص إلى تخصص آخر
  void _showTransferSpecialtyDialog(List<String> studentIds, TreeNodeData groupNode) {
    if (!_canTree('tree_students', PermissionAction.update)) {
      _showNoPermissionSnack('⚠️ عذراً، حسابك لا يملك صلاحية نقل الطلاب بين التخصصات.');
      return;
    }
    // جمع التخصصات والدفعات والفصول من الشجرة
    List<String> availableSpecialties = [];
    Map<String, List<String>> specialtyBatches = {};
    Map<String, List<String>> batchSemesters = {};

    void collectNodes(List<TreeNodeData> nodes) {
      for (var n in nodes) {
        if (n.nodeType == 'semester' && !n.title.contains('الدفعة') && !n.title.contains('الفصل')) {
          final specName = n.title.replaceFirst(RegExp(r'^[^:]+:\s*'), '').trim();
          availableSpecialties.add(specName);

          List<String> batches = [];
          for (var b in n.children) {
            final batchName = b.title.replaceFirst(RegExp(r'^[^:]+:\s*'), '').trim();
            batches.add(batchName);

            List<String> semesters = [];
            for (var s in b.children) {
              final semName = s.title.replaceFirst(RegExp(r'^[^:]+:\s*'), '').trim();
              semesters.add(semName);
            }
            if (semesters.isEmpty) {
              semesters = ['الفصل الأول', 'الفصل الثاني'];
            }
            batchSemesters['$specName|$batchName'] = semesters;
          }
          if (batches.isEmpty) {
            batches = ['الدفعة الأولى', 'الدفعة الثانية', 'الدفعة الثالثة'];
          }
          specialtyBatches[specName] = batches;
        }
        collectNodes(n.children);
      }
    }

    collectNodes(treeData);
    availableSpecialties = availableSpecialties.toSet().toList();
    if (availableSpecialties.isEmpty) {
      availableSpecialties = ['تقنية معلومات', 'فني صيدلة', 'علوم مختبرات', 'تمريض عالي', 'قبالة وتوليد'];
    }

    String selectedSpec = availableSpecialties.first;
    List<String> currentBatches = specialtyBatches[selectedSpec] ?? ['الدفعة الأولى', 'الدفعة الثانية', 'الدفعة الثالثة'];
    String selectedBatch = currentBatches.first;

    List<String> currentSemesters = batchSemesters['$selectedSpec|$selectedBatch'] ?? ['الفصل الأول', 'الفصل الثاني'];
    String selectedSemester = currentSemesters.first;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          title: Text(
            studentIds.length == 1 ? 'نقل الطالب إلى تخصص ودفعة أخرى' : 'نقل ${studentIds.length} طالب إلى تخصص ودفعة أخرى',
            textDirection: TextDirection.rtl,
            style: const TextStyle(fontWeight: FontWeight.bold, color: primaryNavy),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('اختر التخصص الجديد المطلوب النقل إليه:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: selectedSpec,
                  decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
                  items: availableSpecialties.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setModalState(() {
                        selectedSpec = val;
                        currentBatches = specialtyBatches[selectedSpec] ?? ['الدفعة الأولى', 'الدفعة الثانية', 'الدفعة الثالثة'];
                        selectedBatch = currentBatches.first;
                        currentSemesters = batchSemesters['$selectedSpec|$selectedBatch'] ?? ['الفصل الأول', 'الفصل الثاني'];
                        selectedSemester = currentSemesters.first;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                const Text('اختر الدفعة الأكاديمية:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: selectedBatch,
                  decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
                  items: currentBatches.map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setModalState(() {
                        selectedBatch = val;
                        currentSemesters = batchSemesters['$selectedSpec|$selectedBatch'] ?? ['الفصل الأول', 'الفصل الثاني'];
                        selectedSemester = currentSemesters.first;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                const Text('اختر الفصل الدراسي:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: selectedSemester,
                  decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
                  items: currentSemesters.map((sem) => DropdownMenuItem(value: sem, child: Text(sem))).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setModalState(() {
                        selectedSemester = val;
                      });
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
              onPressed: () async {
                Navigator.pop(ctx);
                setState(() => isLoadingStudents = true);
                try {
                  final newLevel = _resolveLevelFromSemester(selectedSemester);
                  for (final id in studentIds) {
                    await supabase.from('students').update({
                      'specialty': selectedSpec,
                      'batch': selectedBatch,
                      'semester': selectedSemester,
                      'level': newLevel,
                    }).eq('academic_id', id.trim());
                  }
                  _showSnackbar('تم نقل الطلاب إلى ($selectedSpec - $selectedBatch - $selectedSemester) بنجاح');
                  await _loadStudentsForGroup(groupNode.id);
                  setState(() => selectedStudentIds.clear());
                } catch (e) {
                  _showSnackbar('فشل النقل: $e', isError: true);
                  setState(() => isLoadingStudents = false);
                }
              },
              icon: const Icon(Icons.swap_horiz, color: Colors.white, size: 18),
              label: const Text('تأكيد النقل', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  // 13. عرض وتعديل درجات الطالب
  Future<void> _showStudentGradesDialog(Map<String, dynamic> student) async {
    final academicId = student['academic_id']?.toString() ?? '';
    setState(() => isLoadingStudents = true);

    Map<String, dynamic>? resultRow;
    try {
      final res = await supabase.from('student_results').select().eq('academic_id', academicId).maybeSingle();
      resultRow = res;
    } catch (_) {}
    setState(() => isLoadingStudents = false);

    Map<String, dynamic> subjects = {};
    if (resultRow != null && resultRow['subjects'] is Map) {
      subjects = Map<String, dynamic>.from(resultRow['subjects'] as Map);
      subjects.remove('terms');
    }

    final totalMarksController = TextEditingController(text: resultRow?['total_marks']?.toString() ?? '0');
    final gpaController = TextEditingController(text: resultRow?['gpa']?.toString() ?? '0');
    final gradeController = TextEditingController(text: resultRow?['grade']?.toString() ?? 'ممتاز');

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          title: Text('درجات الطالب: ${student['full_name']} ($academicId)', textDirection: TextDirection.rtl, style: const TextStyle(fontWeight: FontWeight.bold, color: primaryNavy)),
          content: SizedBox(
            width: 450,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: gpaController,
                          decoration: const InputDecoration(labelText: 'المعدل التراكمي (%)', border: OutlineInputBorder()),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: totalMarksController,
                          decoration: const InputDecoration(labelText: 'المجموع الكلي', border: OutlineInputBorder()),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: gradeController,
                    textDirection: TextDirection.rtl,
                    decoration: const InputDecoration(labelText: 'التقدير العام (مثال: ممتاز، جيد جداً)', border: OutlineInputBorder()),
                  ),
                  const Divider(height: 24),
                  const Align(
                    alignment: Alignment.centerRight,
                    child: Text('المواد والدرجات:', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 8),
                  if (subjects.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(12),
                      child: Text('لا توجد مواد مضافة بعد لهذا الطالب', style: TextStyle(color: Colors.grey)),
                    )
                  else
                    ...subjects.entries.map((e) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(e.key, style: const TextStyle(fontWeight: FontWeight.w600)),
                            Text('${e.value}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueAccent)),
                          ],
                        ),
                      );
                    }).toList(),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إغلاق')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: primaryNavy),
              onPressed: () async {
                if (!_canTree('tree_students', PermissionAction.update)) {
                  _showNoPermissionSnack('⚠️ عذراً، حسابك لا يملك صلاحية تعديل درجات الطلاب.');
                  return;
                }
                Navigator.pop(ctx);
                try {
                  await supabase.from('student_results').upsert({
                    'academic_id': academicId,
                    'student_name': student['full_name'],
                    'specialty': student['specialty'],
                    'gpa': double.tryParse(gpaController.text.trim()) ?? 0.0,
                    'total_marks': double.tryParse(totalMarksController.text.trim()) ?? 0.0,
                    'grade': gradeController.text.trim(),
                  });
                  _showSnackbar('تم حفظ درجات الطالب بنجاح');
                } catch (e) {
                  _showSnackbar('فشل حفظ الدرجات: $e', isError: true);
                }
              },
              child: const Text('حفظ التعديلات', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  // 14. حجب أو إظهار النتيجة للطالب
  Future<void> _toggleHideResult(Map<String, dynamic> student) async {
    if (!_canTree('tree_students', PermissionAction.update)) {
      _showNoPermissionSnack('⚠️ عذراً، حسابك لا يملك صلاحية حجب أو إظهار النتائج.');
      return;
    }
    final academicId = student['academic_id']?.toString().trim() ?? '';
    final bool currentHidden = student['is_result_hidden'] ?? false;
    final bool newHidden = !currentHidden;

    try {
      // تحديث في جدول student_results
      try {
        final existing = await supabase.from('student_results').select('subjects').eq('academic_id', academicId).maybeSingle();
        Map<String, dynamic> subs = {};
        if (existing != null && existing['subjects'] is Map) {
          subs = Map<String, dynamic>.from(existing['subjects'] as Map);
        }
        subs['is_result_hidden'] = newHidden;
        await supabase.from('student_results').upsert({
          'academic_id': academicId,
          'subjects': subs,
          'updated_at': DateTime.now().toIso8601String(),
        }, onConflict: 'academic_id');
      } catch (err) {
        debugPrint('Error updating student_results hidden status: $err');
      }

      // تحديث في جدول students إن أمكن
      try {
        await supabase.from('students').update({'is_result_hidden': newHidden}).eq('academic_id', academicId);
      } catch (_) {}

      _showSnackbar(newHidden ? 'تم حجب النتيجة عن الطالب ($academicId)' : 'تم رفع الحجب عن نتيجة الطالب ($academicId)');
      if (selectedNodeId != null) await _loadStudentsForGroup(selectedNodeId!);
    } catch (e) {
      _showSnackbar('فشلت العملية: $e', isError: true);
    }
  }

  // 15. استخراج نشاطات الطالب
  Future<void> _showStudentActivitiesDialog(Map<String, dynamic> student) async {
    final academicId = student['academic_id']?.toString() ?? '';
    final fullName = student['full_name']?.toString() ?? '';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.history, color: primaryNavy),
            const SizedBox(width: 8),
            Text('سجل ونشاطات الطالب: $fullName', style: const TextStyle(fontWeight: FontWeight.bold, color: primaryNavy, fontSize: 16)),
          ],
        ),
        content: SizedBox(
          width: 480,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.badge, color: accentGold),
                title: Text('الرقم الأكاديمي: $academicId'),
                subtitle: Text('التخصص: ${student['specialty']} | الدفعة: ${student['batch'] ?? "1"}'),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.timeline, color: Colors.blue),
                title: Text('الفصل الحالي: ${student['semester'] ?? "غير محدد"}'),
                subtitle: Text('حالة الحساب: ${(student['is_blocked'] ?? false) ? "موقوف" : "نشط"} | النتيجة: ${(student['is_result_hidden'] ?? false) ? "محجوبة" : "متاحة"}'),
              ),
              const Divider(),
              const Text('سجل العمليات الأخيرة:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('• تسجيل دخول ناجح للنظام (${DateTime.now().toString().substring(0, 16)})', style: const TextStyle(fontSize: 12)),
                    const SizedBox(height: 4),
                    Text('• استعلام عن الجدول الفصلي', style: const TextStyle(fontSize: 12)),
                    const SizedBox(height: 4),
                    Text('• آخر تحديث للبيانات بواسطة لوحة الإدارة', style: const TextStyle(fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: primaryNavy),
            onPressed: () => Navigator.pop(ctx),
            icon: const Icon(Icons.check, color: Colors.white, size: 16),
            label: const Text('إغلاق', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // 16. رفع درجات طلاب الفصل من ملف Excel
  Future<void> _uploadGradesFromExcel(TreeNodeData semesterNode) async {
    if (!_canTree('tree_students', PermissionAction.update)) {
      _showNoPermissionSnack('⚠️ عذراً، حسابك لا يملك صلاحية رفع درجات الطلاب.');
      return;
    }
    final ctx = _getHierarchyContext(semesterNode.id);
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
        withData: true,
      );

      if (result == null || result.files.single.bytes == null) return;

      final Uint8List bytes = result.files.single.bytes!;
      final excel = xl.Excel.decodeBytes(bytes);

      List<Map<String, dynamic>> gradesToUpsert = [];

      for (var table in excel.tables.keys) {
        final rows = excel.tables[table]!.rows;
        if (rows.isEmpty) continue;

        // قراءة الرؤوس (المواد)
        final headerRow = rows[0];
        List<String> subjectHeaders = [];
        for (int c = 2; c < headerRow.length; c++) {
          final hVal = headerRow[c]?.value?.toString().trim() ?? '';
          if (hVal.isNotEmpty && !hVal.contains('المعدل') && !hVal.contains('المجموع')) {
            subjectHeaders.add(hVal);
          }
        }

        for (int r = 1; r < rows.length; r++) {
          final row = rows[r];
          if (row.isEmpty || row[0] == null) continue;

          final academicId = row[0]?.value?.toString().trim() ?? '';
          final studentName = (row.length > 1 ? row[1]?.value?.toString().trim() : '') ?? '';
          if (academicId.isEmpty) continue;

          Map<String, double> subjects = {};
          double totalMarks = 0.0;
          for (int c = 0; c < subjectHeaders.length; c++) {
            if (c + 2 < row.length) {
              final valStr = row[c + 2]?.value?.toString().trim() ?? '0';
              final val = double.tryParse(valStr) ?? 0.0;
              subjects[subjectHeaders[c]] = val;
              totalMarks += val;
            }
          }

          double gpa = subjects.isNotEmpty ? (totalMarks / subjects.length) : 0.0;
          String grade = gpa >= 90 ? 'ممتاز' : (gpa >= 80 ? 'جيد جداً' : (gpa >= 70 ? 'جيد' : (gpa >= 50 ? 'مقبول' : 'راسب')));

          gradesToUpsert.add({
            'academic_id': academicId,
            'student_name': studentName,
            'specialty': ctx['specialty']!,
            'subjects': subjects,
            'total_marks': totalMarks,
            'gpa': double.parse(gpa.toStringAsFixed(1)),
            'grade': grade,
          });
        }
      }

      if (gradesToUpsert.isEmpty) {
        _showSnackbar('لم يتم العثور على درجات صالحة في ملف Excel', isError: true);
        return;
      }

      await supabase.from('student_results').upsert(gradesToUpsert);
      _showSnackbar('تم رفع درجات ${gradesToUpsert.length} طالب بنجاح للفصل (${semesterNode.title})');
    } catch (e) {
      debugPrint('Error uploading grades: $e');
      _showSnackbar('حدث خطأ أثناء قراءة ملف الدرجات: $e', isError: true);
    }
  }

  // 17. تصدير جميع بيانات الطلاب في الفصل الدراسي إلى ملف Excel منسق
  Future<void> _exportStudentsToExcel(TreeNodeData semesterNode) async {
    if (studentsList.isEmpty) {
      _showSnackbar('لا يوجد طلاب لتصديرهم في هذا الفصل الدراسي', isError: true);
      return;
    }

    try {
      final ctx = _getHierarchyContext(semesterNode.id);

      // جلب درجات طلاب هذا الفصل إذا كانت متوفرة
      final studentIds = studentsList.map((s) => s['academic_id'].toString()).toList();
      Map<String, Map<String, dynamic>> resultsMap = {};
      try {
        final res = await supabase.from('student_results').select().inFilter('academic_id', studentIds);
        for (var r in (res as List)) {
          resultsMap[r['academic_id'].toString()] = Map<String, dynamic>.from(r as Map);
        }
      } catch (_) {}

      // إنشاء مستند Excel
      final excel = xl.Excel.createExcel();
      final String sheetName = 'بيانات الطلاب';
      excel.rename('Sheet1', sheetName);
      final sheet = excel[sheetName];
      sheet.isRTL = true;

      // ستايل ترويسة الجدول
      final headerStyle = xl.CellStyle(
        backgroundColorHex: xl.ExcelColor.fromHexString('#0E1B4D'),
        fontColorHex: xl.ExcelColor.fromHexString('#FFFFFF'),
        bold: true,
        fontFamily: xl.getFontFamily(xl.FontFamily.Arial),
        horizontalAlign: xl.HorizontalAlign.Center,
        verticalAlign: xl.VerticalAlign.Center,
      );

      // ستايل الخلايا العادية
      final cellStyle = xl.CellStyle(
        horizontalAlign: xl.HorizontalAlign.Center,
        verticalAlign: xl.VerticalAlign.Center,
      );

      // ستايل الخلايا البديلة
      final altCellStyle = xl.CellStyle(
        backgroundColorHex: xl.ExcelColor.fromHexString('#F8F9FA'),
        horizontalAlign: xl.HorizontalAlign.Center,
        verticalAlign: xl.VerticalAlign.Center,
      );

      // عناوين الأعمدة
      final headers = [
        'م',
        'الرقم الأكاديمي',
        'اسم الطالب رباعي',
        'البريد الإلكتروني',
        'كلمة السر',
        'الكلية',
        'الفرع',
        'القسم',
        'التخصص',
        'الدفعة',
        'الفصل الدراسي',
        'العام الدراسي',
        'حالة الحساب',
        'المعدل (%)',
        'المجموع',
        'التقدير',
        'حالة النتيجة',
      ];

      for (int col = 0; col < headers.length; col++) {
        final cell = sheet.cell(xl.CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 0));
        cell.value = xl.TextCellValue(headers[col]);
        cell.cellStyle = headerStyle;
      }

      // إضافة صفوف بيانات الطلاب
      for (int i = 0; i < studentsList.length; i++) {
        final st = studentsList[i];
        final id = st['academic_id']?.toString() ?? '';
        final res = resultsMap[id];
        final isBlocked = st['is_blocked'] ?? false;
        final isHidden = st['is_result_hidden'] ?? false;
        final currentStyle = (i % 2 == 0) ? cellStyle : altCellStyle;

        final rowValues = [
          '${i + 1}',
          id,
          st['full_name']?.toString() ?? '',
          st['email']?.toString() ?? '',
          PasswordSecurity.isHashed(st['password']?.toString()) ? 'مشفرة (محمية)' : (st['password']?.toString() ?? ''),
          ctx['college'] ?? '',
          ctx['branch'] ?? '',
          ctx['department'] ?? '',
          st['specialty']?.toString() ?? ctx['specialty'] ?? '',
          st['batch']?.toString() ?? ctx['batch'] ?? '',
          st['semester']?.toString() ?? ctx['semester'] ?? '',
          st['academic_year']?.toString() ?? ctx['academic_year'] ?? '',
          isBlocked ? 'موقوف' : 'نشط',
          res?['gpa']?.toString() ?? 'غير مرصود',
          res?['total_marks']?.toString() ?? 'غير مرصود',
          res?['grade']?.toString() ?? 'غير مرصود',
          isHidden ? 'محجوبة' : 'ظاهرة',
        ];

        for (int col = 0; col < rowValues.length; col++) {
          final cell = sheet.cell(xl.CellIndex.indexByColumnRow(columnIndex: col, rowIndex: i + 1));
          cell.value = xl.TextCellValue(rowValues[col]);
          cell.cellStyle = currentStyle;
        }
      }

      // توليد الملف وتنزيله
      final fileBytes = excel.save();
      if (fileBytes != null) {
        final safeSemName = semesterNode.title.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
        final fileName = 'طلاب_${safeSemName}.xlsx';

        await saveAndDownloadFile(fileBytes, fileName);
        _showSnackbar('تم تصدير ملف الإكسل بنجاح: $fileName');
      }
    } catch (e) {
      debugPrint('Error exporting Excel: $e');
      _showSnackbar('حدث خطأ أثناء تصدير ملف الإكسل: $e', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ----------------------------------------
          // القسم الأول (اليمين): شجرة الهيكل الأكاديمي
          // ----------------------------------------
          SizedBox(
            width: 320,
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'الهيكل الأكاديمي',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryNavy),
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh, color: primaryNavy),
                        tooltip: 'تحديث الشجرة',
                        onPressed: _loadTreeFromSupabase,
                      ),
                    ],
                  ),
                  const Divider(),
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.vertical,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(minWidth: 280),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: treeData.map((node) => _buildTreeNode(node)).toList(),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _showAddYearDialog,
                      icon: const Icon(Icons.add, color: Colors.white),
                      label: const Text('إضافة كلية / مؤسسة', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(backgroundColor: accentGold, padding: const EdgeInsets.symmetric(vertical: 12)),
                    ),
                  ),
                ],
              ),
            ),
          ),

          Container(width: 1, color: Colors.grey.shade300),

          // ----------------------------------------
          // القسم الثاني (اليسار): قسم المعاينة والإدارة
          // ----------------------------------------
          Expanded(
            child: Container(
              color: const Color(0xFFF8F9FA),
              padding: const EdgeInsets.all(24.0),
              child: _buildPreviewPanel(),
            ),
          ),
        ],
      ),
    );
  }

  // --- واجهة قسم المعاينة والإدارة ---
  Widget _buildPreviewPanel() {
    if (selectedNodeId == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.account_tree_outlined, size: 70, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'الرجاء تحديد عنصر من الشجرة لإدارته، أو ابدأ بإنشاء عام دراسي جديد.',
              style: TextStyle(fontSize: 16, color: Colors.grey, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _showAddYearDialog,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('إضافة عام دراسي جديد', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: accentGold,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              ),
            )
          ],
        ),
      );
    }

    final selectedNode = _findNodeById(treeData, selectedNodeId!);
    if (selectedNode == null) return const SizedBox();

    // 1. إذا كان العنصر المحدد عبارة عن "مجلد" (عام، تخصص، دفعة، فصل)
    if (selectedNode.isFolder) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_isTreeStructureReadOnly)
            _buildTreeReadOnlyBanner('وضع القراءة فقط: حسابك لا يملك صلاحية إضافة أو تعديل أو حذف عناصر الهيكل الأكاديمي.'),
          Container(
            padding: const EdgeInsets.all(20),
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'إعدادات: ${selectedNode.title}',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: primaryNavy),
                ),
                const SizedBox(height: 24),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => _showEditTitleDialog(selectedNode),
                      icon: const Icon(Icons.edit, color: Colors.white, size: 18),
                      label: const Text('تعديل الاسم', style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade700,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      ),
                    ),
                    if (selectedNode.addLabel != null)
                      ElevatedButton.icon(
                        onPressed: () => _showAddChildDialog(selectedNode),
                        icon: const Icon(Icons.add_circle_outline, color: Colors.white, size: 18),
                        label: Text(selectedNode.addLabel!, style: const TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accentGold,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        ),
                      ),
                    OutlinedButton.icon(
                      onPressed: () => _showDeleteNodeDialog(selectedNode),
                      icon: const Icon(Icons.delete_outline, color: Colors.red, size: 18),
                      label: const Text('حذف هذا العنصر', style: TextStyle(color: Colors.red)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // مربع إرسال إشعار عام
          Container(
            padding: const EdgeInsets.all(20),
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.notifications_active, color: accentGold),
                    const SizedBox(width: 8),
                    Text(
                      'إرسال إشعار عام لجميع طلاب (${selectedNode.title})',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: primaryNavy),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _genTitleCtrl,
                  textDirection: TextDirection.rtl,
                  decoration: const InputDecoration(labelText: 'عنوان الإشعار', hintText: 'اكتب عنوان الإشعار...', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _genBodyCtrl,
                  textDirection: TextDirection.rtl,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'محتوى الإشعار', hintText: 'اكتب محتوى الإشعار هنا...', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _isSendingGenNotif ? null : () async {
                    final canNotify = PermissionService.can('notifications', 'send_notifications', PermissionAction.create) ||
                        _canTree('tree_students', PermissionAction.create);
                    if (!canNotify) {
                      _showNoPermissionSnack('⚠️ عذراً، حسابك لا يملك صلاحية إرسال إشعارات للطلاب.');
                      return;
                    }
                    final title = _genTitleCtrl.text.trim();
                    final body = _genBodyCtrl.text.trim();
                    if (body.isEmpty) {
                      _showSnackbar('يرجى كتابة محتوى الإشعار أولاً', isError: true);
                      return;
                    }
                    setState(() => _isSendingGenNotif = true);
                    try {
                      await supabase.from('notifications').insert({
                        'academic_id': null,
                        'title': title.isEmpty ? 'إشعار من الكلية' : '$title (${selectedNode.title})',
                        'body': body,
                        'notification_type': 'academic',
                        'route_name': 'notifications',
                        'is_read': false,
                      });

                      // إرسال تنبيه سحابي فوري لجميع الطلاب عبر Firebase
                      FcmSenderService.sendToTopic(
                        topic: 'all_students',
                        title: title.isEmpty ? 'إشعار من الكلية' : '$title (${selectedNode.title})',
                        body: body,
                        routeName: 'notifications',
                      );

                      _genBodyCtrl.clear();
                      _showSnackbar('تم إرسال ونشر الإشعار العام لجميع الطلاب بنجاح');
                    } catch (e) {
                      _showSnackbar('فشل الإرسال: $e', isError: true);
                    } finally {
                      if (mounted) setState(() => _isSendingGenNotif = false);
                    }
                  },
                  icon: _isSendingGenNotif
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.send, color: Colors.white),
                  label: Text(_isSendingGenNotif ? 'جارِ الإرسال...' : 'إرسال الإشعار', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700),
                )
              ],
            ),
          ),
          const Spacer(),
          const Center(
            child: Text(
              'اختر الغصن النهائي (المجموعة/الفترة) من الشجرة لإدارة طلابها بشكل فردي.',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
          )
        ],
      );
    }

    // 2. إذا كان العنصر المحدد "غصن نهائي" (المجموعة) تظهر إدارة الطلاب
    final filteredStudents = studentsList.where((s) {
      if (studentSearchQuery.isEmpty) return true;
      final q = studentSearchQuery.toLowerCase();
      final id = (s['academic_id'] ?? '').toString().toLowerCase();
      final name = (s['full_name'] ?? '').toString().toLowerCase();
      return id.contains(q) || name.contains(q);
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_isTreeStudentsReadOnly)
          _buildTreeReadOnlyBanner('وضع القراءة فقط: حسابك لا يملك صلاحية إضافة أو تعديل أو ترقية بيانات الطلاب في هذا الفرع.'),
        Text(
          'إدارة بيانات: ${selectedNode.title}',
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: primaryNavy),
        ),
        const SizedBox(height: 24),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _importStudentsFromExcel(selectedNode),
                  icon: const Icon(Icons.upload_file, color: Colors.white, size: 18),
                  label: const Text('استيراد طلاب (Excel)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _exportStudentsToExcel(selectedNode),
                  icon: const Icon(Icons.download, color: Colors.white, size: 18),
                  label: const Text('تصدير كشف الطلاب (Excel)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueGrey.shade800,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _showAddStudentManualDialog(selectedNode),
                  icon: const Icon(Icons.person_add, color: Colors.white, size: 18),
                  label: const Text('إضافة طالب يدوياً', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryNavy,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _showPromoteSemesterDialog(selectedNode),
                  icon: const Icon(Icons.upgrade, color: Colors.white, size: 18),
                  label: const Text('ترقية طلاب الفصل', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade700,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _showPromoteAllSemestersDialog(selectedNode),
                  icon: const Icon(Icons.published_with_changes, color: Colors.white, size: 18),
                  label: const Text('ترقية كل الفصول', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange.shade800,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _uploadGradesFromExcel(selectedNode),
                  icon: const Icon(Icons.grade, color: Colors.white, size: 18),
                  label: const Text('رفع درجات الطلاب (Excel)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal.shade700,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _showEditTitleDialog(selectedNode),
                  icon: const Icon(Icons.edit, color: Colors.black54, size: 16),
                  label: const Text('تعديل الاسم', style: TextStyle(color: Colors.black87, fontSize: 13)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () => _showDeleteNodeDialog(selectedNode),
                  icon: const Icon(Icons.delete_outline, color: Colors.red, size: 16),
                  label: const Text('حذف', style: TextStyle(color: Colors.red, fontSize: 13)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
              ],
            ),
          ],
        ),
        if (selectedStudentIds.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: primaryNavy.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: primaryNavy.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Text('تم تحديد ${selectedStudentIds.length} طالب', style: const TextStyle(fontWeight: FontWeight.bold, color: primaryNavy)),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => _showSendNotificationDialog(selectedStudentIds.toList(), 'الطلاب المحددين'),
                  icon: const Icon(Icons.notifications_active, size: 18, color: accentGold),
                  label: const Text('إرسال إشعار للمحددين', style: TextStyle(color: primaryNavy, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () => _showTransferSpecialtyDialog(selectedStudentIds.toList(), selectedNode),
                  icon: const Icon(Icons.swap_horiz, size: 18, color: Colors.indigo),
                  label: const Text('نقل لتخصص آخر', style: TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () async {
                    if (!_canTree('tree_students', PermissionAction.update)) {
                      _showNoPermissionSnack('⚠️ عذراً، حسابك لا يملك صلاحية إيقاف حسابات الطلاب.');
                      return;
                    }
                    setState(() => isLoadingStudents = true);
                    try {
                      for (final id in selectedStudentIds) {
                        await supabase.from('students').update({'is_blocked': true}).eq('academic_id', id.trim());
                      }
                      _showSnackbar('تم إيقاف حسابات الطلاب المحددين بنجاح');
                      await _loadStudentsForGroup(selectedNode.id);
                    } catch (e) {
                      _showSnackbar('فشلت العملية: $e', isError: true);
                      setState(() => isLoadingStudents = false);
                    }
                  },
                  icon: const Icon(Icons.block, size: 18, color: Colors.red),
                  label: const Text('إيقاف المحددين', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () async {
                    if (!_canTree('tree_students', PermissionAction.update)) {
                      _showNoPermissionSnack('⚠️ عذراً، حسابك لا يملك صلاحية تنشيط حسابات الطلاب.');
                      return;
                    }
                    setState(() => isLoadingStudents = true);
                    try {
                      for (final id in selectedStudentIds) {
                        await supabase.from('students').update({'is_blocked': false}).eq('academic_id', id.trim());
                      }
                      _showSnackbar('تم تنشيط حسابات الطلاب المحددين بنجاح');
                      await _loadStudentsForGroup(selectedNode.id);
                    } catch (e) {
                      _showSnackbar('فشلت العملية: $e', isError: true);
                      setState(() => isLoadingStudents = false);
                    }
                  },
                  icon: const Icon(Icons.check_circle_outline, size: 18, color: Colors.green),
                  label: const Text('تنشيط المحددين', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.grey),
                  tooltip: 'إلغاء التحديد',
                  onPressed: () => setState(() => selectedStudentIds.clear()),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 16),
        TextField(
          onChanged: (val) => setState(() => studentSearchQuery = val),
          decoration: InputDecoration(
            hintText: 'البحث السريع عن طالب (بالاسم أو الرقم الأكاديمي)...',
            prefixIcon: const Icon(Icons.search, color: primaryNavy),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8)],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: isLoadingStudents
                  ? const Center(child: CircularProgressIndicator())
                  : filteredStudents.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.people_outline, size: 60, color: Colors.grey),
                              const SizedBox(height: 12),
                              Text(
                                studentsList.isEmpty ? 'لا يوجد طلاب مضافين في هذه المجموعة حتى الآن' : 'لا توجد نتائج بحث مطابقة',
                                style: const TextStyle(color: Colors.grey, fontSize: 16),
                              ),
                            ],
                          ),
                        )
                      : DesktopTableScrollView(
                          child: DataTable(
                            columnSpacing: 24,
                                    horizontalMargin: 16,
                                    columns: [
                                      DataColumn(
                                        label: Checkbox(
                                          value: filteredStudents.isNotEmpty && selectedStudentIds.length == filteredStudents.length,
                                          tristate: selectedStudentIds.isNotEmpty && selectedStudentIds.length < filteredStudents.length,
                                          onChanged: (val) {
                                            setState(() {
                                              if (val == true) {
                                                selectedStudentIds = filteredStudents.map((s) => s['academic_id'].toString()).toSet();
                                              } else {
                                                selectedStudentIds.clear();
                                              }
                                            });
                                          },
                                        ),
                                      ),
                                      const DataColumn(label: Text('الرقم الأكاديمي', style: TextStyle(fontWeight: FontWeight.bold))),
                                      const DataColumn(label: Text('اسم الطالب', style: TextStyle(fontWeight: FontWeight.bold))),
                                      const DataColumn(label: Text('البريد الإلكتروني', style: TextStyle(fontWeight: FontWeight.bold))),
                                      const DataColumn(label: Text('حالة الحساب', style: TextStyle(fontWeight: FontWeight.bold))),
                                      const DataColumn(label: Text('النتيجة', style: TextStyle(fontWeight: FontWeight.bold))),
                                      const DataColumn(label: Text('الإجراءات', style: TextStyle(fontWeight: FontWeight.bold))),
                                    ],
                                    rows: filteredStudents.map((st) {
                                      final id = st['academic_id']?.toString() ?? '';
                                      final bool isBlocked = st['is_blocked'] ?? false;
                                      final bool isHidden = st['is_result_hidden'] ?? false;
                                      final bool isSelected = selectedStudentIds.contains(id);

                                      void showStudentContextMenu(Offset globalPosition) {
                                        showMenu<String>(
                                          context: context,
                                          position: RelativeRect.fromLTRB(
                                            globalPosition.dx,
                                            globalPosition.dy,
                                            globalPosition.dx + 1,
                                            globalPosition.dy + 1,
                                          ),
                                          items: [
                                            PopupMenuItem(
                                              value: 'edit',
                                              child: Row(
                                                children: const [
                                                  Icon(Icons.edit, color: Colors.blue, size: 18),
                                                  SizedBox(width: 8),
                                                  Text('تعديل كل بيانات الطالب (مع الـ ID)'),
                                                ],
                                              ),
                                            ),
                                            PopupMenuItem(
                                              value: 'notify',
                                              child: Row(
                                                children: const [
                                                  Icon(Icons.notifications_active, color: accentGold, size: 18),
                                                  SizedBox(width: 8),
                                                  Text('إرسال إشعار للطالب'),
                                                ],
                                              ),
                                            ),
                                            PopupMenuItem(
                                              value: 'block',
                                              child: Row(
                                                children: [
                                                  Icon(isBlocked ? Icons.check_circle : Icons.block, color: isBlocked ? Colors.green : Colors.red, size: 18),
                                                  const SizedBox(width: 8),
                                                  Text(isBlocked ? 'تنشيط حساب الطالب' : 'إيقاف حساب الطالب'),
                                                ],
                                              ),
                                            ),
                                            PopupMenuItem(
                                              value: 'activities',
                                              child: Row(
                                                children: const [
                                                  Icon(Icons.history, color: Colors.purple, size: 18),
                                                  SizedBox(width: 8),
                                                  Text('استخراج جميع نشاطات الطالب'),
                                                ],
                                              ),
                                            ),
                                            PopupMenuItem(
                                              value: 'transfer',
                                              child: Row(
                                                children: const [
                                                  Icon(Icons.swap_horiz, color: Colors.indigo, size: 18),
                                                  SizedBox(width: 8),
                                                  Text('نقل الطالب من تخصص إلى تخصص'),
                                                ],
                                              ),
                                            ),
                                            PopupMenuItem(
                                              value: 'grades',
                                              child: Row(
                                                children: const [
                                                  Icon(Icons.grade, color: Colors.teal, size: 18),
                                                  SizedBox(width: 8),
                                                  Text('درجات الطالب والشهادة'),
                                                ],
                                              ),
                                            ),
                                            PopupMenuItem(
                                              value: 'promote',
                                              child: Row(
                                                children: const [
                                                  Icon(Icons.upgrade, color: Colors.blueAccent, size: 18),
                                                  SizedBox(width: 8),
                                                  Text('ترقية الطالب إلى فصل دراسي'),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ).then((action) {
                                          if (action == null) return;
                                          switch (action) {
                                            case 'edit':
                                              _showEditStudentDialog(st, selectedNode);
                                              break;
                                            case 'notify':
                                              _showSendNotificationDialog([id], st['full_name'] ?? '');
                                              break;
                                            case 'block':
                                              _toggleBlockStudent(st, selectedNode);
                                              break;
                                            case 'activities':
                                              _showStudentActivitiesDialog(st);
                                              break;
                                            case 'transfer':
                                              _showTransferSpecialtyDialog([id], selectedNode);
                                              break;
                                            case 'grades':
                                              _showStudentGradesDialog(st);
                                              break;
                                            case 'promote':
                                              _showPromoteSingleStudentDialog(st, selectedNode);
                                              break;
                                          }
                                        });
                                      }

                                      return DataRow(
                                        selected: isSelected,
                                        onSelectChanged: (val) {
                                          setState(() {
                                            if (val == true) {
                                              selectedStudentIds.add(id);
                                            } else {
                                              selectedStudentIds.remove(id);
                                            }
                                          });
                                        },
                                        cells: [
                                          DataCell(
                                            Checkbox(
                                              value: isSelected,
                                              onChanged: (val) {
                                                setState(() {
                                                  if (val == true) {
                                                    selectedStudentIds.add(id);
                                                  } else {
                                                    selectedStudentIds.remove(id);
                                                  }
                                                });
                                              },
                                            ),
                                          ),
                                          DataCell(
                                            GestureDetector(
                                              onSecondaryTapDown: (details) => showStudentContextMenu(details.globalPosition),
                                              child: Text(id, style: const TextStyle(fontWeight: FontWeight.bold)),
                                            ),
                                          ),
                                          DataCell(
                                            GestureDetector(
                                              onSecondaryTapDown: (details) => showStudentContextMenu(details.globalPosition),
                                              child: Text(st['full_name']?.toString() ?? ''),
                                            ),
                                          ),
                                          DataCell(
                                            GestureDetector(
                                              onSecondaryTapDown: (details) => showStudentContextMenu(details.globalPosition),
                                              child: Text(st['email']?.toString() ?? ''),
                                            ),
                                          ),
                                          DataCell(
                                            Text(
                                              isBlocked ? 'موقوف' : 'نشط',
                                              style: TextStyle(
                                                color: isBlocked ? Colors.red : Colors.green,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          DataCell(
                                            Text(
                                              isHidden ? 'محجوبة' : 'ظاهرة',
                                              style: TextStyle(
                                                color: isHidden ? Colors.deepOrange : Colors.blue.shade700,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          DataCell(Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              IconButton(
                                                icon: const Icon(Icons.more_vert, color: primaryNavy, size: 20),
                                                tooltip: 'خيارات التحكم بالطالب (زر أيمن)',
                                                onPressed: () {
                                                  final renderBox = context.findRenderObject() as RenderBox?;
                                                  final offset = renderBox?.localToGlobal(Offset.zero) ?? const Offset(200, 200);
                                                  showStudentContextMenu(offset + const Offset(150, 150));
                                                },
                                              ),
                                            ],
                                          )),
                                        ],
                                      );
                                    }).toList(),
                                  ),
                        ),
            ),
          ),
        ),
      ],
    );
  }

  // --- بناء الشجرة ---
  Widget _buildTreeNode(TreeNodeData node) {
    final bool isSelected = selectedNodeId == node.id;

    return CustomTreeNodeWidget(
      node: node,
      isSelected: isSelected,
      onTap: () {
        setState(() {
          selectedNodeId = node.id;
        });
        if (!node.isFolder) {
          _loadStudentsForGroup(node.id);
        }
        widget.onNodeAction?.call(node.nodeType, node);
      },
      childNodes: node.children.map((child) => _buildTreeNode(child)).toList(),
    );
  }
}

// ----------------------------------------------------
// ويدجت رسم وتصميم الغصن الواحد في الشجرة بشكل مبسط ونظيف
// ----------------------------------------------------
class CustomTreeNodeWidget extends StatefulWidget {
  final TreeNodeData node;
  final bool isSelected;
  final VoidCallback onTap;
  final List<Widget> childNodes;

  const CustomTreeNodeWidget({
    Key? key,
    required this.node,
    required this.isSelected,
    required this.onTap,
    required this.childNodes,
  }) : super(key: key);

  @override
  State<CustomTreeNodeWidget> createState() => _CustomTreeNodeWidgetState();
}

class _CustomTreeNodeWidgetState extends State<CustomTreeNodeWidget> {
  bool isExpanded = true;

  Widget _buildNodeIcon(TreeNodeData node) {
    switch (node.nodeType) {
      case 'year': // كلية الغد الدولية
        return const Icon(Icons.school, color: Color(0xFF0E1B4D), size: 20);
      case 'specialty': // GIC
        return const Icon(Icons.account_balance, color: Colors.blueGrey, size: 20);
      case 'batch': // الأقسام (قسم العلوم الصحية، القسم التقني)
        return const Icon(Icons.domain, color: Colors.pinkAccent, size: 20);
      case 'semester': // التخصصات (فني صيدلة، تقنية معلومات)
        return const Icon(Icons.stars, color: Colors.orange, size: 20);
      case 'group': // الدفعات (الدفعة 1)
        return const Icon(Icons.groups, color: Colors.cyan, size: 20);
      case 'group_shift': // الفصول الدراسية
      default:
        return const Icon(Icons.computer, color: Colors.blueAccent, size: 19);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 3.0),
          child: InkWell(
            onTap: () {
              widget.onTap();
              if (widget.node.isFolder && widget.childNodes.isNotEmpty) {
                setState(() {
                  isExpanded = !isExpanded;
                });
              }
            },
            borderRadius: BorderRadius.circular(6),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: widget.isSelected ? const Color(0xFF0E1B4D).withOpacity(0.08) : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildNodeIcon(widget.node),
                  const SizedBox(width: 8),
                  if (widget.node.isFolder && widget.childNodes.isNotEmpty)
                    Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.black54, width: 1.2),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Center(
                        child: Icon(
                          isExpanded ? Icons.remove : Icons.add,
                          size: 11,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  if (widget.node.isFolder && widget.childNodes.isNotEmpty)
                    const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      widget.node.title,
                      softWrap: false,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: widget.isSelected ? FontWeight.bold : FontWeight.w600,
                        color: widget.isSelected ? const Color(0xFF0E1B4D) : Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (isExpanded && widget.childNodes.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(right: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: widget.childNodes,
            ),
          ),
      ],
    );
  }
}