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
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.gold,
                        width: 1.5,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(5),
                      child: Container(
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(5),
                          child: Image.asset(
                            'assets/images/gic_shield.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 15),

                  // ============================
                  // مرحباً بك
                  // ============================
                  const Text(
                    'مرحباً بك',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 60,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      height: 1.0,
                      letterSpacing: 0.2,
                    ),
                  ),

                  const SizedBox(height: 4),

                  // ============================
                  // كلية الغد الدولية
                  // ============================
                  const Text(
                    'كلية الغد الدولية',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 32,
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
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(35),
                      border: Border.all(
                        color: AppColors.gold,
                        width: 1.2,
                      ),
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
                            vertical: 16,
                          ),
                          child: Text(
                            'تسجيل الدخول',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 0.2,
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
                      fontSize: 14,
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
