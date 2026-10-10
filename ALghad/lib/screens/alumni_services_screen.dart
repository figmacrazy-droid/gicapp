import 'package:flutter/material.dart';
import '../services/data_service.dart';
import 'dynamic_instruction_screen.dart';

class AlumniServicesScreen extends StatelessWidget {
  const AlumniServicesScreen({super.key});

  static const Color navyDark = Color(0xFF0B1E3D);
  static const Color cardBg = Colors.white;

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
        title: const Text(
          'خدمات شؤون الخريجين',
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
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _buildServiceCard(
                context,
                title: 'تقديم طلب استخراج إفادة تخرج',
                onTap: () async {
                  final info = await DataService.getStudentAffairsServiceInfo('تقديم طلب استخراج إفادة تخرج');
                  if (context.mounted) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => DynamicInstructionScreen(info: info)),
                    );
                  }
                },
              ),
              const SizedBox(height: 14),
              _buildServiceCard(
                context,
                title: 'تقديم طلب استخراج شهادة (دبلوم/بكالوريوس)',
                onTap: () async {
                  final info = await DataService.getStudentAffairsServiceInfo('تقديم طلب استخراج شهادة (دبلوم/بكالوريوس)');
                  if (context.mounted) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => DynamicInstructionScreen(info: info)),
                    );
                  }
                },
              ),
              const SizedBox(height: 14),
              _buildServiceCard(
                context,
                title: 'تقديم طلب استخراج الوثائق اللازمة للتقديم على مزاولة المهنة',
                onTap: () async {
                  final info = await DataService.getStudentAffairsServiceInfo('تقديم طلب استخراج الوثائق اللازمة للتقديم على مزاولة المهنة');
                  if (context.mounted) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => DynamicInstructionScreen(info: info)),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildServiceCard(BuildContext context, {required String title, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
          border: Border.all(color: const Color(0xFFF2F2F2)),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 6, offset: const Offset(0, 2)),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset('assets/images/gic_logo_new.png', fit: BoxFit.cover),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: navyDark, height: 1.35),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
