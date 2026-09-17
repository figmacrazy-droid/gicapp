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
                                        fontSize: 50,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.white,
                                        height: 1.3,
                                        letterSpacing: 0.4,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  const SizedBox(
                                    width: double.infinity,
                                    child: Text(
                                      'التأهيل الطبي والإداري الأفضل',
                                      textAlign: TextAlign.right,
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w400,
                                        color: AppColors.gold,
                                        height: 1.4,
                                        letterSpacing: 0.3,
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
                                  topLeft: Radius.circular(45),
                                  topRight: Radius.circular(45),
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  28,
                                  24,
                                  28,
                                  16,
                                ),
                                child: Column(
                                  mainAxisAlignment:
                                  MainAxisAlignment.spaceEvenly,
                                  children: [
                                    _buildField(
                                      label: 'الرقم الأكاديمي للطالب',
                                      hint: '0000000000',
                                      icon: Icons.person_outline,
                                    ),
                                    _buildField(
                                      label: 'كلمة المرور',
                                      hint: '0000000000',
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
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFF0A2451),
                                          ),
                                        ),
                                        SizedBox(width: 8),
                                        Icon(
                                          Icons.verified_user_outlined,
                                          size: 18,
                                          color: Color(0xFF0A2451),
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
  // زر دخول — نص موسّط + لون تأكيد + اللمعة والزجاج
  // ============================
  Widget _buildGlassButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 70),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.centerRight,
            end: Alignment.centerLeft,
            colors: [
              Color(0xFF0A2451),
              Color(0xFF03102E),
            ],
          ),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: AppColors.gold,
            width: 1.4,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF03102E).withOpacity(0.4),
              blurRadius: 15,
              spreadRadius: 1,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(28),
          child: InkWell(
            borderRadius: BorderRadius.circular(28),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const VerificationScreen(),
                ),
              );
            },
            splashColor: const Color(0xFF03102E).withOpacity(0.85),
            highlightColor: const Color(0xFF03102E).withOpacity(0.45),
            splashFactory: InkRipple.splashFactory,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: SizedBox(
                height: 48, // ← ارتفاع ثابت للزر
                child: Stack(
                  children: [
                    // 1) النص — في المنتصف تماماً
                    const Positioned.fill(
                      child: Center(
                        child: Text(
                          'دخول',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                    ),

                    // 2) انعكاس علوي (زجاج)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(28),
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.white.withOpacity(0.22),
                                Colors.white.withOpacity(0.06),
                                Colors.transparent,
                                Colors.transparent,
                                Colors.black.withOpacity(0.08),
                              ],
                              stops: const [0.0, 0.18, 0.42, 0.85, 1.0],
                            ),
                          ),
                        ),
                      ),
                    ),

                    // 3) حد زجاجي رفيع في الأعلى
                    Positioned(
                      top: 1.5,
                      left: 12,
                      right: 12,
                      child: IgnorePointer(
                        child: Container(
                          height: 1,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.transparent,
                                Colors.white.withOpacity(0.5),
                                Colors.white.withOpacity(0.7),
                                Colors.white.withOpacity(0.5),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    // 4) لمعة ناعمة تتحرك
                    Positioned.fill(
                      child: IgnorePointer(
                        child: AnimatedBuilder(
                          animation: _shimmerController,
                          builder: (context, _) {
                            final double t =
                                _shimmerController.value * 3 - 1;
                            return Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(28),
                                gradient: LinearGradient(
                                  begin: Alignment(t - 0.6, -0.4),
                                  end: Alignment(t + 0.6, 0.4),
                                  colors: [
                                    Colors.transparent,
                                    Colors.white.withOpacity(0.03),
                                    Colors.white.withOpacity(0.10),
                                    Colors.white.withOpacity(0.18),
                                    Colors.white.withOpacity(0.10),
                                    Colors.white.withOpacity(0.03),
                                    Colors.transparent,
                                  ],
                                  stops: const [
                                    0.0,
                                    0.25,
                                    0.40,
                                    0.50,
                                    0.60,
                                    0.75,
                                    1.0,
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
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
            Icon(icon, color: const Color(0xFF0A2451), size: 22),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0A2451),
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        TextField(
          textAlign: TextAlign.right,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF0A2451),
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade400,
              fontWeight: FontWeight.w400,
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 6),
            isDense: true,
            enabledBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFFE0E0E0)),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFFD4A51C), width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}