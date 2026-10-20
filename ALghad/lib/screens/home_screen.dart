import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/auth_service.dart';
import '../services/data_service.dart';
import '../services/system_notification_service.dart';
import 'all_specialties_screen.dart';
import 'notifications_screen.dart';
import 'admission_screen.dart';
import 'academy_screen.dart';
import 'control_screen.dart';
import 'student_affairs_screen.dart';
import 'general_request_screen.dart';
import 'finance_screen.dart';
import 'profile_screen.dart';
import 'calendar_screen.dart';
import 'location_screen.dart';
import 'alumni_screen.dart';
import 'achievements_screen.dart';

class _ImageBytesCache {
  static final Map<String, Uint8List> _cache = {};

  static Uint8List? get(String dataUri) {
    if (_cache.containsKey(dataUri)) return _cache[dataUri];
    try {
      final commaIdx = dataUri.indexOf(',');
      final b64 = commaIdx != -1 ? dataUri.substring(commaIdx + 1) : dataUri;
      final bytes = base64Decode(b64.replaceAll(RegExp(r'\s+'), ''));
      _cache[dataUri] = bytes;
      return bytes;
    } catch (_) {
      return null;
    }
  }
}

class HomeScreen extends StatefulWidget {
  final String studentFullName;
  final String? userName;

  const HomeScreen({
    super.key,
    this.studentFullName = '',
    this.userName,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with TickerProviderStateMixin {
  int _currentSlide = 0;
  int _currentNavIndex = 0;
  int _unreadNotificationsCount = 0;
  String? _sessionFullName;

  String get _effectiveFullName {
    if (_sessionFullName != null && _sessionFullName!.trim().isNotEmpty) {
      return _sessionFullName!.trim();
    }
    if (widget.userName != null && widget.userName!.trim().isNotEmpty) {
      return widget.userName!.trim();
    }
    if (widget.studentFullName.trim().isNotEmpty) {
      return widget.studentFullName.trim();
    }
    return 'طالب أكاديمي';
  }

  String get _firstName {
    final name = _effectiveFullName;
    if (name == 'طالب أكاديمي') return 'طالبنا العزيز';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return 'طالبنا العزيز';
    if (parts.length > 1 && (parts[0] == 'عبد' || parts[0] == 'أمة' || parts[0] == 'امانة')) {
      return '${parts[0]} ${parts[1]}';
    }
    return parts.first;
  }

  String get _greeting =>
      DateTime.now().hour < 12 ? 'صباح الخير' : 'مساء الخير';

  Timer? _autoPlayTimer;
  late AnimationController _syncController;
  late PageController _pageController;

  static const double _cardWidth = 240;
  static const double _cardHeight = 295;
  static const int _initialPage = 5000;

  // 🎨 ألوان التصميم
  static const Color whiteBg = Colors.white;
  static const Color navyDark = Color(0xFF0A2451);
  static const Color cardCream = Color(0xFFF2E8D0);
  static const Color iconBg = Color(0xFFF2F2F2);
  static const Color iconColor = Color(0xFF1A1A1A);
  static const Color textGray = Color(0xFF6B6B6B);

  // 🖼️ قائمة صور الإعلانات (3 بنرات فقط يتم جلبها وتحديثها سحابياً عبر الإنترنت)
  List<String> _adImages = [
    'assets/images/1.jpg',
    'assets/images/2.jpg',
    'assets/images/3.jpg',
  ];

  // 🎓 قائمة التخصصات — 15 تخصص (يتم جلبها وتحديثها وروابطها سحابياً عبر الإنترنت)
  List<Map<String, String>> _specialties = [
    {
      'title': 'بكالوريوس\nإدارة أعمال',
      'visits': '6,635',
      'image': 'assets/images/specialty_1.png',
      'youtube_url': 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
    },
    {
      'title': 'بكالوريوس\nإدارة صحية',
      'visits': '5,420',
      'image': 'assets/images/specialty_2.png',
      'youtube_url': 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
    },
    {
      'title': 'بكالوريوس الأمن\nالسيبراني والشبكات',
      'visits': '5,180',
      'image': 'assets/images/specialty_3.png',
      'youtube_url': 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
    },
    {
      'title': 'بكالوريوس الجرافيكس\nوالوسائط المتعددة',
      'visits': '4,980',
      'image': 'assets/images/specialty_4.png',
      'youtube_url': 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
    },
    {
      'title': 'بكالوريوس\nالمحاسبة',
      'visits': '4,750',
      'image': 'assets/images/specialty_5.png',
      'youtube_url': 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
    },
    {
      'title': 'بكالوريوس\nتقنية المعلومات',
      'visits': '4,520',
      'image': 'assets/images/specialty_6.png',
      'youtube_url': 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
    },
    {
      'title': 'بكالوريوس\nهندسة التعدين',
      'visits': '4,320',
      'image': 'assets/images/specialty_7.png',
      'youtube_url': 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
    },
    {
      'title': 'بكالوريوس هندسة الديكور\nوالتصميم الداخلي',
      'visits': '3,980',
      'image': 'assets/images/specialty_8.png',
      'youtube_url': 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
    },
    {
      'title': 'تخصص\nالتمريض',
      'visits': '3,750',
      'image': 'assets/images/specialty_9.png',
      'youtube_url': 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
    },
    {
      'title': 'تخصص القبالة\nوالتوليد',
      'visits': '3,540',
      'image': 'assets/images/specialty_10.png',
      'youtube_url': 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
    },
    {
      'title': 'تخصص المختبرات\nالطبية',
      'visits': '3,210',
      'image': 'assets/images/specialty_11.png',
      'youtube_url': 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
    },
    {
      'title': 'تخصص\nالصيدلة',
      'visits': '2,980',
      'image': 'assets/images/specialty_12.png',
      'youtube_url': 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
    },
    {
      'title': 'تخصص\nتصميم الأزياء',
      'visits': '2,650',
      'image': 'assets/images/specialty_13.png',
      'youtube_url': 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
    },
    {
      'title': 'تخصص فني\nتخدير وإنعاش',
      'visits': '2,340',
      'image': 'assets/images/specialty_14.png',
      'youtube_url': 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
    },
    {
      'title': 'تخصص فني\nعمليات',
      'visits': '2,180',
      'image': 'assets/images/specialty_15.png',
      'youtube_url': 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
    },
  ];

  @override
  void initState() {
    super.initState();

    _pageController = PageController(
      viewportFraction: 0.76,
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

    _loadStudentProfile();
    _checkUnreadNotifications();
    _loadBannersFromSupabase();
    _listenToBannersRealtime();
    _loadSpecialtiesFromSupabase();
  }

  RealtimeChannel? _bannersChannel;

  void _listenToBannersRealtime() {
    try {
      _bannersChannel = Supabase.instance.client
          .channel('public_banners_sync_${DateTime.now().millisecondsSinceEpoch}')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'system_instructions',
            callback: (payload) {
              final rec = payload.newRecord;
              if (rec['service_key'] == 'ad_banners') {
                _loadBannersFromSupabase();
              }
            },
          )
          .subscribe();
    } catch (_) {}
  }

  Future<void> _loadBannersFromSupabase() async {
    try {
      List<String> list = [];

      // 1. محاولة جلب البنرات المحدثة من system_instructions المربوطة بلوحة التحكم
      try {
        final res = await Supabase.instance.client
            .from('system_instructions')
            .select('steps')
            .eq('service_key', 'ad_banners')
            .maybeSingle();

        if (res != null && res['steps'] != null) {
          final decoded = jsonDecode(res['steps'] as String);
          if (decoded is List && decoded.isNotEmpty) {
            list = decoded
                .map((e) => (e['image_url'] ?? '').toString().trim())
                .where((p) => p.isNotEmpty)
                .take(3)
                .toList();
          }
        }
      } catch (e) {
        debugPrint('Error reading system_instructions banners: $e');
      }

      // 2. إذا لم تتوفر، محاولة القراءة من جدول ad_banners كبديل
      if (list.isEmpty) {
        try {
          final adRes = await Supabase.instance.client
              .from('ad_banners')
              .select('image_url')
              .order('display_order', ascending: true)
              .limit(3);
          if (adRes is List && adRes.isNotEmpty) {
            list = (adRes as List)
                .map((e) => (e['image_url'] ?? '').toString().trim())
                .where((p) => p.isNotEmpty)
                .take(3)
                .toList();
          }
        } catch (_) {}
      }

      // 3. ضمان وجود 3 بنرات إعلانية دائماً في المساحة (يسمح بـ 3 بنرات فقط)
      int fallbackIndex = 1;
      while (list.length < 3) {
        list.add('assets/images/$fallbackIndex.jpg');
        fallbackIndex++;
      }

      final finalList = list.take(3).toList();

      if (mounted) {
        setState(() {
          _adImages = finalList;
        });
      }
    } catch (e) {
      debugPrint('Error loading banners from Supabase: $e');
    }
  }

  Future<void> _loadSpecialtiesFromSupabase() async {
    try {
      final res = await Supabase.instance.client
          .from('specialties')
          .select()
          .order('display_order', ascending: true);
      final List list = res as List;
      if (list.isNotEmpty && mounted) {
        setState(() {
          _specialties = list.map((item) {
            final degree = item['degree_type'] ?? 'بكالوريوس';
            final title = item['title'] ?? '';
            String loc = item['location']?.toString() ?? 'صنعاء - دارس';
            String yt = '';
            if (loc.contains('|')) {
              final parts = loc.split('|');
              loc = parts[0];
              yt = parts.sublist(1).join('|');
            } else if (loc.startsWith('http')) {
              yt = loc;
              loc = 'صنعاء - دارس';
            }
            return {
              'title': '$degree\n$title',
              'visits': '${item['visits_count'] ?? '1,200'}',
              'image': (item['image_url'] ?? '').toString(),
              'youtube_url': yt,
              'location': loc,
            };
          }).toList();
        });
      }
    } catch (e) {
      debugPrint('Error loading specialties from Supabase: $e');
    }
  }

  Future<void> _openSpecialtyVideo(String? url, String title) async {
    if (url != null && url.trim().isNotEmpty) {
      final uri = Uri.parse(url.trim());
      try {
        final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
        if (!launched) {
          await launchUrl(uri, mode: LaunchMode.platformDefault);
        }
        return;
      } catch (e) {
        debugPrint('Could not launch youtube url: $e');
      }
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('سيتم توفير فيديو استكشاف لتخصص ($title) قريباً'),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _loadStudentProfile() async {
    try {
      final session = await AuthService.getSavedSession();
      if (session != null) {
        if (session.fullName.isNotEmpty && mounted) {
          setState(() {
            _sessionFullName = session.fullName;
          });
        }
        // تفعيل الاستماع والتنبيه لشريط إشعارات الهاتف للطالب
        SystemNotificationService.startRealtimeListener(session.academicId);
      }
    } catch (_) {}
  }

  Future<void> _checkUnreadNotifications() async {
    try {
      final session = await AuthService.getSavedSession();
      final String? currentId = session?.academicId;

      var query = Supabase.instance.client
          .from('notifications')
          .select()
          .eq('is_read', false);

      if (currentId != null && currentId.isNotEmpty) {
        query = query.or('academic_id.eq.$currentId,academic_id.is.null');
      } else {
        query = query.filter('academic_id', 'is', null);
      }

      final res = await query;
      if (mounted) {
        setState(() {
          _unreadNotificationsCount = (res as List).length;
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _autoPlayTimer?.cancel();
    if (_bannersChannel != null) {
      try {
        Supabase.instance.client.removeChannel(_bannersChannel!);
      } catch (_) {}
    }
    _syncController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _startAutoPlay() {
    _autoPlayTimer?.cancel();
    _autoPlayTimer = Timer.periodic(
      const Duration(milliseconds: 2000),
          (timer) {
        if (!mounted) return;
        if (!_pageController.hasClients) return;

        final currentPage = _pageController.page?.round() ?? _initialPage;

        _pageController.animateToPage(
          currentPage + 1,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOutCubic,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _currentNavIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_currentNavIndex != 0) {
          setState(() => _currentNavIndex = 0);
        }
      },
      child: Scaffold(
        backgroundColor: whiteBg,
        body: SafeArea(
          bottom: false,
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: Column(
              children: [
                Expanded(
                  child: IndexedStack(
                    index: _currentNavIndex,
                    children: [
                      _buildHomeContent(),
                      const LocationScreen(hideBottomNav: true),
                      CalendarScreen(
                        hideBottomNav: true,
                        onBackToHome: () => setState(() => _currentNavIndex = 0),
                      ),
                      ProfileScreen(
                        hideBottomNav: true,
                        studentFullName: _effectiveFullName,
                        onBackToHome: () => setState(() => _currentNavIndex = 0),
                      ),
                    ],
                  ),
                ),
                _buildBottomNav(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHomeContent() {
    return Column(
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
                _loadBannersFromSupabase();
                _loadSpecialtiesFromSupabase();
              }
              return false;
            },
            child: RefreshIndicator(
              color: navyDark,
              onRefresh: () async {
                await Future.wait([
                  _loadBannersFromSupabase(),
                  _loadSpecialtiesFromSupabase(),
                  _checkUnreadNotifications(),
                ]);
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
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
      ),
    ],
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
              Text(
                _greeting,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: navyDark,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _firstName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
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
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const NotificationsScreen(),
              ),
            );
            _checkUnreadNotifications();
          },
          child: Container(
            width: 46,
            height: 46,
            decoration: const BoxDecoration(
              color: iconBg,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.notifications_rounded,
              color: iconColor,
              size: 26,
            ),
          ),
        ),
        if (_unreadNotificationsCount > 0)
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
    return GestureDetector(
      onTap: () async {
        final phone = await DataService.getCollegeContactPhone();
        final cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
        final targetPhone = cleanPhone.isNotEmpty ? cleanPhone : '967776166321';
        final Uri waMeUrl = Uri.parse('https://wa.me/$targetPhone');
        final Uri whatsappUrl = Uri.parse('whatsapp://send?phone=$targetPhone');
        try {
          final launched = await launchUrl(waMeUrl, mode: LaunchMode.externalApplication);
          if (!launched && await canLaunchUrl(whatsappUrl)) {
            await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
          }
        } catch (_) {
          try {
            await launchUrl(waMeUrl, mode: LaunchMode.externalApplication);
          } catch (_) {}
        }
      },
      child: Container(
        width: 46,
        height: 46,
        decoration: const BoxDecoration(
          color: iconBg,
          shape: BoxShape.circle,
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
  // 3) السلايدر
  // ══════════════════════════════════════
  Widget _buildSlider() {
    return SizedBox(
      height: 325,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 1) PageView غير مرئي للتحكم في التمرير والإيماءات
          PageView.builder(
            controller: _pageController,
            itemCount: 10000,
            onPageChanged: (i) {
              setState(() => _currentSlide = i % _adImages.length);
            },
            physics: const BouncingScrollPhysics(),
            itemBuilder: (context, i) => const SizedBox.shrink(),
          ),

          // 2) رسم 3 بطاقات فقط مع تدوير ثلاثي الأبعاد 3D Turntable كما في فيقما (المركز دائماً في الأمام)
          IgnorePointer(
            child: AnimatedBuilder(
              animation: _pageController,
              builder: (context, child) {
                double page = _initialPage.toDouble();
                if (_pageController.position.haveDimensions) {
                  page = _pageController.page ?? page;
                }

                int currentPage = page.round();

                // 3 كروت فقط في المساحة كما في تصميم فيقما (يمين، يسار، والمركز)
                List<int> indices = [
                  currentPage - 1,
                  currentPage + 1,
                  currentPage,
                ];

                // ترتيب العناصر بحيث يتم رسم الأبعد أولاً، والأقرب للمركز يتم رسمه أخيراً (ليكون في الأعلى)
                indices.sort((a, b) {
                  final distA = (a - page).abs();
                  final distB = (b - page).abs();
                  return distB.compareTo(distA);
                });

                return LayoutBuilder(
                  builder: (context, constraints) {
                     // تباعد البطاقات الأفقية لإظهار دوران ثلاثي الأبعاد متناسق
                    final stepDistance = constraints.maxWidth * 0.32;

                    return Stack(
                      alignment: Alignment.center,
                      children: indices.map((i) {
                        final imageIndex = ((i % _adImages.length) + _adImages.length) % _adImages.length;
                        final value = page - i;
                        final absValue = value.abs();

                        if (absValue > 1.35) return const SizedBox.shrink();

                        // تحجيم وتلاشي خفيف للبطاقات الجانبية
                        final scale = (1.0 - absValue * 0.18).clamp(0.80, 1.0);
                        final opacity = (1.0 - absValue * 0.15).clamp(0.80, 1.0);

                        // إزاحة أفقية وبطاقات مسطحة تماماً بدون أي انحناء
                        final dx = value * stepDistance;

                        final matrix = Matrix4.identity()
                          ..translate(dx, 0.0, 0.0)
                          ..scale(scale, scale, 1.0);

                        Widget card = _buildSlideCard(_adImages[imageIndex], isCenter: absValue < 0.35);

                        card = Opacity(
                          opacity: opacity,
                          child: Transform(
                            alignment: Alignment.center,
                            transform: matrix,
                            child: card,
                          ),
                        );

                        return Align(
                          alignment: Alignment.center,
                          child: UnconstrainedBox(
                            child: SizedBox(
                              width: _cardWidth,
                              height: _cardHeight,
                              child: card,
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlideCard(String imagePath, {bool isCenter = false}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: _cardWidth,
      height: _cardHeight,
      decoration: BoxDecoration(
        color: cardCream,
        borderRadius: BorderRadius.circular(8),
        boxShadow: isCenter
            ? [
                BoxShadow(
                  color: navyDark.withOpacity(0.35),
                  blurRadius: 20,
                  spreadRadius: 2,
                  offset: const Offset(0, 10),
                ),
                BoxShadow(
                  color: const Color(0xFF000000).withOpacity(0.12),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ]
            : [
                BoxShadow(
                  color: navyDark.withOpacity(0.10),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          fit: StackFit.expand,
          children: [
            imagePath.startsWith('data:image')
                ? Builder(
                    builder: (context) {
                      final bytes = _ImageBytesCache.get(imagePath);
                      if (bytes != null) {
                        return Image.memory(
                          bytes,
                          fit: BoxFit.fill,
                          gaplessPlayback: true,
                          errorBuilder: (_, __, ___) => Container(
                            color: cardCream,
                            child: const Center(
                              child: Icon(Icons.image_outlined, size: 40, color: Color(0xFF9E7A2F)),
                            ),
                          ),
                        );
                      }
                      return Container(
                        color: cardCream,
                        child: const Center(
                          child: Icon(Icons.image_outlined, size: 40, color: Color(0xFF9E7A2F)),
                        ),
                      );
                    },
                  )
                : imagePath.startsWith('http')
                    ? Image.network(
                        imagePath,
                        fit: BoxFit.fill,
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
                      )
                    : Image.asset(
                        imagePath,
                        fit: BoxFit.fill,
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
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isCenter
                          ? Colors.white.withOpacity(0.6)
                          : Colors.transparent,
                      width: 1.2,
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withOpacity(0.12),
                        Colors.transparent,
                        Colors.transparent,
                        Colors.black.withOpacity(0.05),
                      ],
                      stops: const [0.0, 0.15, 0.85, 1.0],
                    ),
                  ),
                ),
              ),
            ),
          ],
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
      {'iconPath': 'assets/new_icons/admission.png', 'label': 'القبول\nوالتسجيل', 'route': 'admission'},
      {'iconPath': 'assets/new_icons/academy.png', 'label': 'الأكاديمية', 'route': 'academy'},
      {'iconPath': 'assets/new_icons/student_affairs.png', 'label': 'شؤون الطلاب', 'route': 'student_affairs'},
      {'iconPath': 'assets/new_icons/control.png', 'label': 'الكنترول', 'route': 'control'},
      {'iconPath': 'assets/new_icons/finance.png', 'label': 'المالية', 'route': 'finance'},
      {'iconPath': 'assets/new_icons/alumni.png', 'label': 'خريجي الغد', 'route': 'alumni'},
      {'iconPath': 'assets/new_icons/achievements.png', 'label': 'إنجازاتنا', 'route': 'achievements'},
      {'iconPath': 'assets/new_icons/general_request.png', 'label': 'تقديم طلب\nعام', 'route': 'general_request'},
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: services.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          mainAxisSpacing: 9,
          crossAxisSpacing: 6,
          childAspectRatio: 0.85,
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
        } else if (route == 'academy') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AcademyScreen(),
            ),
          );
        } else if (route == 'student_affairs') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const StudentAffairsScreen(),
            ),
          );
        } else if (route == 'control') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ControlScreen(),
            ),
          );
        } else if (route == 'finance') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const FinanceScreen(),
            ),
          );
        } else if (route == 'alumni') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AlumniScreen(),
            ),
          );
        } else if (route == 'achievements') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AchievementsScreen(),
            ),
          );
        } else if (route == 'general_request') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const GeneralRequestScreen(),
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
                  color: const Color(0xFF0B1E3D).withOpacity(0.18),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.asset(
                iconPath,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: const Color(0xFFF2F2F2),
                    child: const Icon(
                      Icons.apps,
                      color: navyDark,
                      size: 32,
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
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
                fontWeight: FontWeight.w800,
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
      height: 226,
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
              youtubeUrl: item['youtube_url'],
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
    String? youtubeUrl,
  }) {
    return GestureDetector(
      onTap: () => _openSpecialtyVideo(youtubeUrl, title),
      child: Container(
        width: 232,
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
                  imagePath.startsWith('data:image')
                      ? Builder(
                          builder: (context) {
                            final bytes = _ImageBytesCache.get(imagePath);
                            if (bytes != null) {
                              return Image.memory(
                                bytes,
                                fit: BoxFit.cover,
                                gaplessPlayback: true,
                                errorBuilder: (_, __, ___) => Container(
                                  color: const Color(0xFFF2E8D0),
                                  child: const Center(
                                    child: Icon(Icons.image_outlined, size: 36, color: Color(0xFF9E7A2F)),
                                  ),
                                ),
                              );
                            }
                            return Container(
                              color: const Color(0xFFF2E8D0),
                              child: const Center(
                                child: Icon(Icons.image_outlined, size: 36, color: Color(0xFF9E7A2F)),
                              ),
                            );
                          },
                        )
                      : imagePath.startsWith('http')
                          ? Image.network(
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
                            )
                          : Image.asset(
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
                        fontSize: 17, // Increased font size
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
                            Icons.play_arrow_rounded,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          'استكشاف\nالتخصص',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
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
    ),
  );
}

  // ══════════════════════════════════════
  // 8) شريط التنقل السفلي
  // ══════════════════════════════════════
  Widget _buildBottomNav() {
    final items = [
      {
        'activeIcon': Icons.home_rounded,
        'inactiveIcon': Icons.home_outlined,
      },
      {
        'activeIcon': Icons.location_on_rounded,
        'inactiveIcon': Icons.location_on_outlined,
      },
      {
        'activeIcon': Icons.calendar_month_rounded,
        'inactiveIcon': Icons.calendar_today_outlined,
      },
      {
        'activeIcon': Icons.person_rounded,
        'inactiveIcon': Icons.person_outline_rounded,
      },
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
          final iconData = isActive
              ? items[i]['activeIcon'] as IconData
              : items[i]['inactiveIcon'] as IconData;

          return GestureDetector(
            onTap: () {
              setState(() => _currentNavIndex = i);
            },
            behavior: HitTestBehavior.opaque,
            child: Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: isActive ? const Color(0xFFEFF4F9) : Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: Icon(
                iconData,
                color: isActive ? navyDark : const Color(0xFFB0B0B0),
                size: 24,
              ),
            ),
          );
        }),
      ),
    );
  }
}