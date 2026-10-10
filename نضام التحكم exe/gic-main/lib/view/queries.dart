import 'package:flutter/material.dart';

class QueriesView extends StatefulWidget {
  final Function(String path)? onPathChanged;

  const QueriesView({Key? key, this.onPathChanged}) : super(key: key);

  @override
  State<QueriesView> createState() => _QueriesViewState();
}

class _QueriesViewState extends State<QueriesView> {
  static const Color primaryNavy = Color(0xFF0E1B4D);
  static const Color accentGold = Color(0xFFC5A059);

  bool isSearching = false;
  bool studentFound = false;
  
  // بيانات افتراضية لمعاينة التصميم
  Map<String, dynamic> studentData = {
    'academic_id': '20240001',
    'full_name': 'أحمد محمد عبدالله',
    'password': 'password123',
    'email': 'ahmed@alghad.edu.ye',
    'academic_year': '2024/2023',
    'specialty': 'أمن سيبراني',
    'batch': 'الدفعة 2',
    'semester': 'الفصل الرابع',
    'group_name': 'مجموعة A',
    'study_shift': 'صباحي',
  };

  void searchStudent() {
    setState(() {
      isSearching = true;
      studentFound = false;
    });
    
    // محاكاة الاتصال بقاعدة البيانات
    Future.delayed(const Duration(seconds: 1), () {
      setState(() {
        isSearching = false;
        studentFound = true; 
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'الاستعلام الشامل عن الطلاب',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: primaryNavy),
                  ),
                  const SizedBox(height: 24),

                  // محرك البحث
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            decoration: InputDecoration(
                              hintText: 'أدخل الرقم الأكاديمي أو اسم الطالب للبحث في قاعدة البيانات...',
                              prefixIcon: const Icon(Icons.search, color: primaryNavy),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton.icon(
                          onPressed: searchStudent,
                          icon: const Icon(Icons.person_search, color: Colors.white),
                          label: const Text('بحث', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: accentGold,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  if (isSearching)
                    const Center(child: CircularProgressIndicator())
                  else if (studentFound)
                    _buildStudentProfile(),

                ],
              ),
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
                const Text(
                  'المسار: الاستعلامات > بحث متقدم',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: primaryNavy),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentProfile() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accentGold.withOpacity(0.5)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.contact_page_outlined, color: primaryNavy, size: 28),
                  SizedBox(width: 8),
                  Text(
                    'سجل بيانات الطالب كاملة',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: primaryNavy),
                  ),
                ],
              ),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.file_download, color: Colors.green),
                    label: const Text('تصدير Excel', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.green),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.save, color: Colors.white),
                    label: const Text('حفظ التعديلات', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryNavy,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const Divider(height: 32),
          
          // عرض الحقول كـ Grid مرن
          Wrap(
            spacing: 16,
            runSpacing: 20,
            children: studentData.keys.map((key) {
              return SizedBox(
                width: 280,
                child: TextFormField(
                  initialValue: studentData[key],
                  decoration: InputDecoration(
                    labelText: _translateKey(key),
                    labelStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                ),
              );
            }).toList(),
          ),
          
          const Divider(height: 40),
          
          // إرسال إشعار مخصص للطالب
          const Text('إرسال إشعار مخصص (مباشر لهاتف الطالب)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryNavy)),
          const SizedBox(height: 16),
          Row(
            children: [
              const Expanded(
                child: TextField(
                  decoration: InputDecoration(hintText: 'اكتب نص الإشعار هنا...', border: OutlineInputBorder()),
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.send, color: Colors.white),
                label: const Text('إرسال', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentGold,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _translateKey(String key) {
    switch (key) {
      case 'academic_id': return 'الرقم الأكاديمي';
      case 'full_name': return 'اسم الطالب';
      case 'password': return 'كلمة السر';
      case 'email': return 'البريد الإلكتروني';
      case 'academic_year': return 'العام الدراسي';
      case 'specialty': return 'التخصص';
      case 'batch': return 'الدفعة';
      case 'semester': return 'الفصل الدراسي';
      case 'group_name': return 'المجموعة';
      case 'study_shift': return 'الفترة الدراسية';
      default: return key;
    }
  }
}
