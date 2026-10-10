import 'package:flutter/material.dart';
import '../services/data_service.dart';

class UniversityGuideScreen extends StatelessWidget {
  const UniversityGuideScreen({super.key});

  static const Color navyDark = Color(0xFF0B1E3D);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: navyDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'دليل الطالب الجامعي',
          style: TextStyle(
            color: navyDark,
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 3)),
                    ],
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.menu_book_rounded, size: 64, color: navyDark),
                      const SizedBox(height: 16),
                      const Text(
                        'دليل الطالب الجامعي الرسمي',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: navyDark),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'الملف المعتمد الشامل لكافة لوائح وأنظمة وشروط وقوانين كلية الغد المشرق للعلوم الطبية والتطبيقية.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 13, color: Colors.grey, height: 1.5),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('جارِ فتح معاينة دليل الطالب الجامعي...')),
                                );
                              },
                              icon: const Icon(Icons.visibility_outlined, color: navyDark),
                              label: const Text('معاينة الدليل', style: TextStyle(color: navyDark)),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('تم تحميل ملف دليل الطالب الجامعي بنجاح')),
                                );
                              },
                              icon: const Icon(Icons.download_rounded, color: Colors.white),
                              label: const Text('تنزيل PDF', style: TextStyle(color: Colors.white)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: navyDark,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
