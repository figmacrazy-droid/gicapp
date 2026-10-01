import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
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
  final TextEditingController _searchController = TextEditingController();
  final MapController _mapController = MapController();

  // ألوان التصميم المستوحاة من هوية كلية الغد
  static const Color navyDark = Color(0xFF071B42);
  static const Color gold = Color(0xFFEAA70C);
  static const Color textGray = Color(0xFF6B7280);

  // إحداثيات كلية الغد الدولية بشارع المطار (منطقة دارس - صنعاء)
  static final LatLng _collegeLocation = LatLng(15.4215, 44.2052);

  // موقع المستخدم الافتراضي (لحساب المسافة الحقيقية ورسم المسار)
  final LatLng _userLocation = LatLng(15.4050, 44.2010);

  // حالة حساب المسار والمسافة
  bool _showRoute = false;
  double _distanceKm = 0.0;
  int _carMinutes = 0;
  int _walkMinutes = 0;
  bool _isCalculating = false;

  // المكان المحدد حالياً
  Map<String, dynamic>? _selectedPlace;
  bool _isCardExpanded = true;
  String _selectedCategory = 'الكل';

  // قائمة المعالم والأماكن المحيطة بالكلية (كما في صورة الواجهة المطلوبة)
  final List<Map<String, dynamic>> _nearbyPlaces = [
    {
      'id': 'college',
      'name': 'كلية الغد الدولية للعلوم الصحية والتقنية',
      'enName': 'Alghad International College for Health and...',
      'category': 'تعليم',
      'location': LatLng(15.4215, 44.2052),
      'icon': Icons.location_on_rounded,
      'color': Colors.red,
      'type': 'college',
      'description': 'شارع المطار الرئيسي - جوار سوق دارس',
    },
    {
      'id': 'daris_market',
      'name': 'سوق دارس مركز رياضي',
      'enName': 'Daris Market',
      'category': 'تسوق',
      'location': LatLng(15.4190, 44.2058),
      'icon': Icons.shopping_bag_rounded,
      'color': const Color(0xFF1E88E5),
      'type': 'market',
      'description': 'مركز تجاري ورياضي متكامل',
    },
    {
      'id': 'daris_qat',
      'name': 'سوق دارس للقات خضار وفواكه',
      'enName': 'Daris Fresh Market',
      'category': 'تسوق',
      'location': LatLng(15.4178, 44.2045),
      'icon': Icons.shopping_cart_rounded,
      'color': const Color(0xFF0288D1),
      'type': 'market',
      'description': 'خضروات وفواكه طازجة',
    },
    {
      'id': 'restaurant',
      'name': 'مطاعم دارس السياحية',
      'enName': 'Daris Restaurants',
      'category': 'مطاعم',
      'location': LatLng(15.4202, 44.2055),
      'icon': Icons.restaurant_rounded,
      'color': const Color(0xFFF57C00),
      'type': 'food',
      'description': 'مأكولات شعبية ووجبات سريعة',
    },
    {
      'id': 'hospital',
      'name': 'مستشفى المجد - صنعاء',
      'enName': 'Al-Majd Hospital',
      'category': 'صحة',
      'location': LatLng(15.4168, 44.2065),
      'icon': Icons.local_hospital_rounded,
      'color': const Color(0xFFE53935),
      'type': 'health',
      'description': 'خدمات طبية وطوارئ 24 ساعة',
    },
    {
      'id': 'afwai_institute',
      'name': 'معهد أفواي للغات والكمبيوتر',
      'enName': 'Afway Institute',
      'category': 'تعليم',
      'location': LatLng(15.4230, 44.2040),
      'icon': Icons.school_rounded,
      'color': const Color(0xFF43A047),
      'type': 'education',
      'description': 'دورات لغات وحاسوب وتدريب مهني',
    },
  ];

  // نقاط مسار الطريق المباشر بشارع المطار للكلية
  List<LatLng> _routePoints = [];

  @override
  void initState() {
    super.initState();
    _selectedPlace = _nearbyPlaces[0];
    _prepareRoutePoints();
  }

  void _prepareRoutePoints() {
    // إنشاء مسار محاكي دقيق يتبع خط شارع المطار
    _routePoints = [
      _userLocation,
      LatLng(15.4090, 44.2025),
      LatLng(15.4140, 44.2040),
      LatLng(15.4175, 44.2048),
      LatLng(15.4195, 44.2054),
      _collegeLocation,
    ];
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // حساب المسافة الحقيقية بالكيلومتر ووقت الوصول
  void _calculateDistance() {
    setState(() {
      _isCalculating = true;
    });

    Future.delayed(const Duration(milliseconds: 700), () {
      if (!mounted) return;
      const distanceCalc = Distance();
      final double meters = distanceCalc.as(
        LengthUnit.Meter,
        _userLocation,
        _collegeLocation,
      );

      final double km = (meters / 1000.0);
      final double displayKm = double.parse((km + 0.6).toStringAsFixed(1)); // تقدير مسار الشارع

      setState(() {
        _isCalculating = false;
        _showRoute = true;
        _distanceKm = displayKm;
        _carMinutes = max(3, (displayKm * 2.5).round());
        _walkMinutes = (displayKm * 13).round();
        _isCardExpanded = true;
      });

      // ضبط كاميرا الخريطة لتشمل موقع المستخدم والكلية معاً
      _mapController.move(
        LatLng(
          (_userLocation.latitude + _collegeLocation.latitude) / 2,
          (_userLocation.longitude + _collegeLocation.longitude) / 2,
        ),
        14.8,
      );
    });
  }

  // انتقال الكاميرا لمكان محدد
  void _focusOnPlace(Map<String, dynamic> place) {
    setState(() {
      _selectedPlace = place;
      _isCardExpanded = true;
    });
    _mapController.move(place['location'] as LatLng, 16.5);
  }

  // إعادة التمركز على كلية الغد
  void _recenterCollege() {
    _mapController.move(_collegeLocation, 16.5);
    setState(() {
      _selectedPlace = _nearbyPlaces[0];
    });
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
              // 1. الخريطة الحقيقية التفاعلية بالكامل
              Positioned.fill(
                child: FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _collegeLocation,
                    initialZoom: 16.2,
                    minZoom: 12.0,
                    maxZoom: 18.5,
                    interactionOptions: const InteractionOptions(
                      flags: InteractiveFlag.all,
                    ),
                  ),
                  children: [
                    // طبقة بلاطات الخرائط الحقيقية بنمط CartoDB Voyager النظيف والسريع
                    TileLayer(
                      urlTemplate:
                          'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
                      subdomains: const ['a', 'b', 'c', 'd'],
                      userAgentPackageName: 'com.gic.alghadapp',
                      maxZoom: 19,
                    ),

                    // مسار الطريق المباشر عند حساب المسافة
                    if (_showRoute)
                      PolylineLayer(
                        polylines: [
                          Polyline(
                            points: _routePoints,
                            strokeWidth: 5.5,
                            color: const Color(0xFF1E88E5),
                          ),
                          Polyline(
                            points: _routePoints,
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        ],
                      ),

                    // طبقة العلامات والدبابيس التفاعلية لجميع المعالم
                    MarkerLayer(
                      markers: _buildAllMarkers(),
                    ),
                  ],
                ),
              ),

              // 2. شريط البحث العلوي التفاعلي (مع اقتراحات سريعة)
              _buildSearchBarWithSuggestions(),

              // 3. أزرار التحكم بالخريطة (التكبير، التصغير، وتحديد موقع الكلية)
              _buildMapControls(),

              // 4. البطاقة السفلية العائمة التفاعلية لمعلومات الكلية والمسافة
              _buildFloatingDetailsCard(),

              // 5. شريط التنقل السفلي الثابت المطابق للتصميم
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
  // دبابيس الخريطة التفاعلية مع التسميات
  // ══════════════════════════════════════
  List<Marker> _buildAllMarkers() {
    final List<Marker> markers = [];

    // دبوس موقع المستخدم (إذا كان المسار مفعل)
    if (_showRoute) {
      markers.add(
        Marker(
          point: _userLocation,
          width: 50,
          height: 50,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: navyDark,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'موقعك',
                  style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
              const Icon(
                Icons.person_pin_circle_rounded,
                color: Color(0xFF1E88E5),
                size: 32,
              ),
            ],
          ),
        ),
      );
    }

    // دبابيس الأماكن المحيطة
    for (final place in _nearbyPlaces) {
      final bool isCollege = place['id'] == 'college';
      final LatLng pos = place['location'] as LatLng;

      if (isCollege) {
        // دبوس الكلية الكبير والمميز مع النص كما في الواجهة المطلوبة
        markers.add(
          Marker(
            point: pos,
            width: 220,
            height: 95,
            alignment: Alignment.topCenter,
            child: GestureDetector(
              onTap: () => _focusOnPlace(place),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // أيقونة الدبوس الأحمر
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.red.withValues(alpha: 0.35),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.location_on,
                          color: Color(0xFFE53935),
                          size: 38,
                        ),
                      ),
                      const SizedBox(width: 6),
                      // النص الإنجليزي والعربي للكلية المطابق للصورة المطلوبة
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              place['enName'] as String,
                              style: const TextStyle(
                                color: Color(0xFFB71C1C),
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                height: 1.1,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const Text(
                              'كلية الغد الدولية للعلوم\nالصحية والتقنية',
                              style: TextStyle(
                                color: Color(0xFFB71C1C),
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                height: 1.1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      } else {
        // دبابيس الأماكن المجاورة (مطاعم، سوق دارس، مستشفى...)
        markers.add(
          Marker(
            point: pos,
            width: 140,
            height: 70,
            alignment: Alignment.center,
            child: GestureDetector(
              onTap: () => _focusOnPlace(place),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // الأيقونة الدائرية
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: place['color'] as Color,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      place['icon'] as IconData,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                  const SizedBox(height: 2),
                  // اسم المكان الصغير
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(6),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: Text(
                      place['name'] as String,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: (place['color'] as Color).withValues(alpha: 0.95),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }
    }

    return markers;
  }

  // ══════════════════════════════════════
  // شريط البحث العلوي مع قائمة الاقتراحات
  // ══════════════════════════════════════
  Widget _buildSearchBarWithSuggestions() {
    return Positioned(
      top: 14,
      left: 16,
      right: 16,
      child: Column(
        children: [
          Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.search_rounded,
                  color: Color(0xFF9E9E9E),
                  size: 22,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(
                      fontSize: 13,
                      color: navyDark,
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: const InputDecoration(
                      hintText: 'أماكن مقترحة، (معهد أفواي)...',
                      hintStyle: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF9E9E9E),
                        fontWeight: FontWeight.w400,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                    ),
                    onSubmitted: (query) {
                      _filterAndSelectPlace(query);
                    },
                  ),
                ),
                if (_searchController.text.isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      _searchController.clear();
                      setState(() {});
                    },
                    child: const Icon(
                      Icons.close_rounded,
                      color: Color(0xFF9E9E9E),
                      size: 18,
                    ),
                  ),
              ],
            ),
          ),

          // شرائح الفئات السريعة لاكتشاف ما بجوار الكلية
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: ['الكل', 'تعليم', 'تسوق', 'مطاعم', 'صحة'].map((cat) {
                final isSelected = _selectedCategory == cat;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedCategory = cat;
                    });
                    if (cat != 'الكل') {
                      final place = _nearbyPlaces.firstWhere(
                        (p) => p['category'] == cat,
                        orElse: () => _nearbyPlaces[0],
                      );
                      _focusOnPlace(place);
                    }
                  },
                  child: Container(
                    margin: const EdgeInsets.only(left: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: isSelected ? navyDark : Colors.white.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      cat,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                        color: isSelected ? gold : navyDark,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  void _filterAndSelectPlace(String query) {
    if (query.trim().isEmpty) return;
    for (final p in _nearbyPlaces) {
      if ((p['name'] as String).contains(query) ||
          (p['enName'] as String).toLowerCase().contains(query.toLowerCase())) {
        _focusOnPlace(p);
        break;
      }
    }
  }

  // ══════════════════════════════════════
  // أزرار التحكم بالخريطة (Zoom & Location)
  // ══════════════════════════════════════
  Widget _buildMapControls() {
    return Positioned(
      top: 120,
      left: 16,
      child: Column(
        children: [
          // زر التكبير
          _buildCircleButton(
            icon: Icons.add_rounded,
            onTap: () {
              _mapController.move(
                _mapController.camera.center,
                _mapController.camera.zoom + 1,
              );
            },
          ),
          const SizedBox(height: 8),
          // زر التصغير
          _buildCircleButton(
            icon: Icons.remove_rounded,
            onTap: () {
              _mapController.move(
                _mapController.camera.center,
                _mapController.camera.zoom - 1,
              );
            },
          ),
          const SizedBox(height: 8),
          // زر العودة لموقع الكلية
          _buildCircleButton(
            icon: Icons.my_location_rounded,
            iconColor: gold,
            onTap: _recenterCollege,
          ),
        ],
      ),
    );
  }

  Widget _buildCircleButton({
    required IconData icon,
    required VoidCallback onTap,
    Color iconColor = navyDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
    );
  }

  // ══════════════════════════════════════
  // البطاقة السفلية العائمة التفاعلية
  // ══════════════════════════════════════
  Widget _buildFloatingDetailsCard() {
    final place = _selectedPlace ?? _nearbyPlaces[0];

    return Positioned(
      bottom: 78,
      left: 16,
      right: 16,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // السطر العلوي للمكان
            Row(
              children: [
                // مربع الأيقونة المميز
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: navyDark,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    place['icon'] as IconData,
                    color: gold,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        place['name'] as String,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: navyDark,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        place['description'] as String,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: textGray,
                        ),
                      ),
                    ],
                  ),
                ),
                // زر تصغير / تكبير البطاقة
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: Icon(
                    _isCardExpanded
                        ? Icons.keyboard_arrow_down_rounded
                        : Icons.keyboard_arrow_up_rounded,
                    color: textGray,
                  ),
                  onPressed: () {
                    setState(() {
                      _isCardExpanded = !_isCardExpanded;
                    });
                  },
                ),
              ],
            ),

            if (_isCardExpanded) ...[
              // عرض نتيجة حساب المسافة الحقيقية
              if (_showRoute) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F5FA),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFDDE6F0)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildInfoItem(
                        icon: Icons.straighten_rounded,
                        title: 'المسافة',
                        value: '$_distanceKm كم',
                      ),
                      Container(width: 1, height: 24, color: const Color(0xFFCFDCE8)),
                      _buildInfoItem(
                        icon: Icons.directions_car_rounded,
                        title: 'بالسيارة',
                        value: '$_carMinutes دقيقة',
                      ),
                      Container(width: 1, height: 24, color: const Color(0xFFCFDCE8)),
                      _buildInfoItem(
                        icon: Icons.directions_walk_rounded,
                        title: 'مشياً',
                        value: '$_walkMinutes دقيقة',
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 12),

              // الأزرار التفاعلية الداخلية
              Row(
                children: [
                  // زر تحديد المسافة المباشر
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isCalculating ? null : _calculateDistance,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: navyDark,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 10),
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
                              Icons.near_me_rounded,
                              color: gold,
                              size: 18,
                            ),
                      label: Text(
                        _showRoute ? 'تحديث المسافة' : 'تحديد المسافة',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 10),

                  // زر استعراض الأماكن المجاورة
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        _showNearbyPlacesSheet();
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: navyDark,
                        side: const BorderSide(color: navyDark, width: 1.4),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(
                        Icons.explore_rounded,
                        color: navyDark,
                        size: 18,
                      ),
                      label: const Text(
                        'الأماكن المجاورة',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: navyDark),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 9, color: textGray),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: navyDark,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // نافذة سريعة لاستعراض جميع الأماكن المحيطة بالكلية
  void _showNearbyPlacesSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'الأماكن والمعالم بجوار الكلية',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: navyDark,
                ),
              ),
              const SizedBox(height: 12),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _nearbyPlaces.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final p = _nearbyPlaces[i];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor: (p['color'] as Color).withValues(alpha: 0.15),
                        child: Icon(p['icon'] as IconData, color: p['color'] as Color),
                      ),
                      title: Text(
                        p['name'] as String,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: navyDark,
                        ),
                      ),
                      subtitle: Text(
                        p['description'] as String,
                        style: const TextStyle(fontSize: 11, color: textGray),
                      ),
                      trailing: const Icon(
                        Icons.chevron_left_rounded,
                        color: textGray,
                      ),
                      onTap: () {
                        Navigator.pop(ctx);
                        _focusOnPlace(p);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ══════════════════════════════════════
  // شريط التنقل السفلي المطابق للواجهة المطلوبة
  // ══════════════════════════════════════
  Widget _buildBottomNav() {
    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(Icons.person_outline_rounded, () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const ProfileScreen()),
            );
          }),
          _buildNavItem(Icons.calendar_today_outlined, () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const CalendarScreen()),
            );
          }),
          // تبويب الموقع نشط بدائرة مميزة مع أيقونة كحلية بارزة
          _buildNavItem(
            Icons.location_on_rounded,
            () {},
            isActive: true,
          ),
          _buildNavItem(Icons.home_outlined, () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const HomeScreen()),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, VoidCallback onTap, {bool isActive = false}) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFEFF4F9) : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 24,
          color: isActive ? navyDark : const Color(0xFFA0A5AE),
        ),
      ),
    );
  }
}
