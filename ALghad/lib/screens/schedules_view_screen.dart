import 'package:flutter/material.dart';
import '../models/app_models.dart';
import '../services/data_service.dart';

class SchedulesViewScreen extends StatelessWidget {
  final String title;
  final String scheduleType; // 'study', 'midterm', 'final'

  const SchedulesViewScreen({
    super.key,
    required this.title,
    required this.scheduleType,
  });

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
        title: Text(
          title,
          style: const TextStyle(
            color: navyDark,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: FutureBuilder<List<ScheduleModel>>(
            future: DataService.getSchedules(scheduleType),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final schedules = snapshot.data ?? [];
              if (schedules.isEmpty) {
                return const Center(child: Text('لا توجد جداول مرفوعة حالياً'));
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: schedules.length,
                itemBuilder: (context, index) {
                  final item = schedules[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEBF3FF),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.picture_as_pdf, color: navyDark, size: 28),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.title,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: navyDark,
                                    ),
                                  ),
                                  if (item.academicYear != null) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      'العام الدراسي: ${item.academicYear}',
                                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        const Divider(height: 1),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            TextButton.icon(
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('جارِ فتح معاينة الملف...')),
                                );
                              },
                              icon: const Icon(Icons.visibility_outlined, size: 18, color: navyDark),
                              label: const Text('معاينة الجدول', style: TextStyle(color: navyDark)),
                            ),
                            ElevatedButton.icon(
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('بدأ تنزيل ملف الجدول على جهازك بنجاح')),
                                );
                              },
                              icon: const Icon(Icons.download_rounded, size: 18, color: Colors.white),
                              label: const Text('تنزيل الملف', style: TextStyle(color: Colors.white, fontSize: 13)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: navyDark,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
