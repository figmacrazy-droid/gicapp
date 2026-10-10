import 'package:flutter/material.dart';

class TreeNodeData {
  final String id;
  final String title;
  final bool isFolder;
  final String? addLabel;
  final List<TreeNodeData> children;

  TreeNodeData({
    required this.id,
    required this.title,
    this.isFolder = true,
    this.addLabel,
    this.children = const [],
  });
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

  late List<TreeNodeData> treeData;

  @override
  void initState() {
    super.initState();
    treeData = [
      TreeNodeData(
        id: '1',
        title: 'العام الدراسي: 2024/2023',
        isFolder: true,
        addLabel: 'إضافة تخصص جديد لهذا العام',
        children: [
          TreeNodeData(
            id: '1-1',
            title: 'التخصص: أمن سيبراني',
            isFolder: true,
            addLabel: 'إضافة دفعة جديدة للتخصص',
            children: [
              TreeNodeData(
                id: '1-1-1',
                title: 'الدفعة: الدفعة 2',
                isFolder: true,
                addLabel: 'إضافة فصل دراسي للدفعة',
                children: [
                  TreeNodeData(
                    id: '1-1-1-1',
                    title: 'الفصل: الفصل الرابع',
                    isFolder: true,
                    addLabel: 'إضافة مجموعة / دوام',
                    children: [
                      TreeNodeData(
                        id: '1-1-1-1-1',
                        title: 'المجموعة: مجموعة B (مسائي)',
                        isFolder: false,
                      ),
                      TreeNodeData(
                        id: '1-1-1-1-2',
                        title: 'المجموعة: مجموعة A (صباحي)',
                        isFolder: false,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ];
  }

  // دالة للبحث عن العقدة المحددة في الشجرة
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

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ----------------------------------------
          // القسم الأول (اليمين): شجرة الهيكل الأكاديمي
          // ----------------------------------------
          Expanded(
            flex: 1,
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.all(24.0),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: treeData.map((node) => _buildTreeNode(node)).toList(),
                ),
              ),
            ),
          ),
          
          Container(width: 1, color: Colors.grey.shade300),

          // ----------------------------------------
          // القسم الثاني (اليسار): قسم المعاينة والإدارة
          // ----------------------------------------
          Expanded(
            flex: 2,
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
      // شاشة البداية عندما لا يكون هناك أي شيء محدد
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
              onPressed: () {},
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
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.edit, color: Colors.white, size: 18),
                      label: const Text('تعديل الاسم', style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade700,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      ),
                    ),
                    const SizedBox(width: 16),
                    if (selectedNode.addLabel != null)
                      ElevatedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.add_circle_outline, color: Colors.white, size: 18),
                        label: Text(selectedNode.addLabel!, style: const TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accentGold,
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
                const TextField(
                  decoration: InputDecoration(hintText: 'اكتب عنوان الإشعار...', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                const TextField(
                  maxLines: 3,
                  decoration: InputDecoration(hintText: 'اكتب محتوى الإشعار هنا...', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.send, color: Colors.white),
                  label: const Text('إرسال الإشعار', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'إدارة بيانات: ${selectedNode.title}',
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: primaryNavy),
        ),
        const SizedBox(height: 24),
        
        Row(
          children: [
            ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.upload_file, color: Colors.white),
              label: const Text('استيراد طلاب (Excel)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade700,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.person_add, color: Colors.white),
              label: const Text('إضافة طالب يدوياً', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryNavy,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const Spacer(),
            // أضفت زر تعديل اسم المجموعة أو إزالتها في الطرف الآخر
             OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.edit, color: Colors.black54, size: 16),
              label: const Text('تعديل المجموعة', style: TextStyle(color: Colors.black87)),
            ),
          ],
        ),
        const SizedBox(height: 32),

        TextField(
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
        const SizedBox(height: 24),

        Expanded(
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8)],
            ),
            child: SingleChildScrollView(
              child: DataTable(
                headingRowColor: MaterialStateProperty.all(Colors.grey.shade100),
                columns: const [
                  DataColumn(label: Text('الرقم الأكاديمي', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('اسم الطالب', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('حالة الحساب', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('الإجراءات', style: TextStyle(fontWeight: FontWeight.bold))),
                ],
                rows: [
                  DataRow(cells: [
                    const DataCell(Text('20240001')),
                    const DataCell(Text('أحمد محمد عبدالله')),
                    const DataCell(Text('نشط', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold))),
                    DataCell(Row(
                      children: [
                        IconButton(icon: const Icon(Icons.edit, color: Colors.blue, size: 20), onPressed: () {}, tooltip: 'تعديل البيانات'),
                        IconButton(icon: const Icon(Icons.block, color: Colors.red, size: 20), onPressed: () {}, tooltip: 'توقيف الحساب'),
                        IconButton(icon: const Icon(Icons.notifications_active, color: accentGold, size: 20), onPressed: () {}, tooltip: 'إرسال إشعار للهاتف'),
                      ],
                    )),
                  ]),
                  DataRow(cells: [
                    const DataCell(Text('20240002')),
                    const DataCell(Text('فاطمة علي السقاف')),
                    const DataCell(Text('نشط', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold))),
                    DataCell(Row(
                      children: [
                        IconButton(icon: const Icon(Icons.edit, color: Colors.blue, size: 20), onPressed: () {}, tooltip: 'تعديل البيانات'),
                        IconButton(icon: const Icon(Icons.block, color: Colors.red, size: 20), onPressed: () {}, tooltip: 'توقيف الحساب'),
                        IconButton(icon: const Icon(Icons.notifications_active, color: accentGold, size: 20), onPressed: () {}, tooltip: 'إرسال إشعار للهاتف'),
                      ],
                    )),
                  ]),
                ],
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
  // تم التغيير إلى false لكي تكون الشجرة مغلقة (مطوية) عند الفتح الافتراضي
  bool isExpanded = false; 

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
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
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: widget.isSelected ? const Color(0xFF0E1B4D).withOpacity(0.08) : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    widget.node.isFolder ? Icons.folder : Icons.groups,
                    color: const Color(0xFFC5A059),
                    size: 20,
                  ),
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

                  Text(
                    widget.node.title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: widget.isSelected ? FontWeight.bold : FontWeight.normal,
                      color: widget.isSelected ? const Color(0xFF0E1B4D) : Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // عرض الأبناء فقط في حالة كان العنصر مفتوحاً
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