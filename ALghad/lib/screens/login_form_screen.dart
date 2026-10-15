import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../models/app_models.dart';
import '../services/auth_service.dart';
import '../services/email_otp_service.dart';
import 'verification_screen.dart';

class LoginFormScreen extends StatefulWidget {
  const LoginFormScreen({super.key});

  @override
  State<LoginFormScreen> createState() => _LoginFormScreenState();
}

class _LoginFormScreenState extends State<LoginFormScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;

  final TextEditingController _academicIdController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;

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
    _academicIdController.dispose();
    _passwordController.dispose();
    _emailController.dispose();
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
                                              controller: _academicIdController,
                                              keyboardType: TextInputType.number,
                                            ),
                                            _buildField(
                                              label: 'كلمة المرور',
                                              hint: '00000000000',
                                              icon: Icons.lock_outline,
                                              controller: _passwordController,
                                              obscureText: true,
                                            ),
                                            _buildField(
                                              label: 'البريد الإلكتروني',
                                              hint: 'name@example.com',
                                              icon: Icons.email_outlined,
                                              controller: _emailController,
                                              keyboardType: TextInputType.emailAddress,
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
  // دالة تسجيل الدخول والتحقق
  // ============================
  void _handleLogin() async {
    final academicId = _academicIdController.text.trim();
    final password = _passwordController.text.trim();
    final email = _emailController.text.trim();

    if (academicId.isEmpty || password.isEmpty || email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى ملء جميع الحقول للمتابعة'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final student = await AuthService.verifyCredentials(
      academicId: academicId,
      password: password,
      email: email,
    );

    if (student == null) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('بيانات الدخول غير صحيحة، يرجى التأكد وإعادة المحاولة'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    if (student.isPermanentlyBlocked) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('عذراً، تم إيقاف حسابك الأكاديمي من قبل إدارة الكلية. يرجى مراجعة شؤون الطلاب.'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 4),
          ),
        );
      }
      return;
    }

    // توليد رمز تحقق عشوائي من 4 أرقام
    final otpCode = EmailOtpService.generateOtp();

    // إرسال الرمز عبر Resend إلى بريد الطالب
    await EmailOtpService.sendOtpEmail(
      targetEmail: student.email,
      otpCode: otpCode,
      studentName: student.fullName,
    );

    if (mounted) {
      setState(() => _isLoading = false);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => VerificationScreen(
            student: student,
            expectedOtp: otpCode,
          ),
        ),
      );
    }
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
          onTap: _isLoading ? null : _handleLogin,
          splashColor: const Color(0xFF091527).withOpacity(0.85),
          highlightColor: const Color(0xFF091527).withOpacity(0.45),
          splashFactory: InkRipple.splashFactory,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(25),
            child: Center(
              child: _isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : const Text(
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
    TextEditingController? controller,
    bool obscureText = false,
    TextInputType? keyboardType,
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
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
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