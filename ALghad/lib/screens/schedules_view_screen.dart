import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
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

  void _openSchedule(BuildContext context, ScheduleModel item) async {
    final url = item.fileUrl.trim();
    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ملف الجدول غير متوفر حالياً')),
      );
      return;
    }

    if (url.startsWith('data:image')) {
      try {
        final commaIdx = url.indexOf(',');
        final base64Data = commaIdx != -1 ? url.substring(commaIdx + 1) : url;
        final bytes = base64Decode(base64Data);

        showDialog(
          context: context,
          builder: (ctx) => Dialog(
            insetPadding: const EdgeInsets.all(12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppBar(
                  title: Text(item.title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
                  leading: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                  backgroundColor: navyDark,
                  elevation: 0,
                ),
                Flexible(
                  child: InteractiveViewer(
                    panEnabled: true,
                    minScale: 0.8,
                    maxScale: 4.0,
                    child: Image.memory(bytes),
                  ),
                ),
              ],
            ),
          ),
        );
        return;
      } catch (_) {}
    }

    if (url.startsWith('http://') || url.startsWith('https://')) {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return;
      }
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('جارِ فتح ملف: ${item.title}')),
    );
  }

  void _downloadSchedule(BuildContext context, ScheduleModel item) async {
    final url = item.fileUrl.trim();
    if (url.startsWith('http://') || url.startsWith('https://')) {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return;
      }
    } else if (url.startsWith('data:image')) {
      _openSchedule(context, item);
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('بدأ تنزيل جدول: ${item.title}')),
    );
  }

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
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.calendar_today_outlined, size: 56, color: Colors.grey),
                      SizedBox(height: 14),
                      Text(
                        'لا توجد جداول مرفوعة حالياً',
                        style: TextStyle(color: navyDark, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'سيتم نشر الجداول فور اعتمادها من الكلية والكنترول.',
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: schedules.length,
                itemBuilder: (context, index) {
                  final item = schedules[index];
                  final isPdf = item.isPdf;

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
                                color: isPdf ? const Color(0xFFFFEBEE) : const Color(0xFFEBF3FF),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                isPdf ? Icons.picture_as_pdf : Icons.image,
                                color: isPdf ? Colors.red.shade700 : navyDark,
                                size: 28,
                              ),
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
                                  if (item.academicYear != null && item.academicYear!.isNotEmpty) ...[
                                    const SizedBox(height: 6),
                                    Wrap(
                                      spacing: 6,
                                      runSpacing: 4,
                                      children: () {
                                        final raw = item.academicYear!;
                                        if (raw.contains('|')) {
                                          final parts = raw.split('|').map((s) => s.trim()).toList();
                                          return [
                                            if (parts.isNotEmpty) _buildBadge(Icons.school_outlined, parts[0], Colors.indigo),
                                            if (parts.length > 1) _buildBadge(Icons.groups_outlined, parts[1], Colors.teal.shade800),
                                            if (parts.length > 2) _buildBadge(Icons.calendar_today_outlined, parts[2], Colors.orange.shade900),
                                          ];
                                        }
                                        return [
                                          _buildBadge(Icons.calendar_today_outlined, 'العام: $raw', Colors.grey.shade700),
                                        ];
                                      }(),
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
                              onPressed: () => _openSchedule(context, item),
                              icon: const Icon(Icons.visibility_outlined, size: 18, color: navyDark),
                              label: const Text('معاينة الجدول', style: TextStyle(color: navyDark)),
                            ),
                            ElevatedButton.icon(
                              onPressed: () => _downloadSchedule(context, item),
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

  Widget _buildBadge(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(text, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}
