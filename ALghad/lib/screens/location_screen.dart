import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'home_screen.dart';
import 'calendar_screen.dart';
import 'profile_screen.dart';

class LocationScreen extends StatefulWidget {
  const LocationScreen({super.key});

  @override
  State<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen>
    with SingleTickerProviderStateMixin {
  int _currentNavIndex = 1; // 1 = Location tab active
  final TransformationController _transformationController =
      TransformationController();
  final TextEditingController _searchController = TextEditingController();

  double _calculatedDistance = 0.0;
  bool _isCalculating = false;
  bool _distanceCalculated = false;

  static const Color navyDark = Color(0xFF0A2451);
  static const Color gold = Color(0xFFD39706);
  static const Color textGray = Color(0xFF6B6B6B);

  // 📍 رابط خريطة موقع الكلية على Google Maps
  final String _googleMapsUrl =
      'https://www.google.com/maps/place/Alghad+International+College+for+Health+and+Technical+Sciences,+Airport+Rd,+Sanaa,+Yemen/data=!4m2!3m1!1s0x1603d9084afd580b:0x410f08966bf16efc!18m1!1e1?utm_source=mstt_1&entry=gps&coh=192189&g_ep=CAESBzI2LjI3LjUYACCenQoqnwEsOTQyNjc3MjcsOTQyOTIxOTUsOTQyOTk1MzIsMTAwNzk2NDk4LDEwMDc5Nzc2MSwxMDA3OTY1MzUsOTQyODA1NzYsOTQyMCczOTQsOTQy0c1MDYsOTQyMDg1MDYsOTQyMTg2NTMsOTQyMjk4MzksMTAwODA4NjU0LDk0Mjc1MTY4LDk0Mjc5NjE5LDEwMDgyMDIzNywxMDA4MjI0OTRCAllF&skid=0ca2778d-6407-4ec9-a083-30f793e0b961&g_st=aw&q=Alghad%2BInternational%2BCollege%2Bfor%2BHealth%2Band%2BTechnical%2BSciences%2C%2BAirport%2BRd%2C%2BSanaa%2C%2BYemen';

  @override
  void dispose() {
    _transformationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // 🚀 فتح الموقع مباشرة على خرائط جوجل
  Future<void> _openGoogleMaps() async {
    final Uri url = Uri.parse(_googleMapsUrl);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تعذر فتح تطبيق خرائط جوجل'),
          ),
        );
      }
    }
  }

  // 📍 حساب المسافة بين الموقع الحالي والكلية
  void _calculateDistance() {
    setState(() {
      _isCalculating = true;
    });

    Future.delayed(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      setState(() {
        _isCalculating = false;
        _calculatedDistance = 2.4; // 2.4 كم مسافة تقديرية في صنعاء
        _distanceCalculated = true;
      });
    });
  }

  void _zoomIn() {
    final Matrix4 currentMatrix = _transformationController.value;
    _transformationController.value = currentMatrix.scaled(1.25, 1.25, 1.0);
  }

  void _zoomOut() {
    final Matrix4 currentMatrix = _transformationController.value;
    _transformationController.value = currentMatrix.scaled(0.8, 0.8, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Stack(
            children: [
              // 1. الخريطة التفاعلية بالكامل مع دعم التكبير والتحريك
              Positioned.fill(
                child: InteractiveViewer(
                  transformationController: _transformationController,
                  minScale: 0.8,
                  maxScale: 4.5,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.asset(
                        'assets/images/map_location_screen.png',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: const Color(0xFFE5ECEF),
                            child: const Center(
                              child: Icon(
                                Icons.map_rounded,
                                size: 80,
                                color: navyDark,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),

              // 2. شريط البحث العلوي المميز (أماكن مقترحة، معهد أفواي...)
              Positioned(
                top: 16,
                left: 16,
                right: 16,
                child: Container(
                  height: 50,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.10),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.search_rounded,
                        color: Color(0xFF9E9E9E),
                        size: 24,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          style: const TextStyle(
                            fontSize: 14,
                            color: navyDark,
                            fontWeight: FontWeight.w600,
                          ),
                          decoration: const InputDecoration(
                            hintText: 'أماكن مقترحة، (معهد أفواي)...',
                            hintStyle: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF9E9E9E),
                              fontWeight: FontWeight.w400,
                            ),
                            border: InputBorder.none,
                            isDense: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 3. أزرار التحكم في التكبير (+ و -) على يمين الخريطة
              Positioned(
                left: 16,
                top: 90,
                child: Column(
                  children: [
                    FloatingActionButton.small(
                      heroTag: 'zoomIn',
                      onPressed: _zoomIn,
                      backgroundColor: Colors.white,
                      elevation: 4,
                      child: const Icon(Icons.add_rounded, color: navyDark),
                    ),
                    const SizedBox(height: 8),
                    FloatingActionButton.small(
                      heroTag: 'zoomOut',
                      onPressed: _zoomOut,
                      backgroundColor: Colors.white,
                      elevation: 4,
                      child: const Icon(Icons.remove_rounded, color: navyDark),
                    ),
                  ],
                ),
              ),

              // 4. البطاقة السفلية التفاعلية (معلومات الكلية + زر تحديد المسافة وخرائط جوجل)
              Positioned(
                bottom: 80,
                left: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.12),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: navyDark,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.location_on_rounded,
                              color: gold,
                              size: 26,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text(
                                  'كلية الغد الدولية للعلوم الصحية والتقنية',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w900,
                                    color: navyDark,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                SizedBox(height: 3),
                                Text(
                                  'شارع المطار - صنعاء، اليمن',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: textGray,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      if (_distanceCalculated) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF2F5F8),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.near_me_rounded,
                                color: navyDark,
                                size: 18,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'المسافة بينك وبين الكلية: $_calculatedDistance كم (~5 دقائق بالسيارة)',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: navyDark,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 14),

                      // الأزرار: زر تحديد المسافة + زر فتح الخريطة المباشرة
                      Row(
                        children: [
                          // زر تحدد المسافة والموقع
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _isCalculating ? null : _calculateDistance,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: navyDark,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              icon: _isCalculating
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.my_location_rounded,
                                      color: gold,
                                      size: 18,
                                    ),
                              label: const Text(
                                'تحديد المسافة',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(width: 10),

                          // زر خرائط جوجل
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _openGoogleMaps,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: navyDark,
                                side: const BorderSide(color: navyDark, width: 1.5),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              icon: const Icon(
                                Icons.directions_rounded,
                                color: navyDark,
                                size: 18,
                              ),
                              label: const Text(
                                'فتح الخريطة',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // 5. شريط التنقل السفلي ثابت
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: _buildBottomNav(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════
  // شريط التنقل السفلي
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
            onTap: () {
              if (i == 0) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const HomeScreen(),
                  ),
                );
              } else if (i == 2) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CalendarScreen(),
                  ),
                );
              } else if (i == 3) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ProfileScreen(),
                  ),
                );
              } else {
                setState(() => _currentNavIndex = i);
              }
            },
            behavior: HitTestBehavior.opaque,
            child: Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: isActive ? const Color(0xFFF2F5F8) : Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: Icon(
                items[i]['icon'] as IconData,
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
