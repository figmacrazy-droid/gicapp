import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'all_specialties_screen.dart';
import 'notifications_screen.dart';
import 'admission_screen.dart';

class HomeScreen extends StatefulWidget {
  final String userName;
  const HomeScreen({super.key, this.userName = 'مصطفى'});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with TickerProviderStateMixin {
  int _currentSlide = 0;
  int _currentNavIndex = 0;

  Timer? _autoPlayTimer;
  late AnimationController _syncController;
  late PageController _pageController;

  static const double _cardWidth = 222;
  static const double _cardHeight = 278;
  static const double _cardMargin = 8;
  static const int _initialPage = 5000;

  // 🎨 ألوان التصميم
  static const Color whiteBg = Colors.white;
  static const Color navyDark = Color(0xFF0A2451);
  static const Color cardCream = Color(0xFFF2E8D0);
  static const Color iconBg = Color(0xFFF2F2F2);
  static const Color iconColor = Color(0xFF1A1A1A);
  static const Color textGray = Color(0xFF6B6B6B);

  // 🖼️ قائمة صور الإعلانات
  final List<String> _adImages = const [
    'assets/images/1.jpg',
    'assets/images/2.jpg',
    'assets/images/3.jpg',
    'assets/images/4.jpg',
  ];

  // 🎓 قائمة التخصصات — 15 تخصص
  final List<Map<String, String>> _specialties = const [
    {
      'title': 'بكالوريوس\nإدارة أعمال',
      'visits': '6,635',
      'image': 'assets/images/specialty_1.png',
    },
    {
      'title': 'بكالوريوس\nإدارة صحية',
      'visits': '5,420',
      'image': 'assets/images/specialty_2.png',
    },
    {
      'title': 'بكالوريوس الأمن\nالسيبراني والشبكات',
      'visits': '5,180',
      'image': 'assets/images/specialty_3.png',
    },
    {
      'title': 'بكالوريوس الجرافيكس\nوالوسائط المتعددة',
      'visits': '4,980',
      'image': 'assets/images/specialty_4.png',
    },
    {
      'title': 'بكالوريوس\nالمحاسبة',
      'visits': '4,750',
      'image': 'assets/images/specialty_5.png',
    },
    {
      'title': 'بكالوريوس\nتقنية المعلومات',
      'visits': '4,520',
      'image': 'assets/images/specialty_6.png',
    },
    {
      'title': 'بكالوريوس\nهندسة التعدين',
      'visits': '4,320',
      'image': 'assets/images/specialty_7.png',
    },
    {
      'title': 'بكالوريوس هندسة الديكور\nوالتصميم الداخلي',
      'visits': '3,980',
      'image': 'assets/images/specialty_8.png',
    },
    {
      'title': 'تخصص\nالتمريض',
      'visits': '3,750',
      'image': 'assets/images/specialty_9.png',
    },
    {
      'title': 'تخصص القبالة\nوالتوليد',
      'visits': '3,540',
      'image': 'assets/images/specialty_10.png',
    },
    {
      'title': 'تخصص المختبرات\nالطبية',
      'visits': '3,210',
      'image': 'assets/images/specialty_11.png',
    },
    {
      'title': 'تخصص\nالصيدلة',
      'visits': '2,980',
      'image': 'assets/images/specialty_12.png',
    },
    {
      'title': 'تخصص\nتصميم الأزياء',
      'visits': '2,650',
      'image': 'assets/images/specialty_13.png',
    },
    {
      'title': 'تخصص فني\nتخدير وإنعاش',
      'visits': '2,340',
      'image': 'assets/images/specialty_14.png',
    },
    {
      'title': 'تخصص فني\nعمليات',
      'visits': '2,180',
      'image': 'assets/images/specialty_15.png',
    },
  ];

  @override
  void initState() {
    super.initState();

    _pageController = PageController(
      viewportFraction: 0.55,
      initialPage: _initialPage,
    );

    _syncController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        _startAutoPlay();
      }
    });
  }

  @override
  void dispose() {
    _autoPlayTimer?.cancel();
    _syncController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _startAutoPlay() {
    _autoPlayTimer?.cancel();
    _autoPlayTimer = Timer.periodic(
      const Duration(seconds: 4),
          (timer) {
        if (!mounted) return;
        if (!_pageController.hasClients) return;

        final currentPage = _pageController.page?.round() ?? _initialPage;

        _pageController.animateToPage(
          currentPage + 1,
          duration: const Duration(milliseconds: 700),
          curve: Curves.easeInOut,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: whiteBg,
      body: SafeArea(
        bottom: false,
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Column(
            children: [
              Container(
                color: whiteBg,
                padding: const EdgeInsets.only(top: 14, bottom: 6),
                child: _buildTopBar(),
              ),
              Expanded(
                child: NotificationListener<ScrollNotification>(
                  onNotification: (notification) {
                    if (notification is ScrollStartNotification) {
                      _syncController.repeat();
                    } else if (notification is ScrollEndNotification) {
                      _syncController.forward(from: 0).then((_) {
                        if (mounted) _syncController.stop();
                      });
                    }
                    return false;
                  },
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 4),
                        _buildWelcome(),
                        const SizedBox(height: 8),
                        _buildSlider(),
                        const SizedBox(height: 8),
                        _buildDots(),
                        const SizedBox(height: 10),
                        _buildServicesGrid(),
                        const SizedBox(height: 8),
                        _buildSpecialtiesHeader(),
                        const SizedBox(height: 6),
                        _buildSpecialtyCards(),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
              _buildBottomNav(),
            ],
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════
  // 1) الشريط العلوي
  // ══════════════════════════════════════
  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'مساء الخير',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,   // ← من w700 إلى w800
                  color: navyDark,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.userName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,   // ← من w400 إلى w500
                  color: navyDark,
                  height: 1.2,
                ),
              ),
            ],
          ),
          const Spacer(),
          _buildMessageIcon(),
          const SizedBox(width: 10),
          _buildBellIcon(),
        ],
      ),
    );
  }

  Widget _buildBellIcon() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const NotificationsScreen(),
              ),
            );
          },
          child: Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.notifications_rounded,
              color: iconColor,
              size: 26,
            ),
          ),
        ),
        Positioned(
          top: 8,
          right: 10,
          child: Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: const Color(0xFFE53935),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMessageIcon() {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: iconBg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: Stack(
            alignment: Alignment.center,
            children: [
              const Icon(
                Icons.chat_bubble_outline_rounded,
                color: iconColor,
                size: 24,
              ),
              Positioned(
                top: 10,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildTinyDot(),
                    const SizedBox(width: 2),
                    _buildTinyDot(),
                    const SizedBox(width: 2),
                    _buildTinyDot(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTinyDot() {
    return Container(
      width: 2.5,
      height: 2.5,
      decoration: const BoxDecoration(
        color: iconColor,
        shape: BoxShape.circle,
      ),
    );
  }

  // ══════════════════════════════════════
  // 2) "اسحب للأسفل للتحديث"
  // ══════════════════════════════════════
  Widget _buildWelcome() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'اسحب للأسفل للتحديث',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,   // ← من w500 إلى w600
            color: textGray,
          ),
        ),
        const SizedBox(width: 6),
        RotationTransition(
          turns: _syncController,
          child: const Icon(
            Icons.sync_rounded,
            size: 13,
            color: textGray,
          ),
        ),
      ],
    );
  }

  // ══════════════════════════════════════
  // 3) السلايدر
  // ══════════════════════════════════════
  Widget _buildSlider() {
    return SizedBox(
      height: _cardHeight + (_cardMargin * 2),
      child: PageView.builder(
        controller: _pageController,
        itemCount: 10000,
        onPageChanged: (i) {
          setState(() => _currentSlide = i % _adImages.length);
        },
        physics: const BouncingScrollPhysics(),
        itemBuilder: (context, i) {
          final imageIndex = i % _adImages.length;

          return AnimatedBuilder(
            animation: _pageController,
            builder: (context, child) {
              double value = 0;
              if (_pageController.position.haveDimensions) {
                value = (_pageController.page ?? _initialPage.toDouble()) - i;
              }

              final absValue = value.abs();
              final scale = (1 - absValue * 0.30).clamp(0.78, 1.0);
              final opacity = (1 - absValue * 0.45).clamp(0.55, 1.0);
              final translateY = absValue * 2;

              return Transform.translate(
                offset: Offset(0, translateY),
                child: Transform.scale(
                  scale: scale,
                  child: Opacity(
                    opacity: opacity,
                    child: _buildSlideCard(_adImages[imageIndex]),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildSlideCard(String imagePath) {
    return Padding(
      padding: const EdgeInsets.all(_cardMargin),
      child: Container(
        width: _cardWidth,
        height: _cardHeight,
        decoration: BoxDecoration(
          color: cardCream,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: navyDark.withOpacity(0.15),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                imagePath,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: cardCream,
                    child: const Center(
                      child: Icon(
                        Icons.image_outlined,
                        size: 40,
                        color: Color(0xFF9E7A2F),
                      ),
                    ),
                  );
                },
              ),
              Positioned.fill(
                child: IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.white.withOpacity(0.05),
                          Colors.transparent,
                          Colors.transparent,
                          Colors.black.withOpacity(0.04),
                        ],
                        stops: const [0.0, 0.12, 0.88, 1.0],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════
  // 4) مؤشرات السلايدر
  // ══════════════════════════════════════
  Widget _buildDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_adImages.length, (i) {
        final isActive = i == _currentSlide;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: isActive ? 18 : 6,
          height: 6,
          decoration: BoxDecoration(
            color: isActive ? navyDark : const Color(0xFFCFCFCF),
            borderRadius: BorderRadius.circular(3),
          ),
        );
      }),
    );
  }

  // ══════════════════════════════════════
  // 5) شبكة الخدمات — خطوط أغلسط
  // ══════════════════════════════════════
  Widget _buildServicesGrid() {
    final services = [
      {'iconPath': 'assets/new_icons/الكنترول.svg', 'label': 'الكنترول', 'route': null},
      {'iconPath': 'assets/new_icons/شؤون الطلاب.svg', 'label': 'شؤون الطلاب', 'route': null},
      {'iconPath': 'assets/new_icons/الاكاديميه.svg', 'label': 'الأكاديمية', 'route': null},
      {'iconPath': 'assets/new_icons/القبول والتسجيل.svg', 'label': 'القبول\nوالتسجيل', 'route': 'admission'},
      {'iconPath': 'assets/new_icons/تقديم طلب عام.svg', 'label': 'تقديم طلب\nعام', 'route': null},
      {'iconPath': 'assets/new_icons/انجازاتنا.svg', 'label': 'إنجازاتنا', 'route': null},
      {'iconPath': 'assets/new_icons/خريجي الغد.svg', 'label': 'خريجي الغد', 'route': null},
      {'iconPath': 'assets/new_icons/المالية.svg', 'label': 'المالية', 'route': null},
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: services.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          mainAxisSpacing: 0,
          crossAxisSpacing: 6,
          childAspectRatio: 0.82,
        ),
        itemBuilder: (context, i) => _buildServiceItem(
          iconPath: services[i]['iconPath'] as String,
          label: services[i]['label'] as String,
          route: services[i]['route'] as String?,
        ),
      ),
    );
  }

  Widget _buildServiceItem({
    required String iconPath,
    required String label,
    String? route,
  }) {
    return GestureDetector(
      onTap: () {
        if (route == 'admission') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AdmissionScreen(),
            ),
          );
        }
      },
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0B1E3D).withOpacity(0.20),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SvgPicture.asset(
                iconPath,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: navyDark,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════
  // 6) عنوان التخصصات — خطوط أغلسط
  // ══════════════════════════════════════
  Widget _buildSpecialtiesHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'تعرف على التخصصات',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: navyDark,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AllSpecialtiesScreen(),
                ),
              );
            },
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: const Size(0, 0),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text(
              'مشاهدة الكل',
              style: TextStyle(
                fontSize: 13,
                color: navyDark,
                fontWeight: FontWeight.w800,   // ← من w600 إلى w800
                decoration: TextDecoration.underline,
                decorationColor: navyDark,
                decorationThickness: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════
  // 7) بطاقات التخصصات — خطوط أغلسط
  // ══════════════════════════════════════
  Widget _buildSpecialtyCards() {
    return SizedBox(
      height: 260,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        physics: const BouncingScrollPhysics(),
        itemCount: _specialties.length,
        itemBuilder: (context, i) {
          final item = _specialties[i];
          return Padding(
            padding: EdgeInsets.only(
              left: i == _specialties.length - 1 ? 0 : 12,
            ),
            child: _buildSpecialtyCard(
              title: item['title']!,
              visits: item['visits']!,
              imagePath: item['image']!,
            ),
          );
        },
      ),
    );
  }

  Widget _buildSpecialtyCard({
    required String title,
    required String visits,
    required String imagePath,
  }) {
    return Container(
      width: 300,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFE5E5E5),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 130,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    imagePath,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: const Color(0xFFF2E8D0),
                        child: const Center(
                          child: Icon(
                            Icons.image_outlined,
                            size: 36,
                            color: Color(0xFF9E7A2F),
                          ),
                        ),
                      );
                    },
                  ),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.85),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.favorite_border_rounded,
                        size: 15,
                        color: Color(0xFF6B6B6B),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // ✅ العنوان
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: navyDark,
                        height: 1.25,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    // ✅ النجوم + الزيارات
                    Row(
                      children: [
                        ...List.generate(5, (index) {
                          return const Icon(
                            Icons.star_rounded,
                            size: 14,
                            color: Color(0xFFF4B400),
                          );
                        }),
                        const SizedBox(width: 4),
                        Text(
                          '($visits زيارة)',
                          style: const TextStyle(
                            fontSize: 11,
                            color: textGray,
                            fontWeight: FontWeight.w800,   // ← من w600
                          ),
                        ),
                      ],
                    ),
                    // ✅ الشارة + الالتحاق
                    Row(
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF5F5F5),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'صنعاء',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,   // ← من w800
                                  color: navyDark,
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Text(
                              '- دارس',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w900,   // ← من w700
                                color: textGray,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            color: navyDark,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(
                            Icons.login_rounded,
                            size: 14,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          'الالتحاق\nبالتخصص',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w900,   // ← من w700
                            color: navyDark,
                            height: 1.15,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════
  // 8) شريط التنقل السفلي
  // ══════════════════════════════════════
  Widget _buildBottomNav() {
    final items = [
      {'icon': Icons.home_rounded},
      {'icon': Icons.location_on_outlined},
      {'icon': Icons.calendar_today_outlined},
      {'icon': Icons.person_outline_rounded},
    ];

    return Container(
      height: 72,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(items.length, (i) {
          final isActive = i == _currentNavIndex;
          return GestureDetector(
            onTap: () => setState(() => _currentNavIndex = i),
            behavior: HitTestBehavior.opaque,
            child: Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: isActive ? navyDark : Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: Icon(
                items[i]['icon'] as IconData,
                color: isActive ? Colors.white : const Color(0xFFB0B0B0),
                size: 24,
              ),
            ),
          );
        }),
      ),
    );
  }
}