import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/app_models.dart';

class DynamicInstructionScreen extends StatelessWidget {
  final InstructionStepModel info;

  const DynamicInstructionScreen({super.key, required this.info});

  static const Color navyDark = Color(0xFF0B1E3D);
  static const Color accentGold = Color(0xFFD39706);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: navyDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          info.title,
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (info.subtitle != null) ...[
                  Text(
                    info.subtitle!,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: accentGold,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                const Text(
                  'الخطوات والإرشادات المطلوبة:',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: navyDark,
                  ),
                ),
                const SizedBox(height: 12),
                ...info.steps.asMap().entries.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          margin: const EdgeInsets.only(top: 2),
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Color(0xFFF0F4F8),
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '${entry.key + 1}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: navyDark,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            entry.value,
                            style: const TextStyle(
                              fontSize: 14,
                              height: 1.6,
                              color: Color(0xFF2C3E50),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                if (info.note != null) ...[
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF9E6),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFFFE082)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, color: accentGold),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            info.note!,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF5D4037),
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (info.externalUrl != null) ...[
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final Uri uri = Uri.parse(info.externalUrl!);
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri, mode: LaunchMode.externalApplication);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('تعذر فتح الرابط: ${info.externalUrl}')),
                          );
                        }
                      },
                      icon: const Icon(Icons.language, color: Colors.white),
                      label: const Text(
                        'الانتقال إلى البوابة الإلكترونية للوزارة',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: navyDark,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
