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
  late Animation<double> _whiteBackgroundOpacity;
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
      duration: const Duration(milliseconds: 2700),
    );

    // ==========================================
    // المرحلة 0: تأخر قليل على الخلفية الشفافة ثم ظهور الخلفية البيضاء تدريجياً
    // (الشفافية من 0.0s إلى 1.0s ثم التلاشي الأبيض من 1.0s إلى 1.5s)
    // ==========================================
    _whiteBackgroundOpacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.370, 0.555, curve: Curves.easeInOut),
      ),
    );

    // ==========================================
    // المرحلة 1 و 2: ظهور الشعار وتكبره على الشفافية ثم صغره تدريجياً ليدخل داخل الدائرة الذهبية
    // (من 0.0s إلى 1.8s)
    // ==========================================
    _logoOpacity = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.0),
        weight: 30, // ظهور الشعار السلس أولاً على الخلفية الشفافة للهاتف
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.0),
        weight: 45, // البقاء والوضوح كاملاً أثناء فترة التأخير وعلى الخلفية البيضاء
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.0),
        weight: 25, // تصاغر سريع للشعار وانصهاره داخل الدائرة الذهبية
      ),
    ]).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.667, curve: Curves.easeInOut),
      ),
    );

    _logoScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.70, end: 1.35),
        weight: 75, // الشعار يظهر ويكبر طوال الفترة الشفافة والبيضاء
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.35, end: 0.08),
        weight: 25, // انكماش وتصاغر سريع ليدخل بالكامل داخل الدائرة الذهبية
      ),
    ]).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.667, curve: Curves.easeInOutCubic),
      ),
    );

    // ==========================================
    // المرحلة 3: حركة وانطلاق الدائرة الكحلية بشكل فائق السرعة نحو أقصى اليمين
    // (حجم مصغر: 37 بكسل - حركة خاطفة وسريعة من 1.65s إلى 2.05s)
    // ==========================================
    _dotScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.0),
        weight: 25, // ظهور الدائرة
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.12),
        weight: 45, // تضخم خفيف ومصغّر جداً أثناء الحركة
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.12, end: 0.0),
        weight: 30, // اندماج وانصهار الدائرة مع التوسع
      ),
    ]).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.555, 0.900, curve: Curves.easeInOut),
      ),
    );

    _dotPosition = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(145.0, 0.0), // انطلاق خاطف وسريع لأقصى اليمين
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.611, 0.759, curve: Curves.easeOutCubic),
      ),
    );

    _dotColor = ColorTween(
      begin: const Color(0xFFD4A51C), // اللون الذهبي البرّاق الفخم
      end: const Color(0xFF002060), // التحول السريع للون الكحلي الداكن
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.611, 0.740, curve: Curves.easeInOut),
      ),
    );

    // ==========================================
    // المرحلة 4: انطلاق وتوسع الخلفية الكحلية السريع جداً
    // (من 1.95s إلى 2.65s)
    // ==========================================
    _rippleProgress = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.722, 0.981, curve: Curves.easeInQuart),
      ),
    );

    // عند انتهاء الـ 2.7 ثانية بالكامل يتم الانتقال فوراً لشاشة تسجيل الدخول
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
      backgroundColor: Colors.transparent, // الخلفية شفافة في البداية عند نُقر التطبيق
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Stack(
            fit: StackFit.expand,
            alignment: Alignment.center,
            children: [
              // 0️⃣ الخلفية البيضاء المتلاشية تدريجياً من الشفافية
              if (_whiteBackgroundOpacity.value > 0)
                Opacity(
                  opacity: _whiteBackgroundOpacity.value,
                  child: Container(
                    color: Colors.white,
                  ),
                ),
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
                        width: 33,
                        height: 33,
                        decoration: BoxDecoration(
                          color: _dotColor.value ?? const Color(0xFFD4A51C),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withOpacity(0.85),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: (_dotColor.value ?? const Color(0xFFD4A51C))
                                  .withOpacity(0.6),
                              blurRadius: 14,
                              spreadRadius: 3,
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
