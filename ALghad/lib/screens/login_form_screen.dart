import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'verification_screen.dart';

class LoginFormScreen extends StatefulWidget {
  const LoginFormScreen({super.key});

  @override
  State<LoginFormScreen> createState() => _LoginFormScreenState();
}

class _LoginFormScreenState extends State<LoginFormScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      duration: const Duration(seconds: 5),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: AppColors.backgroundGradient,
        ),
        child: SafeArea(
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: IntrinsicHeight(
                      child: Column(
                        children: [
                                  // ============================
                                  // الجزء العلوي الكحلي — العنوان أعلى اليمين
                                  // ============================
                                  Expanded(
                                    flex: 40,
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 24,
                                        vertical: 20,
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        mainAxisAlignment: MainAxisAlignment.start,
                                        children: [
                                          const SizedBox(
                                            width: double.infinity,
                                            child: Text(
                                              'كلية الغد الدولية',
                                              textAlign: TextAlign.right,
                                              style: TextStyle(
                                                fontSize: 36,
                                                fontWeight: FontWeight.w900,
                                                color: Colors.white,
                                                height: 1.2,
                                                letterSpacing: 0.2,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          const SizedBox(
                                            width: double.infinity,
                                            child: Text(
                                              'التأهيل الطبي والإداري الأفضل',
                                              textAlign: TextAlign.right,
                                              style: TextStyle(
                                                fontSize: 17,
                                                fontWeight: FontWeight.w600,
                                                color: AppColors.gold,
                                                height: 1.3,
                                                letterSpacing: 0.0,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),

                                  // ============================
                                  // الجزء السفلي الأبيض
                                  // ============================
                                  Expanded(
                                    flex: 60,
                                    child: Container(
                                      width: double.infinity,
                                      decoration: const BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.only(
                                          topLeft: Radius.circular(55),
                                          topRight: Radius.circular(55),
                                        ),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.fromLTRB(
                                          28,
                                          32,
                                          28,
                                          16,
                                        ),
                                        child: Column(
                                          mainAxisAlignment:
                                          MainAxisAlignment.spaceEvenly,
                                          children: [
                                            _buildField(
                                              label: 'الرقم الأكاديمي للطالب',
                                              hint: '00000000000',
                                              icon: Icons.person_outline,
                                            ),
                                            _buildField(
                                              label: 'كلمة المرور',
                                              hint: '00000000000',
                                              icon: Icons.lock_outline,
                                            ),
                                            _buildField(
                                              label: 'البريد الإلكتروني',
                                              hint: 'name@example.com',
                                              icon: Icons.email_outlined,
                                            ),
                                            Center(
                                              child: _buildGlassButton(),
                                            ),
                                            Row(
                                              mainAxisAlignment:
                                              MainAxisAlignment.center,
                                              children: const [
                                                Text(
                                                  'بيانات آمنة، مستقبل مضمون',
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w600,
                                                    color: Color(0xFF002060),
                                                  ),
                                                ),
                                                SizedBox(width: 8),
                                                Icon(
                                                  Icons.screen_lock_landscape,
                                                  size: 18,
                                                  color: Color(0xFF002060),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                        ],
                      ),
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

  // ============================
  // زر دخول — بنفس مقاس وحجم زر شاشة تسجيل الدخول (261x45)
  // ============================
  Widget _buildGlassButton() {
    return Container(
      width: 261,
      height: 45,
      decoration: BoxDecoration(
        gradient: AppColors.buttonGradient,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: AppColors.gold,
          width: 1.0,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(25),
        child: InkWell(
          borderRadius: BorderRadius.circular(25),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const VerificationScreen(),
              ),
            );
          },
          splashColor: const Color(0xFF091527).withOpacity(0.85),
          highlightColor: const Color(0xFF091527).withOpacity(0.45),
          splashFactory: InkRipple.splashFactory,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(25),
            child: const Center(
              child: Text(
                'دخول',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 0.0,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ============================
  // ويدجت الحقل
  // ============================
  Widget _buildField({
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Row(
          children: [
            Icon(icon, color: const Color(0xFF002060), size: 22),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF002060),
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        TextField(
          textAlign: TextAlign.right,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF002060),
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
              fontSize: 14,
              color: AppColors.textGrey,
              fontWeight: FontWeight.w400,
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 6),
            isDense: true,
            enabledBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFFE0E0E0)),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.gold, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}