import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'login_form_screen.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: AppColors.backgroundGradient,
        ),
        child: SafeArea(
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                children: [
                  SizedBox(height: size.height * 0.20),

                  // ============================
                  // الشعار
                  // ============================
                  Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.gold,
                        width: 2,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Container(
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Image.asset(
                            'assets/images/gic_shield.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 25),

                  // ============================
                  // مرحباً بك
                  // ============================
                  const Text(
                    'مرحباً بك',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 54, // تكبير حجم الخط ليكون طويلاً وبارزاً
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      height: 1.0,
                      letterSpacing: 0.2,
                    ),
                  ),

                  const SizedBox(height: 2),

                  // ============================
                  // كلية الغد الدولية
                  // ============================
                  const Text(
                    'كلية الغد الدولية',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 28, // تكبير الخط ليناسب الصورة
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      height: 1.2,
                      letterSpacing: 0.2,
                    ),
                  ),

                  SizedBox(height: size.height * 0.08),

                  // ============================
                  // زر تسجيل الدخول
                  // ============================
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24), // تقليل الهامش ليكون الزر أطول/أعرض
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: AppColors.buttonGradient,
                        borderRadius: BorderRadius.circular(35), // زيادة الدوران ليتناسب مع الطول الجديد
                        border: Border.all(
                          color: AppColors.gold,
                          width: 1.5, // زيادة سمك الإطار الذهبي قليلاً
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.35),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(35),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(35),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                const LoginFormScreen(),
                              ),
                            );
                          },
                          splashColor:
                              const Color(0xFF091527).withOpacity(0.85),
                          highlightColor:
                              const Color(0xFF091527).withOpacity(0.45),
                          splashFactory: InkRipple.splashFactory,
                          child: const Padding(
                            padding: EdgeInsets.symmetric(
                              vertical: 16, // زيادة الارتفاع الداخلي للزر
                            ),
                            child: Text(
                              'تسجيل الدخول',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 24, // تكبير خط الزر
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 22),

                  // ============================
                  // نص الزائر
                  // ============================
                  const Text(
                    'ليس لديك حساب؟ سجل الدخول كزائر',
                    style: TextStyle(
                      fontSize: 14.5,
                      color: AppColors.gold,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
