import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'home_screen.dart';

class VerificationScreen extends StatefulWidget {
  const VerificationScreen({super.key});

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen>
    with SingleTickerProviderStateMixin {
  final List<TextEditingController> _otpControllers =
  List.generate(4, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(4, (_) => FocusNode());

  // ⏱️ العد التنازلي
  int _secondsRemaining = 60;
  Timer? _timer;

  // ✨ لمعة الزر
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    // ✅ تهيئة الـ controller أولاً
    _shimmerController = AnimationController(
      duration: const Duration(seconds: 5),
      vsync: this,
    )..repeat();
    // ✅ بعدها العد التنازلي
    _startCountdown();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _shimmerController.dispose();
    for (final c in _otpControllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  // ============================
  // بدء العد التنازلي
  // ============================
  void _startCountdown() {
    _timer?.cancel();
    setState(() => _secondsRemaining = 60);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_secondsRemaining <= 1) {
        timer.cancel();
        setState(() => _secondsRemaining = 0);
      } else {
        setState(() => _secondsRemaining--);
      }
    });
  }

  String get _formattedTime {
    final m = (_secondsRemaining ~/ 60).toString().padLeft(2, '0');
    final s = (_secondsRemaining % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  // ============================
  // التحقق من اكتمال الرمز
  // ============================
  void _onOtpChanged() {
    final code = _otpControllers.map((c) => c.text).join();
    if (code.length == 4) {
      _verifyCode(code);
    }
  }

  void _verifyCode(String code) {
    // ✅ الانتقال للشاشة الرئيسية
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const HomeScreen()),
    );
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
                          // الجزء العلوي الكحلي — النصوص في الوسط
                          // ============================
                          Expanded(
                            flex: 40,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 20,
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  const SizedBox(
                                    width: double.infinity,
                                    child: Text(
                                      'التحقق مطلوب',
                                      textAlign: TextAlign.right,
                                      style: TextStyle(
                                        fontSize: 60,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.white,
                                        height: 1.3,
                                        letterSpacing: 0.4,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  const SizedBox(
                                    width: double.infinity,
                                    child: Text(
                                      'لقد أرسلنا رمز التحقق لمرة واحدة (OTP)\nإلى بريدك الإلكتروني يرجى إدخاله\nأدناه لإتمام عملية التحقق.',
                                      textAlign: TextAlign.right,
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.gold,
                                        height: 1.7,
                                        letterSpacing: 0.2,
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
                                  30,
                                  28,
                                  16,
                                ),
                                child: Column(
                                  mainAxisAlignment:
                                  MainAxisAlignment.spaceEvenly,
                                  children: [
                                    const Text(
                                      'Verification Required',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xFF9E9E9E),
                                        letterSpacing: 0.3,
                                      ),
                                    ),

                                    Text(
                                      _formattedTime,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1976D2),
                                        letterSpacing: 1.5,
                                      ),
                                    ),

                                    Row(
                                      mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                      children: List.generate(4, (i) {
                                        return _buildOtpBox(i);
                                      }),
                                    ),

                                    // ✅ زر تأكيد — مع لمعة وزجاج
                                    Center(
                                      child: _buildGlassButton(),
                                    ),

                                    if (_secondsRemaining == 0)
                                      TextButton(
                                        onPressed: _startCountdown,
                                        child: const Text(
                                          'إعادة إرسال الرمز',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: AppColors.gold,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      )
                                    else
                                      Row(
                                        mainAxisAlignment:
                                        MainAxisAlignment.center,
                                        children: const [
                                          Icon(
                                            Icons.screen_lock_landscape,
                                            size: 18,
                                            color: Color(0xFF0A2451),
                                          ),
                                          SizedBox(width: 8),
                                          Text(
                                            'Secured Data, Assured Future',
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFF0A2451),
                                            ),
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
  // زر تأكيد — كحلي + زجاج + لمعة
  // ============================
  Widget _buildGlassButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25),
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
            width: 1.0,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(28),
          child: InkWell(
            borderRadius: BorderRadius.circular(28),
            onTap: () {
              final code = _otpControllers.map((c) => c.text).join();
              if (code.length == 4) {
                _verifyCode(code);
              }
            },
            splashColor: const Color(0xFF03102E).withOpacity(0.85),
            highlightColor: const Color(0xFF03102E).withOpacity(0.45),
            splashFactory: InkRipple.splashFactory,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: SizedBox(
                height: 48,
                child: Stack(
                  children: [
                    const Positioned.fill(
                      child: Center(
                        child: Text(
                          'تأكيد',
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
  // خانة OTP واحدة
  // ============================
  Widget _buildOtpBox(int index) {
    return SizedBox(
      width: 50,
      height: 75,
      child: TextField(
        controller: _otpControllers[index],
        focusNode: _focusNodes[index],
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        maxLength: 1,
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: Color(0xFF0A2451),
        ),
        decoration: InputDecoration(
          counterText: '',
          contentPadding: EdgeInsets.zero,
          filled: true,
          fillColor: Colors.white,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(
              color: Color(0xFF9E9E9E),
              width: 2.0,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(
              color: AppColors.gold,
              width: 2.5,
            ),
          ),
        ),
        onChanged: (value) {
          if (value.isNotEmpty && index < 3) {
            _focusNodes[index + 1].requestFocus();
          } else if (value.isEmpty && index > 0) {
            _focusNodes[index - 1].requestFocus();
          }
          _onOtpChanged();
        },
      ),
    );
  }
}