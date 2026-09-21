import 'package:flutter/material.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  // 🎬 مراحل الأنيميشن
  late Animation<double> _logoOpacity;
  late Animation<double> _logoScale;

  late Animation<double> _dotScale;
  late Animation<Offset> _dotPosition;
  late Animation<Color?> _dotColor;

  late Animation<double> _rippleProgress;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );

    // ==========================================
    // المرحلة 1 و 2: ظهور الشعار ثم انكماشه وامتصاصه داخل النقطة الذهبية
    // (من 0.0s إلى 1.4s)
    // ==========================================
    _logoOpacity = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.0),
        weight: 30, // ظهور الشعار حتى 0.7 ثانية
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.0),
        weight: 20, // الثبات حتى 0.9 ثانية
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.0),
        weight: 50, // اختفاء الانكماش والانصهار داخل النقطة حتى 1.4 ثانية
      ),
    ]).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.467, curve: Curves.easeInOut),
      ),
    );

    _logoScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.85, end: 1.0),
        weight: 40, // الحجم الطبيعي حتى 0.9s
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.05),
        weight: 60, // انكماش الشعار وصغره الشديد للبدء بالانضمام داخل النقطة حتى 1.4s
      ),
    ]).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.467, curve: Curves.easeInOutBack),
      ),
    );

    // ==========================================
    // المرحلة 3: ظهور النقطة الذهبية عند انكماش الشعار ثم انطلاقها لأقصى اليمين وتحول لونها للكحلي
    // (من 0.9s إلى 2.2s)
    // ==========================================
    _dotScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.0),
        weight: 30, // ظهور النقطة الذهبية في المكان الذي انكمش فيه الشعار
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.35),
        weight: 45, // تضخم النقطة أثناء الانطلاق لأقصى اليمين
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.35, end: 0.0),
        weight: 25, // ذوبان النقطة وانصهارها في الموجة
      ),
    ]).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.30, 0.933, curve: Curves.easeInOut),
      ),
    );

    _dotPosition = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(135.0, 0.0), // التحرك والانطلاق إلى أقصى اليمين
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.467, 0.733, curve: Curves.easeInOutCubic),
      ),
    );

    _dotColor = ColorTween(
      begin: const Color(0xFFD4A51C), // اللون الذهبي البراق
      end: const Color(0xFF002060), // التحول التدريجي للون الكحلي الملكي الداكن
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.467, 0.70, curve: Curves.easeInOut),
      ),
    );

    // ==========================================
    // المرحلة 4: انطلاق الموجة الكلية للتدرج الكحلي الداكن
    // (من 2.0s إلى 2.9s)
    // ==========================================
    _rippleProgress = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.667, 0.967, curve: Curves.easeInQuart),
      ),
    );

    // عند انتهاء الـ 3 ثواني بالكامل يتم الانتقال فوراً لشاشة تسجيل الدخول
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _navigateToLogin();
      }
    });

    _controller.forward();
  }

  void _navigateToLogin() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const LoginScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 250),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white, // الخلفية بيضاء ناصعة ثابته (#FFFFFF)
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Stack(
            fit: StackFit.expand,
            alignment: Alignment.center,
            children: [
              // 1️⃣ موجة التوسع الكلي للتدرج الكحلي الداكن
              if (_rippleProgress.value > 0)
                CustomPaint(
                  size: size,
                  painter: RippleBackgroundPainter(
                    progress: _rippleProgress.value,
                    centerOffset: _dotPosition.value,
                  ),
                ),

              // 2️⃣ عرض الشعار وتأثير التكبير (Zoom In) والاختفاء
              if (_logoOpacity.value > 0)
                Center(
                  child: Opacity(
                    opacity: _logoOpacity.value,
                    child: Transform.scale(
                      scale: _logoScale.value,
                      child: Image.asset(
                        'assets/images/logo.png',
                        width: 180,
                        height: 180,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          // الاحتياطي في حال عدم تحميل الصورة من المسار الفرعي
                          return Image.asset(
                            'assets/images/gic_shield.png',
                            width: 180,
                            height: 180,
                            fit: BoxFit.contain,
                          );
                        },
                      ),
                    ),
                  ),
                ),

              // 3️⃣ النقطة البرتقالية المتحركة والمتغيرة إلى اللون الكحلي
              if (_dotScale.value > 0)
                Center(
                  child: Transform.translate(
                    offset: _dotPosition.value,
                    child: Transform.scale(
                      scale: _dotScale.value,
                      child: Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          color: _dotColor.value ?? const Color(0xFFD4A51C),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: (_dotColor.value ?? const Color(0xFFD4A51C))
                                  .withOpacity(0.5),
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// 🎨 رسام موجة الدائرة المتسعة التي تحول الخلفية إلى التدرج الخطي الكحلي الداكن
class RippleBackgroundPainter extends CustomPainter {
  final double progress;
  final Offset centerOffset;

  RippleBackgroundPainter({
    required this.progress,
    required this.centerOffset,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;

    final center = Offset(
      size.width / 2 + centerOffset.dx,
      size.height / 2 + centerOffset.dy,
    );

    // اقصى نصف قطر يضمن تغطية الشاشة بالكامل من النقطة المتحركة
    final maxRadius = size.longestSide * 1.5;
    final currentRadius = maxRadius * progress;

    final rect = Rect.fromCircle(center: center, radius: currentRadius);

    final paint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF0A131D), // اللون الأول
          Color(0xFF091527), // اللون الثاني
          Color(0xFF002060), // اللون الثالث
        ],
        stops: [0.0, 0.5, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final path = Path()..addOval(rect);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant RippleBackgroundPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.centerOffset != centerOffset;
  }
}
