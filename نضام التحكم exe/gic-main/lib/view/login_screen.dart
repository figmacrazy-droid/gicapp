import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gic/services/auth_service.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  static const Color primaryNavy = Color(0xFF0E1B4D);

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
        _errorMessage = 'النظام مغلق مؤقتاً لحمايته. يرجى الانتظار $_remainingLockoutSeconds ثانية';
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
        // توسيع نافذة البرنامج فوراً إلى الحجم الكامل للوحة التحكم
        try {
          const MethodChannel('gic/window').invokeMethod('expand');
        } catch (_) {}

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
      backgroundColor: Colors.white,
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 24.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // الشعار الأصلي للكلية
                  Center(
                    child: SizedBox(
                      height: 85,
                      child: Image.asset(
                        'image/logo.png',
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return const Center(
                            child: Text(
                              'كلية الغد الدولية',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: primaryNavy,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  const Text(
                    'لوحة تحكم النظام الإداري',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: primaryNavy,
                    ),
                  ),
                  const SizedBox(height: 4),

                  const Text(
                    'تسجيل دخول الموظفين والإدارة',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // رسالة الخطأ أو عداد الحظر
                  if (_remainingLockoutSeconds > 0) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.amber.shade400),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.timer_outlined, color: Colors.amber, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'تم قفل الدخول مؤقتاً. يرجى الانتظار $_remainingLockoutSeconds ثانية',
                              style: TextStyle(
                                color: Colors.amber.shade900,
                                fontSize: 12.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                  ] else if (_errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade300),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: TextStyle(
                                color: Colors.red.shade800,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],

                  // حقل اسم المستخدم
                  const Text(
                    'اسم المستخدم',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _usernameController,
                    textAlign: TextAlign.right,
                    textDirection: TextDirection.ltr,
                    onSubmitted: (_) => _handleLogin(),
                    decoration: InputDecoration(
                      hintText: 'أدخل اسم المستخدم',
                      hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
                      filled: true,
                      fillColor: const Color(0xFFEEEEEE),
                      prefixIcon: const Icon(Icons.person_outline, color: primaryNavy, size: 20),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 13,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // حقل كلمة السر
                  const Text(
                    'كلمة السر',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    textAlign: TextAlign.right,
                    textDirection: TextDirection.ltr,
                    onSubmitted: (_) => _handleLogin(),
                    decoration: InputDecoration(
                      hintText: 'أدخل كلمة السر',
                      hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
                      filled: true,
                      fillColor: const Color(0xFFEEEEEE),
                      prefixIcon: const Icon(Icons.lock_outline, color: primaryNavy, size: 20),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_off : Icons.visibility,
                          color: Colors.grey.shade600,
                          size: 19,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 13,
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),

                  // زر تسجيل الدخول الأصلي المعتمد
                  ElevatedButton(
                    onPressed: (_isLoading || _remainingLockoutSeconds > 0) ? null : _handleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryNavy,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      elevation: 2,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.2),
                          )
                        : const Text(
                            'تسجيل الدخول',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15.5,
                              fontWeight: FontWeight.bold,
                            ),
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