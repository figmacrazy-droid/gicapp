import 'package:flutter/material.dart';

class AdmissionScreen extends StatelessWidget {
  const AdmissionScreen({super.key});

  static const Color whiteBg = Colors.white;
  static const Color navyDark = Color(0xFF0B1E3D);
  static const Color cardBg = Colors.white;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: whiteBg,
      body: SafeArea(
        bottom: false,
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Column(
            children: [
              _buildAppBar(context),
              const Divider(height: 1, color: Color(0xFFF0F0F0)),
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                  children: [
                    _buildCard(
                      context,
                      title: 'متطلبات القبول التسجيل في الكلية',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                            const AdmissionRequirementsScreen(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 14),
                    _buildCard(
                      context,
                      title: 'التسجيل اونلاين',
                      onTap: () {},
                    ),
                    const SizedBox(height: 14),
                    _buildCard(
                      context,
                      title:
                      'بوابة التنسيق الالكتروني لوزارة التربية والتعليم والبحث العلمي',
                      onTap: () {},
                    ),
                    const SizedBox(height: 14),
                    _buildCard(
                      context,
                      title: 'نظام الإنسحاب',
                      onTap: () {},
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          InkWell(
            onTap: () => Navigator.pop(context),
            borderRadius: BorderRadius.circular(8),
            child: const Padding(
              padding: EdgeInsets.all(4.0),
              child: Icon(
                Icons.arrow_forward_rounded,
                color: navyDark,
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            'نظام القبول والتسجيل والإنسحاب',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w900,
              color: navyDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(
      BuildContext context, {
        required String title,
        required VoidCallback onTap,
      }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
          border: Border.all(
            color: const Color(0xFFF2F2F2),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                textAlign: TextAlign.right,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: navyDark,
                  height: 1.35,
                ),
              ),
            ),
            const SizedBox(width: 14),
            _buildGicBadge(),
          ],
        ),
      ),
    );
  }

  Widget _buildGicBadge() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: navyDark,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: navyDark.withOpacity(0.25),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white.withOpacity(0.8), width: 1.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(7),
            child: Image.asset(
              'assets/images/gic_shield.png',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return const Center(
                  child: Text(
                    'gic',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════
// صفحة متطلبات القبول والتسجيل
// ═══════════════════════════════════════════════
class AdmissionRequirementsScreen extends StatelessWidget {
  const AdmissionRequirementsScreen({super.key});

  static const Color whiteBg = Colors.white;
  static const Color navyDark = Color(0xFF0A2451);
  static const Color textGray = Color(0xFF6B6B6B);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: whiteBg,
      body: SafeArea(
        bottom: false,
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Column(
            children: [
              _buildAppBar(context),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '- يُشترط في المتقدم للإلتحاق بالكلية ما يلي :-',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: navyDark,
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'أن يكون حاصلاً على الثانوية العامة أو ما يعادلها.',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          color: textGray,
                          height: 1.8,
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        '- إرفاق الوثائق المطلوبة :',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: navyDark,
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildRequirementItem(
                        '1- أصل الشهادة وصورة طبق الأصل من الثانوية العامة.',
                      ),
                      _buildRequirementItem(
                        '2- صورة البطاقة الشخصية أو جواز السفر.',
                      ),
                      _buildRequirementItem(
                        '3- صور شخصية حديثة عدد (10) صور مقاس 4×6.',
                      ),
                      _buildRequirementItem(
                        '4- أن يقوم المتقدم ببعثة إستمارة التسجيل.',
                      ),
                      _buildRequirementItem(
                        '5- إرفاق سند رسوم التسجيل.',
                      ),
                      _buildRequirementItem(
                        '6- يحصل الطالب على رقم أكاديمي وبطاقة الكلية تُحدد كل سنة.',
                      ),
                      const SizedBox(height: 32),
                      Center(
                        child: SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: () {},
                            style: ElevatedButton.styleFrom(
                              backgroundColor: navyDark,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(26),
                              ),
                              elevation: 0,
                            ),
                            child: const Text(
                              'إرفاق الوثائق',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRequirementItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text,
        textAlign: TextAlign.right,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w400,
          color: textGray,
          height: 1.7,
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(
              Icons.arrow_forward_rounded,
              color: navyDark,
              size: 24,
            ),
          ),
          const SizedBox(width: 4),
          const Expanded(
            child: Text(
              'متطلبات القبول والتسجيل',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: navyDark,
              ),
            ),
          ),
          const SizedBox(width: 40),
        ],
      ),
    );
  }
}
