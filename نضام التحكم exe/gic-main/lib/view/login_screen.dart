import 'dart:async';
import 'package:flutter/material.dart';
import 'package:gic/services/auth_service.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  static const Color primaryNavy = Color(0xFF0E1B4D);
  static const Color darkBg = Color(0xFF080D1A);
  static const Color cardBg = Color(0xFF101C3D);
  static const Color accentGold = Color(0xFFC5A059);
  static const Color accentGoldLight = Color(0xFFDFBF7A);

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;
  Timer? _lockoutTimer;
  int _remainingLockoutSeconds = 0;

  @override
  void initState() {
    super.initState();
    _checkLockoutStatus();
  }

  void _checkLockoutStatus() {
    if (AuthService.isLockedOut) {
      _remainingLockoutSeconds = AuthService.lockoutRemainingSeconds;
      _startLockoutCountdown();
    }
  }

  void _startLockoutCountdown() {
    _lockoutTimer?.cancel();
    _lockoutTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _remainingLockoutSeconds = AuthService.lockoutRemainingSeconds;
        if (_remainingLockoutSeconds <= 0) {
          timer.cancel();
          _errorMessage = null;
        }
      });
    });
  }

  @override
  void dispose() {
    _lockoutTimer?.cancel();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (AuthService.isLockedOut) {
      setState(() {
        _remainingLockoutSeconds = AuthService.lockoutRemainingSeconds;
        _errorMessage = 'النظام مغلق مؤقتاً لحمايته من التخمين. يرجى الانتظار $_remainingLockoutSeconds ثانية';
      });
      _startLockoutCountdown();
      return;
    }

    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = 'يرجى إدخال اسم المستخدم وكلمة السر');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final success = await AuthService.login(username, password);
      if (success && mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const HomeScreen(),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception:', '').trim();
          if (AuthService.isLockedOut) {
            _remainingLockoutSeconds = AuthService.lockoutRemainingSeconds;
            _startLockoutCountdown();
          }
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkBg,
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Stack(
          children: [
            // خلفية فخمة بتدرج لوني كحلي غامق مع لمسات إضاءة ناعمة
            Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.15,
                  colors: [
                    Color(0xFF152654),
                    Color(0xFF0C1633),
                    Color(0xFF070B18),
                  ],
                ),
              ),
            ),

            // دائرة زخرفية خلفية علوية
            Positioned(
              top: -80,
              right: -80,
              child: Container(
                width: 320,
                height: 320,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accentGold.withOpacity(0.04),
                ),
              ),
            ),

            // دائرة زخرفية خلفية سفلية
            Positioned(
              bottom: -100,
              left: -100,
              child: Container(
                width: 360,
                height: 360,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF1E3A8A).withOpacity(0.06),
                ),
              ),
            ),

            // نافذة تسجيل الدخول المنبثقة في المركز
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
                child: Container(
                  width: 450,
                  padding: const EdgeInsets.symmetric(horizontal: 36.0, vertical: 40.0),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(20.0),
                    border: Border.all(
                      color: accentGold.withOpacity(0.35),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.55),
                        blurRadius: 35,
                        spreadRadius: 4,
                        offset: const Offset(0, 12),
                      ),
                      BoxShadow(
                        color: accentGold.withOpacity(0.05),
                        blurRadius: 25,
                        spreadRadius: 1,
                        offset: const Offset(0, 0),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // حاوية الشعار مع إطار ذهبي أنيق
                      Center(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0B142B),
                            shape: BoxShape.circle,
                            border: Border.all(color: accentGold.withOpacity(0.5), width: 1.5),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: SizedBox(
                            width: 75,
                            height: 75,
                            child: Image.asset(
                              'image/logo.png',
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(Icons.school, size: 45, color: accentGold);
                              },
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),

                      // اسم الكلية
                      const Text(
                        'كلية الغد الدولية',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: accentGoldLight,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 6),

                      // عنوان اللوحة
                      const Text(
                        'لوحة تحكم النظام الإداري الموحد',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 4),

                      const Text(
                        'بوابة تسجيل الدخول الآمن للموظفين والإدارة',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white38,
                        ),
                      ),
                      const SizedBox(height: 26),

                      // تنبيه مؤقت الحظر أو الخطأ
                      if (_remainingLockoutSeconds > 0) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade900.withOpacity(0.25),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.amber.shade600),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.timer_outlined, color: Colors.amber, size: 22),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'النظام مقفل مؤقتاً لحمايته. يرجى الانتظار $_remainingLockoutSeconds ثانية',
                                  style: const TextStyle(
                                    color: Colors.amberAccent,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ] else if (_errorMessage != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.red.shade900.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.red.shade400.withOpacity(0.7)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline, color: Color(0xFFFF6B6B), size: 22),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: const TextStyle(
                                    color: Color(0xFFFF8E8E),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // حقل اسم المستخدم
                      const Text(
                        'اسم المستخدم',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _usernameController,
                        textAlign: TextAlign.right,
                        textDirection: TextDirection.ltr,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        onSubmitted: (_) => _handleLogin(),
                        decoration: InputDecoration(
                          hintText: 'أدخل اسم المستخدم',
                          hintStyle: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 13),
                          filled: true,
                          fillColor: const Color(0xFF091229),
                          prefixIcon: const Icon(Icons.person_outline, color: accentGoldLight, size: 20),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.0),
                            borderSide: BorderSide(color: Colors.white.withOpacity(0.12)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.0),
                            borderSide: const BorderSide(color: accentGold, width: 1.5),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                      ),
                      const SizedBox(height: 18),

                      // حقل كلمة السر
                      const Text(
                        'كلمة السر',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        textAlign: TextAlign.right,
                        textDirection: TextDirection.ltr,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        onSubmitted: (_) => _handleLogin(),
                        decoration: InputDecoration(
                          hintText: 'أدخل كلمة السر',
                          hintStyle: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 13),
                          filled: true,
                          fillColor: const Color(0xFF091229),
                          prefixIcon: const Icon(Icons.lock_outline, color: accentGoldLight, size: 20),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility_off : Icons.visibility,
                              color: Colors.white38,
                              size: 20,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.0),
                            borderSide: BorderSide(color: Colors.white.withOpacity(0.12)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.0),
                            borderSide: const BorderSide(color: accentGold, width: 1.5),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                      ),
                      const SizedBox(height: 28),

                      // زر تسجيل الدخول بتصميم ذهبي وكحلي ملكي
                      Container(
                        height: 50,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFFC5A059),
                              Color(0xFF9E7C33),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: accentGold.withOpacity(0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: (_isLoading || _remainingLockoutSeconds > 0) ? null : _handleLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 22,
                                  width: 22,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                                )
                              : const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.login, color: Colors.white, size: 20),
                                    SizedBox(width: 8),
                                    Text(
                                      'تسجيل الدخول للنظام',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // تذييل أمني
                      const Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.shield_outlined, size: 14, color: Colors.white38),
                            SizedBox(width: 6),
                            Text(
                              'نظام مشفر ومحمي - كلية الغد الدولية',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.white38,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}