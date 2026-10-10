import 'package:flutter/material.dart';

class ServicesView extends StatefulWidget {
  final Function(String path) onServiceTap;

  const ServicesView({
    Key? key,
    required this.onServiceTap,
  }) : super(key: key);

  @override
  State<ServicesView> createState() => _ServicesViewState();
}

class _ServicesViewState extends State<ServicesView> {
  static const Color primaryNavy = Color(0xFF0E1B4D);
  static const Color accentGold = Color(0xFFC5A059);
  static const Color dropDownBg = Color(0xFFDCDCDC);

  String? openServiceTitle;
  String currentPath = 'الخدمات';
  String? selectedSubService;

  final List<Map<String, dynamic>> servicesData = [
    {
      'title': 'القبول والتسجيل',
      'icon': Icons.how_to_reg_outlined,
      'items': [
        'متطلبات القبول والتسجيل',
        'التسجيل في مقر الكلية',
        'التسجيل أونلاين',
        'التسجيل عبر البوابة الإلكترونية لوزارة التربية',
      ],
    },
    {
      'title': 'الأكاديمية',
      'icon': Icons.co_present_outlined,
      'items': [
        'التخصصات الأكاديمية',
        'الكادر الأكاديمي والتدريس',
        'التدريب الميداني',
      ],
    },
    {
      'title': 'شؤون الطلاب',
      'icon': Icons.groups_outlined,
      'items': [
        'الجداول الدراسية',
        'الأنشطة والفعاليات',
        'تقديم طلب تحويل من تخصص إلى تخصص آخر',
        'تقديم طلب وقف قيد',
        'تقديم طلب فتح قيد',
        'تقديم طلب مقاصصة',
        'تقديم طلب تجميد ملف',
        'تقديم طلب سحب ملف',
      ],
    },
    {
      'title': 'شؤون الخريجين',
      'icon': Icons.school_outlined,
      'items': [
        'تقديم طلب استخراج إفادة تخرج',
        'تقديم طلب استخراج شهادة (دبلوم/بكالوريوس)',
        'تقديم طلب استخراج الوثائق اللازمة للتقديم على مزاولة المهنة',
      ],
    },
    {
      'title': 'الكنترول',
      'icon': Icons.fact_check_outlined,
      'items': [
        'جداول الامتحانات النصفية',
        'جداول الامتحانات النهائية',
        'أرقام الجلوس',
        'أوائل الطلاب',
        'النتائج',
        'تقديم طلب تظلم',
      ],
    },
    {
      'title': 'المالية',
      'icon': Icons.attach_money,
      'items': [
        'الإشعارات المالية وكشوفات الحساب',
      ],
    },
    {
      'title': 'الإعلانات والإنجازات',
      'icon': Icons.workspace_premium_outlined,
      'items': [
        'البنرات الإعلانية',
        'سجل الإنجازات',
        'التقويم الأكاديمي',
      ],
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Column(
        children: [
          // شريط القوائم العلوية (Horizontal Menu)
          Container(
            constraints: const BoxConstraints(maxHeight: 280),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: servicesData.map((service) {
                    final bool isOpen = openServiceTitle == service['title'];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          InkWell(
                            onTap: () {
                              setState(() {
                                if (openServiceTitle == service['title']) {
                                  openServiceTitle = null;
                                } else {
                                  openServiceTitle = service['title'];
                                  currentPath = 'الخدمات > ${service['title']}';
                                }
                              });
                            },
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: primaryNavy,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(service['icon'], color: Colors.white, size: 18),
                                  const SizedBox(width: 8),
                                  Text(
                                    service['title'],
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13.5),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(isOpen ? Icons.arrow_drop_up : Icons.arrow_drop_down, color: Colors.white70, size: 20),
                                ],
                              ),
                            ),
                          ),
                          if (isOpen) ...[
                            const SizedBox(height: 10),
                            Container(
                              width: 210,
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: dropDownBg,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.black12, width: 1),
                              ),
                              child: Column(
                                children: (service['items'] as List<String>).map((subItem) {
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                                    child: Material(
                                      color: selectedSubService == subItem ? accentGold.withOpacity(0.2) : Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      elevation: selectedSubService == subItem ? 0 : 1,
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(16),
                                        onTap: () {
                                          final fullPath = 'الخدمات > ${service['title']} > $subItem';
                                          setState(() {
                                            currentPath = fullPath;
                                            selectedSubService = subItem;
                                          });
                                          widget.onServiceTap(fullPath);
                                        },
                                        child: Container(
                                          width: double.infinity,
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                          child: Text(
                                            subItem,
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontSize: 11.5,
                                              fontWeight: FontWeight.bold,
                                              color: selectedSubService == subItem ? primaryNavy : Colors.black87,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
          
          // منطقة محرر الخدمة (Editor Panel)
          Expanded(
            child: Container(
              width: double.infinity,
              color: const Color(0xFFF4F6F8),
              child: _buildEditorPanel(),
            ),
          ),

          // شريط المسار السفلي
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
            color: const Color(0xFFDCDCDC),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.location_on_outlined, size: 18, color: primaryNavy),
                const SizedBox(width: 8),
                Text(
                  'المسار: $currentPath',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: primaryNavy),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditorPanel() {
    if (selectedSubService == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.dashboard_customize_outlined, size: 80, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'الرجاء اختيار خدمة فرعية من الأعلى لإدارتها',
              style: TextStyle(fontSize: 18, color: Colors.grey, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
    }

    // --- تحليل نوع الخدمة لعرض المحرر المناسب ---
    
    // 1. خدمات الاستمارة المباشرة (واتساب)
    if (selectedSubService == 'التسجيل أونلاين') {
      return _buildMessageOnly('هذه الخدمة ترتبط بنموذج التطبيق وترسل بياناتها بصيغة PDF إلى رقم الواتساب المخصص (967776166321). لا تحتاج لرفع محتوى هنا.');
    }

    // 2. خدمات رفع PDF أو صور (الجداول)
    if (selectedSubService!.contains('الجداول الدراسية') || selectedSubService!.contains('جداول الامتحانات')) {
      return _buildPdfUploadEditor();
    }

    // 3. خدمات إدخال جداول إكسل (النتائج، الأوائل)
    if (selectedSubService == 'أوائل الطلاب' || selectedSubService == 'النتائج') {
      return _buildExcelUploadEditor();
    }

    // 4. خدمات الكادر الأكاديمي والتخصصات (صور + بيانات)
    if (selectedSubService == 'الكادر الأكاديمي والتدريس') {
      return _buildStaffEditor();
    }
    if (selectedSubService == 'التخصصات الأكاديمية') {
      return _buildSpecialtyEditor();
    }
    if (selectedSubService == 'أرقام الجلوس') {
      return _buildExcelUploadEditor(title: 'توليد ورفع أرقام الجلوس (Excel)');
    }

    // 5. خدمات البنرات والتقويم
    if (selectedSubService == 'البنرات الإعلانية') {
      return _buildBannerEditor();
    }
    if (selectedSubService == 'التقويم الأكاديمي') {
      return _buildCalendarEditor();
    }
    
    // 6. الخدمة المالية
    if (selectedSubService == 'الإشعارات المالية وكشوفات الحساب') {
      return _buildFinanceEditor();
    }

    // 7. كل الخدمات المتبقية (طلبات، أنشطة، إفادات) تعتمد على (العنوان + الخطوات النصية + رابط اختياري)
    bool hasUrl = selectedSubService == 'التسجيل عبر البوابة الإلكترونية لوزارة التربية';
    return _buildTextInstructionEditor(hasUrl: hasUrl);
  }

  // ==========================================
  // تصميم واجهات المحررات المختلفة
  // ==========================================

  Widget _buildFinanceEditor() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('الإشعارات المالية المطالبات', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: primaryNavy)),
          const Divider(height: 32),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.red.shade200)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('بحث عن طالب لإرسال إشعار مالي / كشف حساب', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: primaryNavy)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Expanded(
                      child: TextField(decoration: InputDecoration(hintText: 'الرقم الأكاديمي للطالب...', border: OutlineInputBorder(), prefixIcon: Icon(Icons.search))),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(onPressed: (){}, style: ElevatedButton.styleFrom(backgroundColor: primaryNavy, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16)), child: const Text('بحث', style: TextStyle(color: Colors.white))),
                  ],
                ),
                const SizedBox(height: 24),
                const Text('رسالة المطالبة أو الإشعار:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const TextField(maxLines: 3, decoration: InputDecoration(hintText: 'مثال: عليك تسديد القسط المتبقي وقدره...', border: OutlineInputBorder())),
                const SizedBox(height: 16),
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: (){}, icon: const Icon(Icons.picture_as_pdf, color: Colors.white), label: const Text('إرفاق كشف حساب (PDF)', style: TextStyle(color: Colors.white)), style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade700),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      onPressed: (){}, icon: const Icon(Icons.send, color: Colors.white), label: const Text('إرسال الإشعار المالي فوراً', style: TextStyle(color: Colors.white)), style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700),
                    ),
                  ],
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildMessageOnly(String msg) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.blue.shade200)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.info_outline, size: 50, color: Colors.blue.shade700),
              const SizedBox(height: 16),
              Text(msg, textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: primaryNavy, fontWeight: FontWeight.bold, height: 1.5)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextInstructionEditor({bool hasUrl = false}) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('إدارة محتوى: $selectedSubService', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: primaryNavy)),
            const Divider(height: 32),
            const TextField(decoration: InputDecoration(labelText: 'العنوان الرئيسي للخدمة', border: OutlineInputBorder())),
            const SizedBox(height: 16),
            const TextField(decoration: InputDecoration(labelText: 'المقدمة أو العنوان الفرعي', border: OutlineInputBorder()), maxLines: 2),
            const SizedBox(height: 16),
            const Text('الخطوات والتعليمات (نص):', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
              child: const TextField(
                decoration: InputDecoration(hintText: 'اكتب الخطوة هنا...', border: InputBorder.none),
                maxLines: 4,
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(onPressed: (){}, icon: const Icon(Icons.add, color: Colors.white), label: const Text('إضافة خطوة أخرى', style: TextStyle(color: Colors.white)), style: ElevatedButton.styleFrom(backgroundColor: accentGold)),
            const SizedBox(height: 16),
            const TextField(decoration: InputDecoration(labelText: 'ملاحظة تحذيرية (تظهر باللون الأحمر أسفل الخطوات)', border: OutlineInputBorder()), maxLines: 2),
            if (hasUrl) ...[
              const SizedBox(height: 16),
              const TextField(decoration: InputDecoration(labelText: 'الرابط الخارجي (مثال: رابط الوزارة)', border: OutlineInputBorder(), prefixIcon: Icon(Icons.link))),
            ],
            const SizedBox(height: 24),
            Align(
              alignment: Alignment.centerLeft,
              child: ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.save, color: Colors.white),
                label: const Text('حفظ ونشر في التطبيق', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700, padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPdfUploadEditor() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('رفع وإدارة: $selectedSubService', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: primaryNavy)),
          const Divider(height: 32),
          
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // الشجرة المصغرة (تحديد المستهدف)
              Expanded(
                flex: 1,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.blue.shade200)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.account_tree, color: primaryNavy),
                          SizedBox(width: 8),
                          Text('1. تحديد المستهدف (الشجرة المصغرة)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: primaryNavy)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(labelText: 'العام الدراسي', border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12)),
                        items: const [DropdownMenuItem(value: '1', child: Text('2023/2024'))],
                        onChanged: (v) {},
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(labelText: 'التخصص', border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12)),
                        items: const [DropdownMenuItem(value: '1', child: Text('أمن سيبراني')), DropdownMenuItem(value: '2', child: Text('مختبرات طبية'))],
                        onChanged: (v) {},
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(labelText: 'الدفعة والفصل', border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12)),
                        items: const [DropdownMenuItem(value: '1', child: Text('الدفعة 2 - الفصل الرابع'))],
                        onChanged: (v) {},
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(labelText: 'المجموعة والفترة (الغصن النهائي)', border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12)),
                        items: const [DropdownMenuItem(value: '1', child: Text('مجموعة A - صباحي')), DropdownMenuItem(value: '2', child: Text('مجموعة B - مسائي'))],
                        onChanged: (v) {},
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 24),
              // مربع رفع الملف
              Expanded(
                flex: 1,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade300)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.picture_as_pdf, color: Colors.red),
                          SizedBox(width: 8),
                          Text('2. رفع الملف وإرساله', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: primaryNavy)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        height: 170,
                        decoration: BoxDecoration(color: Colors.grey.shade50, border: Border.all(color: Colors.grey.shade400, style: BorderStyle.solid), borderRadius: BorderRadius.circular(8)),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.cloud_upload, size: 50, color: Colors.grey.shade400),
                            const SizedBox(height: 8),
                            const Text('اسحب وأفلت ملف الجدول هنا', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 12),
                            ElevatedButton(onPressed: (){}, style: ElevatedButton.styleFrom(backgroundColor: primaryNavy), child: const Text('تصفح الملفات', style: TextStyle(color: Colors.white))),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.send, color: Colors.white),
                          label: const Text('اعتماد وإرسال إشعار للطلاب', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700, padding: const EdgeInsets.symmetric(vertical: 14)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 40),
          
          // قائمة الجداول السابقة
          const Text('الجداول المرفوعة سابقاً (سجل الأرشيف)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryNavy)),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade300)),
            child: DataTable(
              headingRowColor: MaterialStateProperty.all(Colors.grey.shade100),
              columns: const [
                DataColumn(label: Text('اسم الملف', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('المستهدف (من الشجرة)', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('تاريخ الرفع', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('إجراءات', style: TextStyle(fontWeight: FontWeight.bold))),
              ],
              rows: [
                DataRow(cells: [
                  const DataCell(Row(children: [Icon(Icons.picture_as_pdf, color: Colors.red, size: 20), SizedBox(width: 8), Text('جدول_محاضرات_A.pdf')])),
                  const DataCell(Text('أمن سيبراني > دفعة 2 > مجموعة A (صباحي)')),
                  const DataCell(Text('10-10-2026')),
                  DataCell(IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: (){}, tooltip: 'حذف الجدول')),
                ]),
                DataRow(cells: [
                  const DataCell(Row(children: [Icon(Icons.picture_as_pdf, color: Colors.red, size: 20), SizedBox(width: 8), Text('جدول_محاضرات_B.pdf')])),
                  const DataCell(Text('أمن سيبراني > دفعة 2 > مجموعة B (مسائي)')),
                  const DataCell(Text('10-10-2026')),
                  DataCell(IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: (){}, tooltip: 'حذف الجدول')),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExcelUploadEditor({String? title}) {
    return Center(
      child: Container(
        width: 600,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title ?? 'استيراد بيانات: $selectedSubService', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: primaryNavy)),
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              height: 150,
              decoration: BoxDecoration(color: Colors.green.shade50, border: Border.all(color: Colors.green.shade400, style: BorderStyle.solid), borderRadius: BorderRadius.circular(8)),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.table_view, size: 50, color: Colors.green.shade600),
                  const SizedBox(height: 8),
                  const Text('ارفع ملف Excel لتحديث قاعدة البيانات تلقائياً', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  ElevatedButton(onPressed: (){}, style: ElevatedButton.styleFrom(backgroundColor: primaryNavy), child: const Text('اختيار ملف إكسل', style: TextStyle(color: Colors.white))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStaffEditor() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('إضافة كادر أكاديمي جديد', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: primaryNavy)),
            const Divider(height: 32),
            Row(
              children: [
                InkWell(
                  onTap: (){},
                  child: Container(
                    width: 120, height: 120,
                    decoration: BoxDecoration(color: Colors.grey.shade200, shape: BoxShape.circle, border: Border.all(color: Colors.grey.shade400)),
                    child: const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.add_a_photo, color: Colors.grey), SizedBox(height: 4), Text('رفع صورة', style: TextStyle(fontSize: 10, color: Colors.grey))])),
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    children: [
                      const TextField(decoration: InputDecoration(labelText: 'اسم الدكتور / الأستاذ', border: OutlineInputBorder())),
                      const SizedBox(height: 16),
                      const TextField(decoration: InputDecoration(labelText: 'التخصص', border: OutlineInputBorder())),
                      const SizedBox(height: 16),
                      const TextField(decoration: InputDecoration(labelText: 'سنوات الخبرة', border: OutlineInputBorder())),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {}, icon: const Icon(Icons.save, color: Colors.white), label: const Text('حفظ البيانات', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700, padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16)),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSpecialtyEditor() {
    return _buildMessageOnly('واجهة إضافة تخصص (صورة التخصص، اسم التخصص، الدرجة العلمية) مشابهة لواجهة الكادر الأكاديمي.');
  }

  Widget _buildBannerEditor() {
    return _buildMessageOnly('واجهة البنرات الإعلانية: تتيح لك رفع صورة إعلان، تحديد رابطه الخارجي، ترتيب ظهوره، وزر تفعيل/إيقاف.');
  }
  
  Widget _buildCalendarEditor() {
    return _buildMessageOnly('واجهة التقويم الأكاديمي: اختيار تاريخ الحدث، كتابة العنوان، الوصف، وتحديد ما إذا كان سيظهر مميزاً باللون الذهبي.');
  }
}