import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:gic/services/supabase_service.dart';

class AccountsManagementView extends StatefulWidget {
  final Function(String path)? onPathChanged;

  const AccountsManagementView({
    Key? key,
    this.onPathChanged,
  }) : super(key: key);

  @override
  State<AccountsManagementView> createState() => _AccountsManagementViewState();
}

class _AccountsManagementViewState extends State<AccountsManagementView> {
  static const Color primaryNavy = Color(0xFF0E1B4D);
  static const Color accentGold = Color(0xFFC5A059);

  bool isLoading = true;
  int totalStudentsCount = 0;
  List<Map<String, dynamic>> socialLinks = [];
  Map<String, dynamic>? currentGuide;

  final TextEditingController _platformNameController = TextEditingController();
  final TextEditingController _urlController = TextEditingController();

  final TextEditingController _guideTitleController = TextEditingController();
  final TextEditingController _guideUrlController = TextEditingController();

  SupabaseClient get supabase => AdminSupabase.client;

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    setState(() => isLoading = true);
    try {
      // 1. عدد الطلاب
      final studentsRes = await supabase.from('students').select('academic_id');
      totalStudentsCount = (studentsRes as List).length;

      // 2. حسابات التواصل الاجتماعي
      final socialRes = await supabase.from('social_media_links').select().order('display_order');
      socialLinks = List<Map<String, dynamic>>.from(socialRes as List);

      // 3. دليل الطالب
      final guideRes = await supabase.from('university_guides').select().limit(1);
      final list = guideRes as List;
      if (list.isNotEmpty) {
        currentGuide = list.first;
        _guideTitleController.text = currentGuide!['title'] ?? '';
        _guideUrlController.text = currentGuide!['file_url'] ?? '';
      }

      setState(() => isLoading = false);
    } catch (e) {
      debugPrint('Error loading accounts data: $e');
      setState(() => isLoading = false);
    }
  }

  void _showSnackbar(String msg, {bool isError = false}) {
    if (!mounted) return;
    if (isError) {
      debugPrint('[Accounts Error]: $msg');
      String cleanMsg = msg;
      if (cleanMsg.contains('PostgrestException') ||
          cleanMsg.contains('Exception') ||
          cleanMsg.contains('SocketException') ||
          cleanMsg.contains('code:')) {
        if (cleanMsg.contains('duplicate') || cleanMsg.contains('23505')) {
          cleanMsg = 'هذا الحساب أو الرابط مسجل مسبقاً في النظام';
        } else if (cleanMsg.contains('SocketException') || cleanMsg.contains('timed out')) {
          cleanMsg = 'تعذر الاتصال بقاعدة البيانات، يرجى التحقق من اتصال الإنترنت';
        } else {
          final colonIdx = cleanMsg.indexOf(':');
          if (colonIdx > 0 && colonIdx < 40) {
            cleanMsg = cleanMsg.substring(0, colonIdx).trim() + '، يرجى التحقق من البيانات والمحاولة مجدداً';
          } else {
            cleanMsg = 'حدث خطأ أثناء معالجة العملية، يرجى إعادة المحاولة';
          }
        }
      }
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          title: const Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red, size: 28),
              SizedBox(width: 8),
              Text('تنبيه', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          content: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Text(
              cleanMsg,
              textDirection: TextDirection.rtl,
              style: const TextStyle(fontSize: 13, color: Colors.black87),
            ),
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: primaryNavy),
              onPressed: () => Navigator.pop(ctx),
              child: const Text('حسناً', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg, textDirection: TextDirection.rtl),
          backgroundColor: Colors.green.shade700,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  // إضافة أو تعديل رابط تواصل
  void _showSocialLinkDialog({Map<String, dynamic>? item}) {
    _platformNameController.text = item?['platform_name'] ?? '';
    _urlController.text = item?['url'] ?? '';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          item == null ? 'إضافة حساب تواصل جديد' : 'تعديل حساب تواصل',
          textDirection: TextDirection.rtl,
          style: const TextStyle(fontWeight: FontWeight.bold, color: primaryNavy),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _platformNameController,
              textDirection: TextDirection.rtl,
              decoration: const InputDecoration(
                labelText: 'اسم المنصة (مثال: انستقرام، فيسبوك، واتساب)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _urlController,
              textDirection: TextDirection.ltr,
              decoration: const InputDecoration(
                labelText: 'رابط أو يوزر الحساب',
                hintText: 'مثال: @username أو رابط كامل',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: accentGold),
            onPressed: () async {
              final name = _platformNameController.text.trim();
              String url = _urlController.text.trim();
              if (name.isEmpty || url.isEmpty) return;

              // معالجة الرابط واليوزر تلقائياً
              if (!url.startsWith('http://') && !url.startsWith('https://')) {
                String cleanUsername = url.startsWith('@') ? url.substring(1) : url;
                if (!url.contains('.')) {
                  final lowerName = name.toLowerCase();
                  if (lowerName.contains('insta') || name.contains('انستقرام') || name.contains('انستجرام')) {
                    url = 'https://instagram.com/$cleanUsername';
                  } else if (lowerName.contains('face') || name.contains('فيسبوك')) {
                    url = 'https://facebook.com/$cleanUsername';
                  } else if (lowerName.contains('x') || lowerName.contains('twitter') || name.contains('تويتر')) {
                    url = 'https://x.com/$cleanUsername';
                  } else if (lowerName.contains('tele') || name.contains('تيليجرام') || name.contains('تليجرام')) {
                    url = 'https://t.me/$cleanUsername';
                  } else {
                    url = 'https://$url';
                  }
                } else {
                  url = 'https://$url';
                }
              }

              // تحديد الأيقونة المناسبة
              String icon = 'link';
              final lower = name.toLowerCase();
              if (lower.contains('insta') || name.contains('انستقرام') || name.contains('انستجرام')) {
                icon = 'instagram';
              } else if (lower.contains('face') || name.contains('فيسبوك')) {
                icon = 'facebook';
              } else if (lower.contains('x') || lower.contains('twitter') || name.contains('تويتر')) {
                icon = 'twitter';
              } else if (lower.contains('tele') || name.contains('تيليجرام') || name.contains('تليجرام')) {
                icon = 'telegram';
              } else if (lower.contains('whats') || name.contains('واتساب')) {
                icon = 'whatsapp';
              } else if (lower.contains('you') || name.contains('يوتيوب')) {
                icon = 'youtube';
              }

              Navigator.pop(ctx);
              try {
                if (item == null) {
                  await supabase.from('social_media_links').insert({
                    'platform_name': name,
                    'url': url,
                    'icon_name': icon,
                    'display_order': socialLinks.length + 1,
                  });
                  _showSnackbar('تمت إضافة حساب التواصل بنجاح');
                } else {
                  await supabase.from('social_media_links').update({
                    'platform_name': name,
                    'url': url,
                    'icon_name': icon,
                  }).eq('id', item['id']);
                  _showSnackbar('تم تعديل حساب التواصل بنجاح');
                }
                _loadAllData();
              } catch (e) {
                _showSnackbar('فشلت العملية: $e', isError: true);
              }
            },
            child: const Text('حفظ', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // حذف رابط تواصل
  Future<void> _deleteSocialLink(dynamic id) async {
    try {
      await supabase.from('social_media_links').delete().eq('id', id);
      _showSnackbar('تم حذف الرابط بنجاح');
      _loadAllData();
    } catch (e) {
      _showSnackbar('فشل الحذف: $e', isError: true);
    }
  }

  // حفظ دليل الطالب
  Future<void> _saveUniversityGuide() async {
    final title = _guideTitleController.text.trim();
    final url = _guideUrlController.text.trim();
    if (title.isEmpty || url.isEmpty) {
      _showSnackbar('يرجى كتابة عنوان الدليل ورابط الملف', isError: true);
      return;
    }

    try {
      if (currentGuide != null) {
        await supabase.from('university_guides').update({
          'title': title,
          'file_url': url,
        }).eq('id', currentGuide!['id']);
      } else {
        await supabase.from('university_guides').insert({
          'title': title,
          'file_url': url,
        });
      }
      _showSnackbar('تم حفظ ونشر دليل الطالب الجامعي بنجاح في التطبيق!');
      _loadAllData();
    } catch (e) {
      _showSnackbar('فشل الحفظ: $e', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. بطاقات الإحصائيات العلوية
            Row(
              children: [
                _buildStatCard(
                  title: 'إجمالي الطلاب المسجلين',
                  value: '$totalStudentsCount طالب',
                  icon: Icons.people_alt_outlined,
                  color: Colors.blue.shade800,
                ),
                const SizedBox(width: 20),
                _buildStatCard(
                  title: 'حسابات التواصل النشطة',
                  value: '${socialLinks.length} منصات',
                  icon: Icons.share_outlined,
                  color: accentGold,
                ),
                const SizedBox(width: 20),
                _buildStatCard(
                  title: 'دليل الطالب الجامعي',
                  value: currentGuide != null ? 'منشور ونشط' : 'غير منشور',
                  icon: Icons.menu_book_outlined,
                  color: Colors.green.shade700,
                ),
              ],
            ),

            const SizedBox(height: 32),

            // 2. قسم إدارة دليل الطالب الجامعي (PDF)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 3)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.picture_as_pdf_outlined, color: primaryNavy, size: 28),
                      SizedBox(width: 10),
                      Text(
                        'إدارة دليل الطالب الجامعي (ملف PDF)',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryNavy),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'يمكنك هنا رفع أو تحديد الرابط المباشر لملف دليل الطالب بصيغة PDF ليعرض فوراً لكافة الطلاب في تطبيقهم.',
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                  const Divider(height: 28),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: _guideTitleController,
                          textDirection: TextDirection.rtl,
                          decoration: const InputDecoration(
                            labelText: 'عنوان الدليل (مثال: دليل الطالب الجامعي 2025/2024)',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.title),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 3,
                        child: TextField(
                          controller: _guideUrlController,
                          textDirection: TextDirection.ltr,
                          decoration: const InputDecoration(
                            labelText: 'رابط ملف الـ PDF المباشر',
                            hintText: 'https://.../student_guide.pdf',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.link),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton.icon(
                        onPressed: _saveUniversityGuide,
                        icon: const Icon(Icons.cloud_upload_outlined, color: Colors.white),
                        label: const Text('حفظ ونشر الدليل', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryNavy,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // 3. قسم إدارة حسابات التواصل الاجتماعي
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 3)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.public_outlined, color: primaryNavy, size: 28),
                          SizedBox(width: 10),
                          Text(
                            'إدارة حسابات التواصل الاجتماعي للكلية',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryNavy),
                          ),
                        ],
                      ),
                      ElevatedButton.icon(
                        onPressed: () => _showSocialLinkDialog(),
                        icon: const Icon(Icons.add, color: Colors.white),
                        label: const Text('إضافة حساب جديد', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accentGold,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 28),
                  if (socialLinks.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Center(child: Text('لا توجد حسابات تواصل مضافة حالياً', style: TextStyle(color: Colors.grey))),
                    )
                  else
                    Table(
                      columnWidths: const {
                        0: FlexColumnWidth(2),
                        1: FlexColumnWidth(4),
                        2: FlexColumnWidth(1.5),
                      },
                      border: TableBorder(
                        horizontalInside: BorderSide(color: Colors.grey.shade200, width: 1),
                      ),
                      children: [
                        TableRow(
                          decoration: BoxDecoration(color: Colors.grey.shade100),
                          children: const [
                            Padding(padding: EdgeInsets.all(12), child: Text('اسم المنصة', style: TextStyle(fontWeight: FontWeight.bold))),
                            Padding(padding: EdgeInsets.all(12), child: Text('الرابط المباشر', style: TextStyle(fontWeight: FontWeight.bold))),
                            Padding(padding: EdgeInsets.all(12), child: Text('الإجراءات', style: TextStyle(fontWeight: FontWeight.bold))),
                          ],
                        ),
                        ...socialLinks.map((item) {
                          return TableRow(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(12),
                                child: Text(item['platform_name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(12),
                                child: Text(item['url'] ?? '', textDirection: TextDirection.ltr, style: const TextStyle(color: Colors.blue)),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(4),
                                child: Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
                                      onPressed: () => _showSocialLinkDialog(item: item),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                                      onPressed: () => _deleteSocialLink(item['id']),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 3)),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 30),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Text(value, style: TextStyle(color: primaryNavy, fontSize: 20, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
