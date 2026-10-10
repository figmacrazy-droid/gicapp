import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/auth_service.dart';
import 'verification_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  static const Color navyDark = Color(0xFF0B1E3D);

  final _formKey = GlobalKey<FormState>();
  final _idController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailController = TextEditingController();

  bool _isLoading = false;
  String? _lockoutMessage;
  bool _isPermanentlyBlocked = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 30),
                  Center(
                    child: Image.asset(
                      'assets/images/gic_logo_new.png',
                      height: 100,
                      errorBuilder: (_, __, ___) => const Icon(Icons.school, size: 80, color: navyDark),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Center(
                    child: Text(
                      'تسجيل الدخول - نظام الغد المشرق',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: navyDark),
                    ),
                  ),
                  const SizedBox(height: 30),

                  if (_lockoutMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(14),
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFEBEE),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.red),
                      ),
                      child: Column(
                        children: [
                          Text(
                            _lockoutMessage!,
                            style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 13),
                            textAlign: TextAlign.center,
                          ),
                          if (_isPermanentlyBlocked) ...[
                            const SizedBox(height: 12),
                            ElevatedButton.icon(
                              onPressed: _openWhatsAppSupport,
                              icon: const Icon(Icons.chat, color: Colors.white),
                              label: const Text('التواصل مع فريق الدعم عبر الواتساب', style: TextStyle(color: Colors.white)),
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],

                  // 1. الرقم الأكاديمي ID (10 أرقام)
                  TextFormField(
                    controller: _idController,
                    decoration: _inputDecoration('الرقم الأكاديمي (10 أرقام بالضبط)'),
                    keyboardType: TextInputType.number,
                    validator: AuthService.validateAcademicId,
                  ),
                  const SizedBox(height: 16),

                  // 2. كلمة السر (أحرف فقط)
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: _inputDecoration('كلمة السر (أحرف ونصوص فقط)'),
                    validator: AuthService.validatePassword,
                  ),
                  const SizedBox(height: 16),

                  // 3. البريد الإلكتروني الجامعي
                  TextFormField(
                    controller: _emailController,
                    decoration: _inputDecoration('البريد الإلكتروني الجامعي'),
                    keyboardType: TextInputType.emailAddress,
                    validator: AuthService.validateUniversityEmail,
                  ),
                  const SizedBox(height: 30),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading || _isPermanentlyBlocked ? null : _handleLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: navyDark,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('دخول وإرسال كود التحقق', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
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

  void _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final id = _idController.text.trim();
    final password = _passwordController.text.trim();
    final email = _emailController.text.trim();

    setState(() {
      _isLoading = true;
      _lockoutMessage = null;
    });

    // فحص حالة الحظر الحالية
    final lockout = await AuthService.checkLockoutStatus(id);
    if (lockout['isLocked'] == true) {
      setState(() {
        _isLoading = false;
        _isPermanentlyBlocked = lockout['isPermanent'] ?? false;
        if (_isPermanentlyBlocked) {
          _lockoutMessage = 'تم حظر حسابك لتجاوز المحاولات الخاطئة. يرجى التواصل مع فريق الدعم الفني لفتح الحساب.';
        } else {
          final remaining = lockout['remainingSeconds'] ?? 60;
          _lockoutMessage = 'الحساب محظور مؤقتاً لتكرار المحاولات الخاطئة. المتبقي: $remaining ثانية.';
        }
      });
      return;
    }

    // التحقق من مطابقة البيانات في قاعدة البيانات
    final student = await AuthService.verifyCredentials(
      academicId: id,
      password: password,
      email: email,
    );

    if (student == null) {
      final newLock = await AuthService.registerFailedAttempt(id);
      final int attempts = newLock['attempts'] ?? 1;
      final bool isPerm = newLock['isPermanent'] ?? false;

      setState(() {
        _isLoading = false;
        _isPermanentlyBlocked = isPerm;
        if (isPerm) {
          _lockoutMessage = 'تم حظر حسابك نهائياً بسبب تكرار المحاولات الخاطئة 9 مرات. يرجى التواصل مع فريق الدعم الفني.';
        } else if (attempts == 3) {
          _lockoutMessage = 'تم إدخال بيانات خاطئة 3 مرات. تم حظر الدخول لمدة دقيقة واحدة.';
        } else if (attempts == 6) {
          _lockoutMessage = 'تم إدخال بيانات خاطئة 6 مرات. تم حظر الدخول لمدة ساعة واحدة.';
        } else {
          _lockoutMessage = 'بيانات الدخول غير صحيحة. محاولة خاطئة رقم ($attempts).';
        }
      });
    } else {
      await AuthService.resetLockout(id);
      setState(() => _isLoading = false);

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VerificationScreen(student: student),
          ),
        );
      }
    }
  }

  void _openWhatsAppSupport() async {
    final String url = 'https://wa.me/967776166321?text=${Uri.encodeComponent("مرحبا فريق الدعم، تم حظر حسابي الأكاديمي رقم ${_idController.text} وأحتاج فتح الحساب.")}';
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: const Color(0xFFF8F9FA),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: navyDark, width: 1.5)),
    );
  }
}
