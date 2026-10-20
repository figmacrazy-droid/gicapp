import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:gic/services/permission_service.dart';
import 'package:gic/services/supabase_service.dart';
import '../services/fcm_sender_service.dart';

class AdsView extends StatefulWidget {
  final Function(String path) onPathChanged;

  const AdsView({
    Key? key,
    required this.onPathChanged,
  }) : super(key: key);

  @override
  State<AdsView> createState() => _AdsViewState();
}

class _AdsViewState extends State<AdsView> {
  static const Color primaryNavy = Color(0xFF0E1B4D);
  static const Color calendarBg = Color(0xFF0B1736);
  static const Color accentGold = Color(0xFFC5A059);

  String activeSubTab = 'البنر الإعلاني';
  bool sendNotification = false;

  // البنرات الإعلانية
  int selectedBannerIndex = 0;
  bool isLoadingBanners = false;
  List<Map<String, dynamic>> bannersData = [];

  // التخصصات
  int selectedSpecialtyIndex = 0;
  bool isLoadingSpecialties = false;
  List<Map<String, dynamic>> specialtiesData = [];

  // التقويم السنوي
  DateTime currentDate = DateTime.now();
  int? selectedDay;
  List<int> eventDays = [];

  // إنجازاتنا
  int selectedAchievementIndex = 0;
  bool isLoadingAchievements = false;
  List<Map<String, dynamic>> achievementsData = [];

  // خريجي الغد
  int selectedAlumniIndex = 0;
  bool isLoadingAlumni = false;
  List<Map<String, dynamic>> alumniData = [];

  final List<String> monthsNames = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];

  @override
  void initState() {
    super.initState();
    selectedDay = currentDate.day;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onPathChanged('الإعلانات > $activeSubTab');
      _loadAllAdsData();
    });
  }

  Future<void> _loadAllAdsData() async {
    await Future.wait([
      _loadBannersFromSupabase(),
      _loadSpecialtiesFromSupabase(),
      _loadEventsFromSupabase(),
      _loadAchievementsFromSupabase(),
      _loadAlumniFromSupabase(),
    ]);
  }

  // ══════════════════════════════════════════════════════════════
  // 1. إدارة البنرات الإعلانية في Supabase (3 بنرات ثابتة قابلة للاستبدال)
  // ══════════════════════════════════════════════════════════════
  Future<void> _loadBannersFromSupabase() async {
    setState(() => isLoadingBanners = true);
    try {
      // 1. محاولة جلب البنرات من system_instructions (خدمة ad_banners المعتمدة)
      final res = await AdminSupabase.client
          .from('system_instructions')
          .select()
          .eq('service_key', 'ad_banners')
          .maybeSingle();

      List<Map<String, dynamic>> loaded = [];
      if (res != null && res['steps'] != null) {
        final decoded = jsonDecode(res['steps'] as String);
        if (decoded is List) {
          loaded = decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        }
      }

      // 2. إذا كانت فارغة، جلب من جدول ad_banners مباشرة
      if (loaded.isEmpty) {
        final adBannersRes = await AdminSupabase.client
            .from('ad_banners')
            .select()
            .order('display_order', ascending: true);
        if (adBannersRes is List && adBannersRes.isNotEmpty) {
          loaded = (adBannersRes as List)
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();
        }
      }

      // فرز حسب display_order
      loaded.sort((a, b) => ((a['display_order'] ?? 0) as int).compareTo((b['display_order'] ?? 0) as int));

      // 3. ضمان وجود 3 بنرات ثابتة فقط (البنر الأول، البنر الثاني، البنر الثالث)
      final defaultTitles = [
        'إعلان بدء التنسيق والقبول للعام الجديد',
        'افتتاح قسم الصيدلة السريرية المتطور',
        'تجهيز معمل التشخيص الميكروبيولوجي',
      ];
      while (loaded.length < 3) {
        final order = loaded.length + 1;
        loaded.add({
          'id': 'banner_$order',
          'title': defaultTitles[order - 1],
          'image_url': 'assets/images/$order.jpg',
          'display_order': order,
          'is_active': true,
        });
      }

      // أخذ 3 بنرات فقط بدقة
      final final3 = loaded.take(3).toList();
      for (int i = 0; i < final3.length; i++) {
        final3[i]['display_order'] = i + 1;
      }

      if (mounted) {
        setState(() {
          bannersData = final3;
          if (selectedBannerIndex >= bannersData.length) {
            selectedBannerIndex = 0;
          }
          isLoadingBanners = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading banners: $e');
      if (mounted) setState(() => isLoadingBanners = false);
    }
  }

  Future<void> _saveBannersToSupabase() async {
    try {
      final final3 = bannersData.take(3).toList();
      for (int i = 0; i < final3.length; i++) {
        final3[i]['display_order'] = i + 1;
      }

      final jsonStr = jsonEncode(final3);
      await AdminSupabase.client.from('system_instructions').upsert({
        'service_key': 'ad_banners',
        'title': 'قائمة البنرات الإعلانية المعتمدة (3 بنرات)',
        'steps': jsonStr,
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'service_key');

      // مزامنة فورية مع جدول ad_banners لكل بنر من الـ 3
      try {
        for (int i = 0; i < final3.length; i++) {
          final b = final3[i];
          final img = (b['image_url'] ?? '').toString();
          if (img.isNotEmpty) {
            await AdminSupabase.client.from('ad_banners').update({
              'title': b['title'] ?? 'إعلان',
              'image_url': img,
              'is_active': true,
            }).eq('display_order', i + 1);
          }
        }
      } catch (innerE) {
        debugPrint('ad_banners direct table sync note: $innerE');
      }
    } catch (e) {
      debugPrint('Error saving banners: $e');
    }
  }

  // ══════════════════════════════════════════════════════════════
  // 2. إدارة التخصصات ورابط اليوتيوب في Supabase
  // ══════════════════════════════════════════════════════════════
  Future<void> _loadSpecialtiesFromSupabase() async {
    setState(() => isLoadingSpecialties = true);
    try {
      final res = await AdminSupabase.client
          .from('specialties')
          .select()
          .order('display_order', ascending: true);

      final List list = res as List;
      final loaded = list.map((e) {
        final m = Map<String, dynamic>.from(e as Map);
        // استخراج رابط يوتيوب المخزن
        String loc = m['location']?.toString() ?? 'صنعاء - دارس';
        String yt = '';
        if (loc.contains('|')) {
          final parts = loc.split('|');
          loc = parts[0];
          yt = parts.sublist(1).join('|');
        } else if (loc.startsWith('http')) {
          yt = loc;
          loc = 'صنعاء - دارس';
        }
        m['parsed_location'] = loc;
        m['youtube_url'] = yt;
        return m;
      }).toList();

      if (mounted) {
        setState(() {
          specialtiesData = loaded;
          if (selectedSpecialtyIndex >= specialtiesData.length) {
            selectedSpecialtyIndex = specialtiesData.isNotEmpty ? 0 : 0;
          }
          isLoadingSpecialties = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading specialties: $e');
      if (mounted) setState(() => isLoadingSpecialties = false);
    }
  }

  // ══════════════════════════════════════════════════════════════
  // 3. التقويم السنوي
  // ══════════════════════════════════════════════════════════════
  Future<void> _loadEventsFromSupabase() async {
    try {
      final res = await AdminSupabase.client
          .from('calendar_events')
          .select('event_date');
      final List list = res as List;
      final Set<int> days = {};
      for (var item in list) {
        final dateStr = item['event_date']?.toString();
        if (dateStr != null) {
          final dt = DateTime.tryParse(dateStr);
          if (dt != null && dt.year == currentDate.year && dt.month == currentDate.month) {
            days.add(dt.day);
          }
        }
      }
      if (mounted) {
        setState(() {
          eventDays = days.toList();
        });
      }
    } catch (e) {
      debugPrint('Error loading calendar events: $e');
    }
  }

  void _nextMonth() {
    setState(() {
      currentDate = DateTime(currentDate.year, currentDate.month + 1, 1);
      selectedDay = null;
    });
    _loadEventsFromSupabase();
  }

  void _previousMonth() {
    setState(() {
      currentDate = DateTime(currentDate.year, currentDate.month - 1, 1);
      selectedDay = null;
    });
    _loadEventsFromSupabase();
  }

  // ══════════════════════════════════════════════════════════════
  // 4. إدارة إنجازاتنا في Supabase
  // ══════════════════════════════════════════════════════════════
  Future<void> _loadAchievementsFromSupabase() async {
    setState(() => isLoadingAchievements = true);
    try {
      final res = await AdminSupabase.client
          .from('system_instructions')
          .select()
          .eq('service_key', 'achievements')
          .maybeSingle();

      List<Map<String, dynamic>> loaded = [];
      if (res != null && res['steps'] != null) {
        final decoded = jsonDecode(res['steps'] as String);
        if (decoded is List) {
          loaded = decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        }
      }

      if (loaded.isEmpty) {
        final directRes = await AdminSupabase.client
            .from('achievements')
            .select()
            .order('created_at', ascending: false);
        if (directRes is List && directRes.isNotEmpty) {
          loaded = (directRes as List)
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();
        }
      }

      if (mounted) {
        setState(() {
          achievementsData = loaded;
          if (selectedAchievementIndex >= achievementsData.length) {
            selectedAchievementIndex = achievementsData.isNotEmpty ? 0 : 0;
          }
          isLoadingAchievements = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading achievements: $e');
      if (mounted) setState(() => isLoadingAchievements = false);
    }
  }

  Future<void> _saveAchievementsToSupabase() async {
    try {
      final jsonStr = jsonEncode(achievementsData);
      await AdminSupabase.client.from('system_instructions').upsert({
        'service_key': 'achievements',
        'title': 'إنجازاتنا',
        'steps': jsonStr,
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'service_key');
    } catch (e) {
      debugPrint('Error saving achievements: $e');
      rethrow;
    }
  }

  // ══════════════════════════════════════════════════════════════
  // 5. إدارة خريجي الغد في Supabase
  // ══════════════════════════════════════════════════════════════
  Future<void> _loadAlumniFromSupabase() async {
    setState(() => isLoadingAlumni = true);
    try {
      final res = await AdminSupabase.client
          .from('system_instructions')
          .select()
          .eq('service_key', 'alumni_batches')
          .maybeSingle();

      List<Map<String, dynamic>> loaded = [];
      if (res != null && res['steps'] != null) {
        final decoded = jsonDecode(res['steps'] as String);
        if (decoded is List) {
          loaded = decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        }
      }

      if (loaded.isEmpty) {
        final directRes = await AdminSupabase.client
            .from('alumni_batches')
            .select()
            .order('created_at', ascending: false);
        if (directRes is List && directRes.isNotEmpty) {
          loaded = (directRes as List)
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();
        }
      }

      if (mounted) {
        setState(() {
          alumniData = loaded;
          if (selectedAlumniIndex >= alumniData.length) {
            selectedAlumniIndex = alumniData.isNotEmpty ? 0 : 0;
          }
          isLoadingAlumni = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading alumni batches: $e');
      if (mounted) setState(() => isLoadingAlumni = false);
    }
  }

  Future<void> _saveAlumniToSupabase() async {
    try {
      final jsonStr = jsonEncode(alumniData);
      await AdminSupabase.client.from('system_instructions').upsert({
        'service_key': 'alumni_batches',
        'title': 'خريجي الغد',
        'steps': jsonStr,
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'service_key');
    } catch (e) {
      debugPrint('Error saving alumni batches: $e');
      rethrow;
    }
  }

  bool _canAds(PermissionAction action) {
    return PermissionService.can('advertisements', 'ads_management', action) ||
        PermissionService.can('services', 'banners_achieve', action);
  }

  void _showNotification(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: isError ? Colors.red.shade800 : Colors.green.shade800,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  // بناء واجهة المستخدم
  // ══════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // القائمة الجانبية للتبويبات
                  SizedBox(
                    width: 180,
                    child: Column(
                      children: [
                        _buildSubTabButton('البنر الإعلاني', Icons.view_carousel),
                        const SizedBox(height: 10),
                        _buildSubTabButton('التقويم السنوي', Icons.calendar_month),
                        const SizedBox(height: 10),
                        _buildSubTabButton('التخصصات', Icons.school),
                        const SizedBox(height: 10),
                        _buildSubTabButton('إنجازاتنا', Icons.military_tech_rounded),
                        const SizedBox(height: 10),
                        _buildSubTabButton('خريجي الغد', Icons.workspace_premium_rounded),
                      ],
                    ),
                  ),

                  const SizedBox(width: 20),

                  // المحتوى الديناميكي
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF4F6F9),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.black12),
                      ),
                      child: _buildDynamicContent(),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // شريط المسار السفلي
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
            color: const Color(0xFFDCDCDC),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.location_on_outlined, size: 18, color: primaryNavy),
                const SizedBox(width: 8),
                Text(
                  'المسار: الإعلانات > $activeSubTab',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: primaryNavy,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDynamicContent() {
    if (activeSubTab == 'البنر الإعلاني') {
      return _buildBannersView();
    } else if (activeSubTab == 'التقويم السنوي') {
      return _buildCalendarView();
    } else if (activeSubTab == 'إنجازاتنا') {
      return _buildAchievementsView();
    } else if (activeSubTab == 'خريجي الغد') {
      return _buildAlumniView();
    } else {
      return _buildSpecialtiesView();
    }
  }

  // ══════════════════════════════════════════════════════════════
  // عرض قسم البنر الإعلاني
  // ══════════════════════════════════════════════════════════════
  Widget _buildBannersView() {
    if (isLoadingBanners) {
      return const Center(child: CircularProgressIndicator(color: accentGold));
    }

    if (bannersData.isEmpty) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.image_not_supported_outlined, size: 60, color: Colors.grey),
          const SizedBox(height: 16),
          const Text('لا توجد بنرات إعلانية حالياً في قاعدة البيانات', style: TextStyle(fontSize: 16, color: Colors.grey)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showAddBannerDialog(context),
            icon: const Icon(Icons.add_photo_alternate, color: Colors.white),
            label: const Text('إضافة بنر جديد', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(backgroundColor: accentGold, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12)),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'البنرات الإعلانية المعتمدة (${bannersData.length} بنرات)',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryNavy),
            ),
            IconButton(
              icon: const Icon(Icons.refresh, color: primaryNavy),
              tooltip: 'تحديث من السحابة',
              onPressed: _loadBannersFromSupabase,
            ),
          ],
        ),
        const SizedBox(height: 16),

        // عرض البنرات بالمقاسات المعتمدة لتطبيق الطالب (العرض 222 والارتفاع 278)
        Expanded(
          child: Center(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: bannersData.asMap().entries.map((entry) {
                  final index = entry.key;
                  final banner = entry.value;
                  final isSelected = selectedBannerIndex == index;

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10.0),
                    child: InkWell(
                      onTap: () => setState(() => selectedBannerIndex = index),
                      borderRadius: BorderRadius.circular(14),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 222, // مقاس كرت الطالب الدقيق
                        height: 278, // مقاس كرت الطالب الدقيق
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected ? accentGold : Colors.grey.shade300,
                            width: isSelected ? 3 : 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: isSelected ? accentGold.withOpacity(0.3) : Colors.black.withOpacity(0.08),
                              blurRadius: isSelected ? 12 : 6,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(11),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              _buildImageWidget(banner['image_url']?.toString() ?? ''),
                              // طبقة تظليل سفلية للنص
                              Positioned(
                                bottom: 0,
                                left: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.bottomCenter,
                                      end: Alignment.topCenter,
                                      colors: [
                                        Colors.black.withOpacity(0.85),
                                        Colors.transparent,
                                      ],
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        banner['title'] ?? 'بنر إعلاني',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'ترتيب العرض: ${banner['display_order'] ?? (index + 1)}',
                                            style: const TextStyle(color: Colors.white70, fontSize: 11),
                                          ),
                                          if (isSelected)
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: accentGold,
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: const Text('محدد', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
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
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
        const SizedBox(height: 15),

        // نقاط التنقل
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(bannersData.length, (index) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: selectedBannerIndex == index ? accentGold : Colors.grey.shade400,
                shape: BoxShape.circle,
              ),
            );
          }),
        ),
        const SizedBox(height: 20),

        // أزرار التحكم بالبنرات الـ 3 المعتمدة (استبدال / تعديل، وإعادة تعيين للافتراضي)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Checkbox(
                  value: sendNotification,
                  activeColor: primaryNavy,
                  onChanged: (val) => setState(() => sendNotification = val ?? false),
                ),
                const Text(
                  'هل تريد النشر وإيصال إشعار للطلاب ؟',
                  style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: Colors.black87),
                ),
              ],
            ),
            Row(
              children: [
                _buildActionButton(
                  'إعادة تعيين للافتراضي',
                  Icons.restore,
                  Colors.grey.shade700,
                  () => _resetBannerToDefault(selectedBannerIndex),
                ),
                const SizedBox(width: 12),
                _buildActionButton(
                  'استبدال / تعديل البنر المحدد (${selectedBannerIndex + 1})',
                  Icons.swap_horiz,
                  accentGold,
                  bannersData.isNotEmpty ? () => _showEditBannerDialog(context, bannersData[selectedBannerIndex]) : () {},
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════
  // عرض قسم التخصصات ورابط يوتيوب
  // ══════════════════════════════════════════════════════════════
  Widget _buildSpecialtiesView() {
    if (isLoadingSpecialties) {
      return const Center(child: CircularProgressIndicator(color: accentGold));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'التخصصات الأكاديمية وربط استكشاف يوتيوب (${specialtiesData.length} تخصص)',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryNavy),
            ),
            IconButton(
              icon: const Icon(Icons.refresh, color: primaryNavy),
              tooltip: 'تحديث من السحابة',
              onPressed: _loadSpecialtiesFromSupabase,
            ),
          ],
        ),
        const SizedBox(height: 14),

        // شبكة التخصصات
        Expanded(
          child: specialtiesData.isEmpty
              ? const Center(child: Text('لا توجد تخصصات مسجلة', style: TextStyle(color: Colors.grey)))
              : GridView.builder(
                  itemCount: specialtiesData.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    childAspectRatio: 1.6,
                  ),
                  itemBuilder: (context, index) {
                    final spec = specialtiesData[index];
                    final isSelected = selectedSpecialtyIndex == index;
                    final hasYoutube = (spec['youtube_url'] ?? '').toString().isNotEmpty;

                    return InkWell(
                      onTap: () => setState(() => selectedSpecialtyIndex = index),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? accentGold : Colors.grey.shade300,
                            width: isSelected ? 2.5 : 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: isSelected ? accentGold.withOpacity(0.2) : Colors.black.withOpacity(0.04),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            // صورة التخصص
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: SizedBox(
                                width: 70,
                                height: 70,
                                child: _buildImageWidget(spec['image_url']?.toString() ?? ''),
                              ),
                            ),
                            const SizedBox(width: 12),

                            // تفاصيل التخصص
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    '${spec['degree_type'] ?? 'بكالوريوس'} ${spec['title'] ?? ''}',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: primaryNavy,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      const Icon(Icons.location_on, size: 12, color: Colors.grey),
                                      const SizedBox(width: 2),
                                      Text(
                                        spec['parsed_location'] ?? 'صنعاء - دارس',
                                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        '(${spec['visits_count'] ?? 1000} زيارة)',
                                        style: const TextStyle(fontSize: 10, color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  // شارة رابط اليوتيوب
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: hasYoutube ? Colors.red.shade50 : Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(
                                        color: hasYoutube ? Colors.red.shade300 : Colors.grey.shade300,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.play_circle_filled,
                                          size: 13,
                                          color: hasYoutube ? Colors.red : Colors.grey,
                                        ),
                                        const SizedBox(width: 4),
                                        Flexible(
                                          child: Text(
                                            hasYoutube ? 'فيديو يوتيوب مرتبط' : 'لا يوجد رابط فيديو',
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: hasYoutube ? Colors.red.shade800 : Colors.grey.shade700,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
        const SizedBox(height: 20),

        // أزرار التحكم بالتخصص
        _buildBottomControls(
          addLabel: 'إضافة تخصص',
          onAddPressed: () => _showAddSpecialtyDialog(context),
          onEditPressed: specialtiesData.isNotEmpty ? () => _showEditSpecialtyDialog(context, specialtiesData[selectedSpecialtyIndex]) : () {},
          onDeletePressed: specialtiesData.isNotEmpty ? () => _deleteSpecialty(selectedSpecialtyIndex) : () {},
          showAddButton: true,
          showNotificationCheckbox: true,
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════
  // دوال الحذف والتعديل والإضافة للبنر
  // ══════════════════════════════════════════════════════════════
  Future<void> _deleteBanner(int index) async {
    if (!_canAds(PermissionAction.delete)) {
      _showNotification('⚠️ عذراً، حسابك لا يملك صلاحية الحذف في قسم الإعلانات.', isError: true);
      return;
    }
    if (index < 0 || index >= bannersData.length) return;
    final banner = bannersData[index];

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تأكيد حذف البنر'),
        content: Text('هل أنت متأكد من حذف البنر "${banner['title']}" نهائياً من قاعدة البيانات والتطبيق؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('نعم، حذف', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      setState(() {
        bannersData.removeAt(index);
        if (selectedBannerIndex >= bannersData.length && bannersData.isNotEmpty) {
          selectedBannerIndex = bannersData.length - 1;
        }
      });
      await _saveBannersToSupabase();
      _showNotification('تم حذف البنر بنجاح');
    } catch (e) {
      _showNotification('فشل حذف البنر: $e', isError: true);
    }
  }

  void _showAddBannerDialog(BuildContext context) {
    if (!_canAds(PermissionAction.create)) {
      _showNotification('⚠️ عذراً، حسابك لا يملك صلاحية الإضافة في قسم الإعلانات.', isError: true);
      return;
    }
    final titleCtrl = TextEditingController();
    String currentImageUrl = 'assets/images/1.jpg';
    String? selectedFileName;
    final orderCtrl = TextEditingController(text: '${bannersData.length + 1}');

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          title: const Text('إضافة بنر إعلاني جديد', style: TextStyle(color: primaryNavy, fontWeight: FontWeight.bold)),
          content: SizedBox(
            width: 460,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(
                    labelText: 'عنوان البنر الإعلاني *',
                    hintText: 'مثال: بدء التسجيل للعام الجامعي الجديد',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 14),
                _buildDeviceImagePicker(
                  context: context,
                  currentImageUrl: currentImageUrl,
                  selectedFileName: selectedFileName,
                  onImagePicked: (newUrl, fName) {
                    setDlgState(() {
                      currentImageUrl = newUrl;
                      selectedFileName = fName;
                    });
                  },
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: orderCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'ترتيب العرض',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'ملاحظة: تظهر البنرات في تطبيق الطالب بنسبة الأبعاد القياسية (222 × 278)',
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: accentGold),
              onPressed: () async {
                final title = titleCtrl.text.trim();
                final img = currentImageUrl.trim();
                final order = int.tryParse(orderCtrl.text.trim()) ?? (bannersData.length + 1);

                if (title.isEmpty || img.isEmpty) {
                  _showNotification('يرجى إدخال العنوان واختيار صورة البنر', isError: true);
                  return;
                }

                Navigator.pop(ctx);
                final newBanner = {
                  'id': 'banner_${DateTime.now().millisecondsSinceEpoch}',
                  'title': title,
                  'image_url': img,
                  'display_order': order,
                  'is_active': true,
                };

                setState(() {
                  bannersData.add(newBanner);
                  bannersData.sort((a, b) => ((a['display_order'] ?? 0) as int).compareTo((b['display_order'] ?? 0) as int));
                  selectedBannerIndex = bannersData.indexOf(newBanner);
                });

                await _saveBannersToSupabase();

                // إرسال إشعار للطلاب إذا كان الخيار محدداً
                if (sendNotification) {
                  try {
                    await AdminSupabase.client.from('notifications').insert({
                      'academic_id': null,
                      'title': 'إعلان جديد: $title',
                      'body': 'تم نشر إعلان جديد في التطبيق: $title',
                      'notification_type': 'general',
                      'route_name': 'home',
                      'is_read': false,
                    });
                  } catch (_) {}
                }

                _showNotification('تمت إضافة البنر الإعلاني بنجاح وحفظه في السحابة!');
              },
              child: const Text('حفظ ونشر', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _resetBannerToDefault(int index) async {
    if (!_canAds(PermissionAction.delete)) {
      _showNotification('⚠️ عذراً، حسابك لا يملك صلاحية الحذف في قسم الإعلانات.', isError: true);
      return;
    }
    if (index < 0 || index >= bannersData.length) return;
    final defaultTitles = [
      'إعلان بدء التنسيق والقبول للعام الجديد',
      'افتتاح قسم الصيدلة السريرية المتطور',
      'تجهيز معمل التشخيص الميكروبيولوجي',
    ];
    setState(() {
      bannersData[index]['title'] = defaultTitles[index];
      bannersData[index]['image_url'] = 'assets/images/${index + 1}.jpg';
      bannersData[index]['display_order'] = index + 1;
    });
    await _saveBannersToSupabase();
    _showNotification('تمت إعادة تعيين البنر (${index + 1}) للافتراضي بنجاح');
  }

  void _showEditBannerDialog(BuildContext context, Map<String, dynamic> banner) {
    if (!_canAds(PermissionAction.update)) {
      _showNotification('⚠️ عذراً، حسابك لا يملك صلاحية التعديل في قسم الإعلانات.', isError: true);
      return;
    }
    final titleCtrl = TextEditingController(text: banner['title']);
    String currentImageUrl = banner['image_url'] ?? '';
    String? selectedFileName;
    final slotNumber = (banner['display_order'] ?? (bannersData.indexOf(banner) + 1));

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.swap_horiz, color: accentGold),
              const SizedBox(width: 8),
              Text('استبدال وتعديل البنر (البنر رقم $slotNumber)', style: const TextStyle(color: primaryNavy, fontWeight: FontWeight.bold)),
            ],
          ),
          content: SizedBox(
            width: 480,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: titleCtrl,
                    decoration: const InputDecoration(
                      labelText: 'عنوان البنر الإعلاني *',
                      hintText: 'مثال: فتح باب التسجيل للفصل الدراسي القادم',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _buildDeviceImagePicker(
                    context: context,
                    currentImageUrl: currentImageUrl,
                    selectedFileName: selectedFileName,
                    onImagePicked: (newUrl, fName) {
                      setDlgState(() {
                        currentImageUrl = newUrl;
                        selectedFileName = fName;
                      });
                    },
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'ملاحظة: يتم حفظ البنر ومزامنته فوراً مع تطبيق الطالب في المساحة المخصصة للـ 3 بنرات.',
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: accentGold),
              onPressed: () async {
                final title = titleCtrl.text.trim();
                final img = currentImageUrl.trim();

                if (title.isEmpty || img.isEmpty) {
                  _showNotification('يرجى كتابة عنوان البنر واختيار صورته', isError: true);
                  return;
                }

                Navigator.pop(ctx);
                setState(() {
                  banner['title'] = title;
                  banner['image_url'] = img;
                  banner['is_active'] = true;
                });

                await _saveBannersToSupabase();

                // إرسال إشعار للطلاب إذا كان الخيار محدداً
                if (sendNotification) {
                  try {
                    await AdminSupabase.client.from('notifications').insert({
                      'academic_id': null,
                      'title': 'إعلان جديد: $title',
                      'body': 'تم تحديث الإعلانات في التطبيق: $title',
                      'notification_type': 'general',
                      'route_name': 'home',
                      'is_read': false,
                    });
                    FcmSenderService.sendToTopic(
                      topic: 'all_students',
                      title: 'إعلان جديد: $title',
                      body: 'تم تحديث الإعلانات في التطبيق: $title',
                      routeName: 'home',
                    );
                  } catch (_) {}
                }

                _showNotification('تم استبدال وحفظ البنر رقم $slotNumber بنجاح ومزامنته مع التطبيق!');
              },
              child: const Text('حفظ واستبدال البنر', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  // دوال الحذف والتعديل والإضافة للتخصص ورابط اليوتيوب
  // ══════════════════════════════════════════════════════════════
  Future<void> _deleteSpecialty(int index) async {
    if (!_canAds(PermissionAction.delete)) {
      _showNotification('⚠️ عذراً، حسابك لا يملك صلاحية الحذف في قسم الإعلانات.', isError: true);
      return;
    }
    if (index < 0 || index >= specialtiesData.length) return;
    final spec = specialtiesData[index];

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تأكيد حذف التخصص'),
        content: Text('هل أنت متأكد من حذف تخصص "${spec['title']}" نهائياً من قاعدة البيانات وتطبيق الطلاب؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('نعم، حذف', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      if (spec['id'] != null) {
        await AdminSupabase.client.from('specialties').delete().eq('id', spec['id']);
      }
      setState(() {
        specialtiesData.removeAt(index);
        if (selectedSpecialtyIndex >= specialtiesData.length && specialtiesData.isNotEmpty) {
          selectedSpecialtyIndex = specialtiesData.length - 1;
        }
      });
      _showNotification('تم حذف التخصص بنجاح');
    } catch (e) {
      _showNotification('فشل حذف التخصص: $e', isError: true);
    }
  }

  void _showAddSpecialtyDialog(BuildContext context) {
    if (!_canAds(PermissionAction.create)) {
      _showNotification('⚠️ عذراً، حسابك لا يملك صلاحية الإضافة في قسم الإعلانات.', isError: true);
      return;
    }
    final titleCtrl = TextEditingController();
    String degreeType = 'بكالوريوس';
    String currentImageUrl = 'assets/images/specialty_1.png';
    String? selectedFileName;
    final youtubeCtrl = TextEditingController(text: 'https://www.youtube.com/watch?v=dQw4w9WgXcQ');

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          title: const Text('إضافة تخصص جديد وربط فيديو يوتيوب', style: TextStyle(color: primaryNavy, fontWeight: FontWeight.bold)),
          content: SizedBox(
            width: 480,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(labelText: 'اسم التخصص *', hintText: 'مثال: الأمن السيبراني والشبكات', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  value: degreeType,
                  decoration: const InputDecoration(labelText: 'الدرجة العلمية', border: OutlineInputBorder()),
                  items: const [
                    DropdownMenuItem(value: 'بكالوريوس', child: Text('بكالوريوس')),
                    DropdownMenuItem(value: 'تخصص', child: Text('تخصص (دبلوم عالي)')),
                    DropdownMenuItem(value: 'دبلوم', child: Text('دبلوم')),
                  ],
                  onChanged: (v) => setDlgState(() => degreeType = v ?? 'بكالوريوس'),
                ),
                const SizedBox(height: 14),
                _buildDeviceImagePicker(
                  context: context,
                  currentImageUrl: currentImageUrl,
                  selectedFileName: selectedFileName,
                  onImagePicked: (newUrl, fName) {
                    setDlgState(() {
                      currentImageUrl = newUrl;
                      selectedFileName = fName;
                    });
                  },
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: youtubeCtrl,
                  decoration: InputDecoration(
                    labelText: 'رابط فيديو يوتيوب للاستكشاف (YouTube URL) *',
                    hintText: 'https://www.youtube.com/watch?v=...',
                    border: const OutlineInputBorder(),
                    prefixIcon: Icon(Icons.video_library, color: Colors.red.shade700),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: accentGold),
              onPressed: () async {
                final title = titleCtrl.text.trim();
                final img = currentImageUrl.trim();
                final yt = youtubeCtrl.text.trim();

                if (title.isEmpty) {
                  _showNotification('يرجى إدخال اسم التخصص', isError: true);
                  return;
                }

                Navigator.pop(ctx);
                try {
                  final combinedLocation = 'صنعاء - دارس|$yt';
                  final insertRes = await AdminSupabase.client.from('specialties').insert({
                    'title': title,
                    'degree_type': degreeType,
                    'image_url': img.isEmpty ? 'assets/images/specialty_1.png' : img,
                    'location': combinedLocation,
                    'visits_count': 1200,
                    'display_order': specialtiesData.length + 1,
                  }).select().single();

                  final newMap = Map<String, dynamic>.from(insertRes as Map);
                  newMap['parsed_location'] = 'صنعاء - دارس';
                  newMap['youtube_url'] = yt;

                  setState(() {
                    specialtiesData.add(newMap);
                    selectedSpecialtyIndex = specialtiesData.length - 1;
                  });

                  if (sendNotification) {
                    try {
                      await AdminSupabase.client.from('notifications').insert({
                        'academic_id': null,
                        'title': 'تخصص أكاديمي جديد: $degreeType $title',
                        'body': 'تمت إضافة تخصص ($degreeType $title) إلى برامج الكلية. يمكنك استكشافه ومشاهدة الفيديو التعريفي الآن!',
                        'notification_type': 'general',
                        'route_name': 'home',
                        'is_read': false,
                      });
                      FcmSenderService.sendToTopic(
                        topic: 'all_students',
                        title: 'تخصص أكاديمي جديد: $degreeType $title',
                        body: 'تمت إضافة تخصص ($degreeType $title) إلى برامج الكلية. يمكنك استكشافه ومشاهدة الفيديو التعريفي الآن!',
                        routeName: 'home',
                      );
                    } catch (_) {}
                  }

                  _showNotification('تمت إضافة التخصص ورابط اليوتيوب بنجاح!');
                } catch (e) {
                  _showNotification('فشل إضافة التخصص: $e', isError: true);
                }
              },
              child: const Text('إضافة التخصص', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditSpecialtyDialog(BuildContext context, Map<String, dynamic> spec) {
    if (!_canAds(PermissionAction.update)) {
      _showNotification('⚠️ عذراً، حسابك لا يملك صلاحية التعديل في قسم الإعلانات.', isError: true);
      return;
    }
    final titleCtrl = TextEditingController(text: spec['title']);
    String degreeType = spec['degree_type'] ?? 'بكالوريوس';
    String currentImageUrl = spec['image_url'] ?? '';
    String? selectedFileName;
    final youtubeCtrl = TextEditingController(text: spec['youtube_url'] ?? '');

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          title: const Text('تعديل التخصص ورابط استكشاف يوتيوب', style: TextStyle(color: primaryNavy, fontWeight: FontWeight.bold)),
          content: SizedBox(
            width: 480,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(labelText: 'اسم التخصص', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  value: degreeType,
                  decoration: const InputDecoration(labelText: 'الدرجة العلمية', border: OutlineInputBorder()),
                  items: const [
                    DropdownMenuItem(value: 'بكالوريوس', child: Text('بكالوريوس')),
                    DropdownMenuItem(value: 'تخصص', child: Text('تخصص (دبلوم عالي)')),
                    DropdownMenuItem(value: 'دبلوم', child: Text('دبلوم')),
                  ],
                  onChanged: (v) => setDlgState(() => degreeType = v ?? 'بكالوريوس'),
                ),
                const SizedBox(height: 14),
                _buildDeviceImagePicker(
                  context: context,
                  currentImageUrl: currentImageUrl,
                  selectedFileName: selectedFileName,
                  onImagePicked: (newUrl, fName) {
                    setDlgState(() {
                      currentImageUrl = newUrl;
                      selectedFileName = fName;
                    });
                  },
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: youtubeCtrl,
                  decoration: InputDecoration(
                    labelText: 'رابط فيديو يوتيوب للاستكشاف (YouTube URL)',
                    hintText: 'https://www.youtube.com/watch?v=...',
                    border: const OutlineInputBorder(),
                    prefixIcon: Icon(Icons.video_library, color: Colors.red.shade700),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: primaryNavy),
              onPressed: () async {
                final title = titleCtrl.text.trim();
                final img = currentImageUrl.trim();
                final yt = youtubeCtrl.text.trim();

                if (title.isEmpty) {
                  _showNotification('يرجى ملء اسم التخصص', isError: true);
                  return;
                }

                Navigator.pop(ctx);
                try {
                  final loc = spec['parsed_location'] ?? 'صنعاء - دارس';
                  final combinedLocation = '$loc|$yt';

                  if (spec['id'] != null) {
                    await AdminSupabase.client.from('specialties').update({
                      'title': title,
                      'degree_type': degreeType,
                      'image_url': img,
                      'location': combinedLocation,
                    }).eq('id', spec['id']);
                  }

                  setState(() {
                    spec['title'] = title;
                    spec['degree_type'] = degreeType;
                    spec['image_url'] = img;
                    spec['youtube_url'] = yt;
                  });

                  _showNotification('تم تحديث التخصص ورابط فيديو اليوتيوب بنجاح!');
                } catch (e) {
                  _showNotification('فشل التعديل: $e', isError: true);
                }
              },
              child: const Text('حفظ التعديل', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  // عرض قسم إنجازاتنا والتحكم بها
  // ══════════════════════════════════════════════════════════════
  Widget _buildAchievementsView() {
    if (isLoadingAchievements) {
      return const Center(child: CircularProgressIndicator(color: accentGold));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'خدمة إنجازاتنا (${achievementsData.length} إنجاز)',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryNavy),
            ),
            IconButton(
              icon: const Icon(Icons.refresh, color: primaryNavy),
              tooltip: 'تحديث من السحابة',
              onPressed: _loadAchievementsFromSupabase,
            ),
          ],
        ),
        const SizedBox(height: 14),

        Expanded(
          child: achievementsData.isEmpty
              ? const Center(child: Text('لا توجد إنجازات مسجلة حالياً', style: TextStyle(color: Colors.grey)))
              : ListView.builder(
                  itemCount: achievementsData.length,
                  itemBuilder: (context, index) {
                    final item = achievementsData[index];
                    final isSelected = selectedAchievementIndex == index;
                    final hasYoutube = (item['youtube_url'] ?? '').toString().isNotEmpty;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: InkWell(
                        onTap: () => setState(() => selectedAchievementIndex = index),
                        borderRadius: BorderRadius.circular(12),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? accentGold : Colors.grey.shade300,
                              width: isSelected ? 2.5 : 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: isSelected ? accentGold.withOpacity(0.2) : Colors.black.withOpacity(0.04),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: SizedBox(
                                  width: 100,
                                  height: 90,
                                  child: _buildImageWidget(item['image_url']?.toString() ?? ''),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            item['title'] ?? '',
                                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: primaryNavy),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        Text(
                                          item['date_str'] ?? item['date'] ?? '',
                                          style: const TextStyle(fontSize: 11, color: Colors.grey),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      item['description'] ?? '',
                                      style: const TextStyle(fontSize: 12.5, color: Color(0xFF4A4A4A), height: 1.4),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        if (hasYoutube)
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: Colors.red.shade50,
                                              borderRadius: BorderRadius.circular(6),
                                              border: Border.all(color: Colors.red.shade200),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(Icons.play_circle_fill, size: 14, color: Colors.red.shade700),
                                                const SizedBox(width: 4),
                                                Text('فيديو يوتيوب متاح', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.red.shade800)),
                                              ],
                                            ),
                                          )
                                        else
                                          const Text('بدون فيديو', style: TextStyle(fontSize: 11, color: Colors.grey)),
                                        const Spacer(),
                                        if (isSelected)
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: accentGold,
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: const Text('محدد', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                                          ),
                                      ],
                                    ),
                                  ],
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
        const SizedBox(height: 16),

        _buildBottomControls(
          addLabel: 'إضافة إنجاز',
          onAddPressed: () => _showAddAchievementDialog(context),
          onEditPressed: achievementsData.isNotEmpty ? () => _showEditAchievementDialog(context, achievementsData[selectedAchievementIndex]) : () {},
          onDeletePressed: achievementsData.isNotEmpty ? () => _deleteAchievement(selectedAchievementIndex) : () {},
          showAddButton: true,
          showNotificationCheckbox: true,
        ),
      ],
    );
  }

  Future<void> _deleteAchievement(int index) async {
    if (!_canAds(PermissionAction.delete)) {
      _showNotification('⚠️ عذراً، حسابك لا يملك صلاحية الحذف في قسم الإعلانات.', isError: true);
      return;
    }
    if (index < 0 || index >= achievementsData.length) return;
    final item = achievementsData[index];

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تأكيد حذف الإنجاز'),
        content: Text('هل أنت متأكد من حذف إنجاز "${item['title']}"؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('نعم، حذف', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      setState(() {
        achievementsData.removeAt(index);
        if (selectedAchievementIndex >= achievementsData.length && achievementsData.isNotEmpty) {
          selectedAchievementIndex = achievementsData.length - 1;
        }
      });
      await _saveAchievementsToSupabase();
      _showNotification('تم حذف الإنجاز بنجاح');
    } catch (e) {
      _showNotification('فشل حذف الإنجاز: $e', isError: true);
    }
  }

  void _showAddAchievementDialog(BuildContext context) {
    if (!_canAds(PermissionAction.create)) {
      _showNotification('⚠️ عذراً، حسابك لا يملك صلاحية الإضافة في قسم الإعلانات.', isError: true);
      return;
    }
    final titleCtrl = TextEditingController();
    final dateCtrl = TextEditingController(text: '${DateTime.now().day} أكتوبر ${DateTime.now().year}');
    final descCtrl = TextEditingController();
    final ytCtrl = TextEditingController();
    String currentImageUrl = 'assets/images/achievement_1.png';
    String? selectedFileName;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          title: const Text('إضافة إنجاز جديد', style: TextStyle(color: primaryNavy, fontWeight: FontWeight.bold)),
          content: SizedBox(
            width: 480,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleCtrl,
                    decoration: const InputDecoration(labelText: 'اسم / عنوان الإنجاز *', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: dateCtrl,
                    decoration: const InputDecoration(labelText: 'تاريخ الإنجاز', hintText: 'مثال: 15 أكتوبر 2024', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(labelText: 'وصف الإنجاز *', hintText: 'اكتب تفاصيل الإنجاز كاملاً...', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  _buildDeviceImagePicker(
                    context: context,
                    currentImageUrl: currentImageUrl,
                    selectedFileName: selectedFileName,
                    onImagePicked: (newUrl, fName) {
                      setDlgState(() {
                        currentImageUrl = newUrl;
                        selectedFileName = fName;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: ytCtrl,
                    decoration: InputDecoration(
                      labelText: 'رابط فيديو يوتيوب (اختياري)',
                      hintText: 'https://www.youtube.com/watch?v=...',
                      border: const OutlineInputBorder(),
                      prefixIcon: Icon(Icons.video_library, color: Colors.red.shade700),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: accentGold),
              onPressed: () async {
                final title = titleCtrl.text.trim();
                final desc = descCtrl.text.trim();
                final yt = ytCtrl.text.trim();
                final date = dateCtrl.text.trim();

                if (title.isEmpty || desc.isEmpty) {
                  _showNotification('يرجى ملء اسم ووصف الإنجاز', isError: true);
                  return;
                }

                Navigator.pop(ctx);
                final newAchievement = {
                  'id': 'ach_${DateTime.now().millisecondsSinceEpoch}',
                  'title': title,
                  'date_str': date.isNotEmpty ? date : 'مؤخراً',
                  'description': desc,
                  'image_url': currentImageUrl,
                  'youtube_url': yt.isNotEmpty ? yt : null,
                };

                setState(() {
                  achievementsData.insert(0, newAchievement);
                  selectedAchievementIndex = 0;
                });

                await _saveAchievementsToSupabase();

                if (sendNotification) {
                  try {
                    await AdminSupabase.client.from('notifications').insert({
                      'academic_id': null,
                      'title': 'إنجاز جديد: $title',
                      'body': desc.length > 80 ? '${desc.substring(0, 80)}...' : desc,
                      'notification_type': 'general',
                      'route_name': 'achievements',
                      'is_read': false,
                    });
                    FcmSenderService.sendToTopic(
                      topic: 'all_students',
                      title: 'إنجاز جديد: $title',
                      body: desc.length > 80 ? '${desc.substring(0, 80)}...' : desc,
                      routeName: 'achievements',
                    );
                  } catch (_) {}
                }

                _showNotification('تمت إضافة الإنجاز وحفظه في السحابة بنجاح!');
              },
              child: const Text('حفظ ونشر', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditAchievementDialog(BuildContext context, Map<String, dynamic> item) {
    if (!_canAds(PermissionAction.update)) {
      _showNotification('⚠️ عذراً، حسابك لا يملك صلاحية التعديل في قسم الإعلانات.', isError: true);
      return;
    }
    final titleCtrl = TextEditingController(text: item['title']);
    final dateCtrl = TextEditingController(text: item['date_str'] ?? item['date'] ?? '');
    final descCtrl = TextEditingController(text: item['description']);
    final ytCtrl = TextEditingController(text: item['youtube_url'] ?? '');
    String currentImageUrl = item['image_url'] ?? '';
    String? selectedFileName;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          title: const Text('تعديل الإنجاز', style: TextStyle(color: primaryNavy, fontWeight: FontWeight.bold)),
          content: SizedBox(
            width: 480,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleCtrl,
                    decoration: const InputDecoration(labelText: 'اسم / عنوان الإنجاز *', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: dateCtrl,
                    decoration: const InputDecoration(labelText: 'تاريخ الإنجاز', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(labelText: 'وصف الإنجاز *', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  _buildDeviceImagePicker(
                    context: context,
                    currentImageUrl: currentImageUrl,
                    selectedFileName: selectedFileName,
                    onImagePicked: (newUrl, fName) {
                      setDlgState(() {
                        currentImageUrl = newUrl;
                        selectedFileName = fName;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: ytCtrl,
                    decoration: InputDecoration(
                      labelText: 'رابط فيديو يوتيوب',
                      border: const OutlineInputBorder(),
                      prefixIcon: Icon(Icons.video_library, color: Colors.red.shade700),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: primaryNavy),
              onPressed: () async {
                final title = titleCtrl.text.trim();
                final desc = descCtrl.text.trim();
                final yt = ytCtrl.text.trim();
                final date = dateCtrl.text.trim();

                if (title.isEmpty || desc.isEmpty) {
                  _showNotification('يرجى ملء كافة الحقول الأساسية', isError: true);
                  return;
                }

                Navigator.pop(ctx);
                setState(() {
                  item['title'] = title;
                  item['date_str'] = date;
                  item['description'] = desc;
                  item['image_url'] = currentImageUrl;
                  item['youtube_url'] = yt.isNotEmpty ? yt : null;
                });

                await _saveAchievementsToSupabase();
                _showNotification('تم تحديث الإنجاز بنجاح!');
              },
              child: const Text('حفظ التعديل', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  // عرض قسم خريجي الغد والتحكم بها
  // ══════════════════════════════════════════════════════════════
  Widget _buildAlumniView() {
    if (isLoadingAlumni) {
      return const Center(child: CircularProgressIndicator(color: accentGold));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'خدمة خريجي الغد (${alumniData.length} دفعة)',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryNavy),
            ),
            IconButton(
              icon: const Icon(Icons.refresh, color: primaryNavy),
              tooltip: 'تحديث من السحابة',
              onPressed: _loadAlumniFromSupabase,
            ),
          ],
        ),
        const SizedBox(height: 14),

        Expanded(
          child: alumniData.isEmpty
              ? const Center(child: Text('لا توجد دفعات خريجين مسجلة', style: TextStyle(color: Colors.grey)))
              : ListView.builder(
                  itemCount: alumniData.length,
                  itemBuilder: (context, index) {
                    final item = alumniData[index];
                    final isSelected = selectedAlumniIndex == index;
                    final hasPdf = (item['magazine_pdf_url'] ?? '').toString().isNotEmpty;
                    final hasYoutube = (item['ceremony_youtube_url'] ?? '').toString().isNotEmpty;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: InkWell(
                        onTap: () => setState(() => selectedAlumniIndex = index),
                        borderRadius: BorderRadius.circular(12),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? accentGold : Colors.grey.shade300,
                              width: isSelected ? 2.5 : 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: isSelected ? accentGold.withOpacity(0.2) : Colors.black.withOpacity(0.04),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: SizedBox(
                                  width: 110,
                                  height: 85,
                                  child: _buildImageWidget(item['banner_image_url'] ?? item['banner_image_path'] ?? ''),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          item['title'] ?? '',
                                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: primaryNavy),
                                        ),
                                        if (isSelected)
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: accentGold,
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: const Text('محدد', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 5),
                                    Row(
                                      children: [
                                        const Icon(Icons.school, size: 14, color: accentGold),
                                        const SizedBox(width: 4),
                                        Text(
                                          item['batch_name'] ?? '',
                                          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: accentGold),
                                        ),
                                        const SizedBox(width: 10),
                                        Text(
                                          item['graduates_count'] ?? '',
                                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: hasPdf ? Colors.blue.shade50 : Colors.grey.shade100,
                                            borderRadius: BorderRadius.circular(4),
                                            border: Border.all(color: hasPdf ? Colors.blue.shade300 : Colors.grey.shade300),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(Icons.picture_as_pdf, size: 12, color: hasPdf ? Colors.blue.shade800 : Colors.grey),
                                              const SizedBox(width: 4),
                                              Text(
                                                hasPdf ? 'مجلة PDF متوفرة' : 'بدون مجلة',
                                                style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: hasPdf ? Colors.blue.shade800 : Colors.grey),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: hasYoutube ? Colors.red.shade50 : Colors.grey.shade100,
                                            borderRadius: BorderRadius.circular(4),
                                            border: Border.all(color: hasYoutube ? Colors.red.shade300 : Colors.grey.shade300),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(Icons.play_circle_fill, size: 12, color: hasYoutube ? Colors.red.shade800 : Colors.grey),
                                              const SizedBox(width: 4),
                                              Text(
                                                hasYoutube ? 'فيديو الحفل متاح' : 'بدون فيديو حفل',
                                                style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: hasYoutube ? Colors.red.shade800 : Colors.grey),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
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
        const SizedBox(height: 16),

        _buildBottomControls(
          addLabel: 'إضافة دفعة خريجين',
          onAddPressed: () => _showAddAlumniDialog(context),
          onEditPressed: alumniData.isNotEmpty ? () => _showEditAlumniDialog(context, alumniData[selectedAlumniIndex]) : () {},
          onDeletePressed: alumniData.isNotEmpty ? () => _deleteAlumni(selectedAlumniIndex) : () {},
          showAddButton: true,
          showNotificationCheckbox: true,
        ),
      ],
    );
  }

  Future<void> _deleteAlumni(int index) async {
    if (!_canAds(PermissionAction.delete)) {
      _showNotification('⚠️ عذراً، حسابك لا يملك صلاحية الحذف في قسم الإعلانات.', isError: true);
      return;
    }
    if (index < 0 || index >= alumniData.length) return;
    final item = alumniData[index];

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تأكيد حذف دفعة الخريجين'),
        content: Text('هل أنت متأكد من حذف "${item['title']}"؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('نعم، حذف', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      setState(() {
        alumniData.removeAt(index);
        if (selectedAlumniIndex >= alumniData.length && alumniData.isNotEmpty) {
          selectedAlumniIndex = alumniData.length - 1;
        }
      });
      await _saveAlumniToSupabase();
      _showNotification('تم حذف دفعة الخريجين بنجاح');
    } catch (e) {
      _showNotification('فشل الحذف: $e', isError: true);
    }
  }

  void _showAddAlumniDialog(BuildContext context) {
    if (!_canAds(PermissionAction.create)) {
      _showNotification('⚠️ عذراً، حسابك لا يملك صلاحية الإضافة في قسم الإعلانات.', isError: true);
      return;
    }
    final titleCtrl = TextEditingController(text: 'دفعة ');
    final batchNameCtrl = TextEditingController(text: 'الدفعة السادسة');
    final countCtrl = TextEditingController(text: '200');
    final ytCtrl = TextEditingController();
    String currentBannerUrl = 'assets/images/alumni_banner_1.png';
    String? bannerFileName;
    String currentPdfUrl = '';
    String? pdfFileName;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          title: const Text('إضافة دفعة خريجين جديدة', style: TextStyle(color: primaryNavy, fontWeight: FontWeight.bold)),
          content: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleCtrl,
                    decoration: const InputDecoration(labelText: 'اسم الدفعة *', hintText: 'مثال: دفعة رواد الغد', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: batchNameCtrl,
                          decoration: const InputDecoration(labelText: 'ترتيب الدفعة *', hintText: 'مثال: الدفعة الخامسة', border: OutlineInputBorder()),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: countCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'عدد الخريجين *', hintText: 'مثال: 250', border: OutlineInputBorder()),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildDeviceImagePicker(
                    context: context,
                    currentImageUrl: currentBannerUrl,
                    selectedFileName: bannerFileName,
                    onImagePicked: (newUrl, fName) {
                      setDlgState(() {
                        currentBannerUrl = newUrl;
                        bannerFileName = fName;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildDevicePdfPicker(
                    context: context,
                    currentPdfUrl: currentPdfUrl,
                    selectedFileName: pdfFileName,
                    onPdfPicked: (newPdf, fName) {
                      setDlgState(() {
                        currentPdfUrl = newPdf;
                        pdfFileName = fName;
                      });
                    },
                    onClear: () {
                      setDlgState(() {
                        currentPdfUrl = '';
                        pdfFileName = null;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: ytCtrl,
                    decoration: InputDecoration(
                      labelText: 'رابط يوتيوب لمشاهدة الحفل (اختياري)',
                      hintText: 'https://www.youtube.com/watch?v=...',
                      border: const OutlineInputBorder(),
                      prefixIcon: Icon(Icons.video_library, color: Colors.red.shade700),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: accentGold),
              onPressed: () async {
                final title = titleCtrl.text.trim();
                final bName = batchNameCtrl.text.trim();
                final count = countCtrl.text.trim();
                final yt = ytCtrl.text.trim();

                if (title.isEmpty || bName.isEmpty || count.isEmpty) {
                  _showNotification('يرجى ملء اسم الدفعة وترتيبها وعدد الخريجين', isError: true);
                  return;
                }

                Navigator.pop(ctx);
                final newBatch = {
                  'id': 'alumni_${DateTime.now().millisecondsSinceEpoch}',
                  'title': title,
                  'batch_name': bName,
                  'graduates_count': '($count خريج)',
                  'banner_image_url': currentBannerUrl,
                  'magazine_pdf_url': currentPdfUrl.isNotEmpty ? currentPdfUrl : null,
                  'ceremony_youtube_url': yt.isNotEmpty ? yt : null,
                };

                setState(() {
                  alumniData.insert(0, newBatch);
                  selectedAlumniIndex = 0;
                });

                await _saveAlumniToSupabase();

                if (sendNotification) {
                  try {
                    await AdminSupabase.client.from('notifications').insert({
                      'academic_id': null,
                      'title': 'حفل تخرج جديد: $title',
                      'body': 'تهانينا لخريجي $bName ($title)! يمكنكم الآن تصفح المجلة ومشاهدة الحفل عبر التطبيق.',
                      'notification_type': 'general',
                      'route_name': 'alumni',
                      'is_read': false,
                    });
                    FcmSenderService.sendToTopic(
                      topic: 'all_students',
                      title: 'حفل تخرج جديد: $title',
                      body: 'تهانينا لخريجي $bName ($title)! يمكنكم الآن تصفح المجلة ومشاهدة الحفل عبر التطبيق.',
                      routeName: 'alumni',
                    );
                  } catch (_) {}
                }

                _showNotification('تمت إضافة دفعة الخريجين بنجاح!');
              },
              child: const Text('حفظ ونشر', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditAlumniDialog(BuildContext context, Map<String, dynamic> item) {
    if (!_canAds(PermissionAction.update)) {
      _showNotification('⚠️ عذراً، حسابك لا يملك صلاحية التعديل في قسم الإعلانات.', isError: true);
      return;
    }
    final titleCtrl = TextEditingController(text: item['title']);
    final batchNameCtrl = TextEditingController(text: item['batch_name']);
    String countRaw = (item['graduates_count'] ?? '').toString();
    countRaw = countRaw.replaceAll('(', '').replaceAll(')', '').replaceAll('خريج', '').trim();
    final countCtrl = TextEditingController(text: countRaw);
    final ytCtrl = TextEditingController(text: item['ceremony_youtube_url'] ?? '');
    String currentBannerUrl = item['banner_image_url'] ?? item['banner_image_path'] ?? '';
    String? bannerFileName;
    String currentPdfUrl = item['magazine_pdf_url'] ?? '';
    String? pdfFileName;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          title: const Text('تعديل دفعة الخريجين', style: TextStyle(color: primaryNavy, fontWeight: FontWeight.bold)),
          content: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleCtrl,
                    decoration: const InputDecoration(labelText: 'اسم الدفعة *', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: batchNameCtrl,
                          decoration: const InputDecoration(labelText: 'ترتيب الدفعة *', border: OutlineInputBorder()),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: countCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'عدد الخريجين *', border: OutlineInputBorder()),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildDeviceImagePicker(
                    context: context,
                    currentImageUrl: currentBannerUrl,
                    selectedFileName: bannerFileName,
                    onImagePicked: (newUrl, fName) {
                      setDlgState(() {
                        currentBannerUrl = newUrl;
                        bannerFileName = fName;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildDevicePdfPicker(
                    context: context,
                    currentPdfUrl: currentPdfUrl,
                    selectedFileName: pdfFileName,
                    onPdfPicked: (newPdf, fName) {
                      setDlgState(() {
                        currentPdfUrl = newPdf;
                        pdfFileName = fName;
                      });
                    },
                    onClear: () {
                      setDlgState(() {
                        currentPdfUrl = '';
                        pdfFileName = null;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: ytCtrl,
                    decoration: InputDecoration(
                      labelText: 'رابط يوتيوب لمشاهدة الحفل',
                      border: const OutlineInputBorder(),
                      prefixIcon: Icon(Icons.video_library, color: Colors.red.shade700),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: primaryNavy),
              onPressed: () async {
                final title = titleCtrl.text.trim();
                final bName = batchNameCtrl.text.trim();
                final count = countCtrl.text.trim();
                final yt = ytCtrl.text.trim();

                if (title.isEmpty || bName.isEmpty || count.isEmpty) {
                  _showNotification('يرجى ملء كافة الحقول الأساسية', isError: true);
                  return;
                }

                Navigator.pop(ctx);
                setState(() {
                  item['title'] = title;
                  item['batch_name'] = bName;
                  item['graduates_count'] = '($count خريج)';
                  item['banner_image_url'] = currentBannerUrl;
                  item['magazine_pdf_url'] = currentPdfUrl.isNotEmpty ? currentPdfUrl : null;
                  item['ceremony_youtube_url'] = yt.isNotEmpty ? yt : null;
                });

                await _saveAlumniToSupabase();
                _showNotification('تم تحديث بيانات الدفعة بنجاح!');
              },
              child: const Text('حفظ التعديل', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  // التقويم السنوي (المحافظة على كامل وظيفته السابقة)
  // ══════════════════════════════════════════════════════════════
  Widget _buildCalendarView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Center(
            child: Container(
              width: 340,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: calendarBg,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: _previousMonth,
                        icon: const Icon(Icons.arrow_back_ios, color: accentGold, size: 16),
                      ),
                      InkWell(
                        onTap: () => _showYearPicker(context),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: accentGold,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${currentDate.year}',
                            style: const TextStyle(
                              color: primaryNavy,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () => _showMonthPicker(context),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: primaryNavy,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: accentGold, width: 1.5),
                          ),
                          child: Text(
                            monthsNames[currentDate.month - 1],
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: _nextMonth,
                        icon: const Icon(Icons.arrow_forward_ios, color: accentGold, size: 16),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: const ['S', 'M', 'T', 'W', 'T', 'F', 'S']
                        .map((day) => Text(
                              day,
                              style: const TextStyle(
                                color: Colors.white54,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ))
                        .toList(),
                  ),
                  const Divider(color: Colors.white24, height: 16),
                  _buildCalendarGrid(),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        _buildBottomControls(
          addLabel: '',
          onAddPressed: () {},
          onEditPressed: () {},
          onDeletePressed: () {},
          showAddButton: false,
          showNotificationCheckbox: false,
        ),
      ],
    );
  }

  Widget _buildCalendarGrid() {
    final int daysInMonth = DateUtils.getDaysInMonth(currentDate.year, currentDate.month);
    final int firstWeekday = DateTime(currentDate.year, currentDate.month, 1).weekday;

    List<int> calendarDays = [];
    int startOffset = (firstWeekday % 7);
    for (int i = 0; i < startOffset; i++) {
      calendarDays.add(0);
    }
    for (int i = 1; i <= daysInMonth; i++) {
      calendarDays.add(i);
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
      ),
      itemCount: calendarDays.length,
      itemBuilder: (context, index) {
        final day = calendarDays[index];
        if (day == 0) return const SizedBox.shrink();

        final bool isSelected = (day == selectedDay);
        final bool hasEvent = eventDays.contains(day);

        return GestureDetector(
          onTap: () {
            setState(() => selectedDay = day);
            _showAddEventDialog(context, day);
          },
          child: Container(
            decoration: BoxDecoration(
              color: isSelected ? accentGold : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Text(
                  '$day',
                  style: TextStyle(
                    color: isSelected ? primaryNavy : Colors.white,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 13,
                  ),
                ),
                if (hasEvent)
                  Positioned(
                    top: 2,
                    right: 2,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 4,
                          height: 4,
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const Icon(
                          Icons.notifications,
                          size: 10,
                          color: accentGold,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showMonthPicker(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('اختر الشهر', style: TextStyle(color: primaryNavy, fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: 250,
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(12, (index) {
              return InkWell(
                onTap: () {
                  setState(() {
                    currentDate = DateTime(currentDate.year, index + 1, 1);
                    selectedDay = null;
                  });
                  Navigator.pop(context);
                  _loadEventsFromSupabase();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: (currentDate.month == index + 1) ? accentGold : Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    monthsNames[index],
                    style: TextStyle(
                      color: (currentDate.month == index + 1) ? primaryNavy : Colors.black87,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  void _showYearPicker(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('اختر السنة', style: TextStyle(color: primaryNavy, fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: 250,
          height: 250,
          child: ListView.builder(
            itemCount: 15,
            itemBuilder: (context, index) {
              final year = 2020 + index;
              return ListTile(
                title: Text('$year', style: TextStyle(fontWeight: year == currentDate.year ? FontWeight.bold : FontWeight.normal, color: year == currentDate.year ? accentGold : Colors.black87)),
                onTap: () {
                  setState(() {
                    currentDate = DateTime(year, currentDate.month, 1);
                    selectedDay = null;
                  });
                  Navigator.pop(context);
                  _loadEventsFromSupabase();
                },
              );
            },
          ),
        ),
      ),
    );
  }

  final TextEditingController _eventNameController = TextEditingController();
  final TextEditingController _eventDescController = TextEditingController();

  void _showAddEventDialog(BuildContext context, int clickedDay) {
    if (!_canAds(PermissionAction.create) && !_canAds(PermissionAction.update)) {
      _showNotification('⚠️ عذراً، حسابك لا يملك صلاحية تعديل أحداث التقويم.', isError: true);
      return;
    }
    bool dialogNotification = false;
    _eventNameController.clear();
    _eventDescController.clear();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'إضافة مناسبة ليوم $clickedDay ${monthsNames[currentDate.month - 1]} ${currentDate.year}',
            style: const TextStyle(color: primaryNavy, fontWeight: FontWeight.bold, fontSize: 16),
          ),
          content: SizedBox(
            width: 320,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _eventNameController,
                  decoration: const InputDecoration(
                    labelText: 'اسم المناسبة',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _eventDescController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'الوصف أو التفاصيل',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Checkbox(
                      value: dialogNotification,
                      activeColor: primaryNavy,
                      onChanged: (val) => setDialogState(() => dialogNotification = val ?? false),
                    ),
                    const Expanded(
                      child: Text('إرسال إشعار للطلاب عن هذه المناسبة', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: accentGold),
              onPressed: () async {
                final title = _eventNameController.text.trim();
                final desc = _eventDescController.text.trim();
                if (title.isEmpty) return;

                Navigator.pop(context);
                final monthStr = currentDate.month.toString().padLeft(2, '0');
                final dayStr = clickedDay.toString().padLeft(2, '0');
                final dateStr = '${currentDate.year}-$monthStr-$dayStr';

                try {
                  await AdminSupabase.client.from('calendar_events').insert({
                    'title': title,
                    'description': desc,
                    'event_date': dateStr,
                    'is_highlighted_gold': true,
                  });

                  if (dialogNotification) {
                    try {
                      await AdminSupabase.client.from('notifications').insert({
                        'title': 'مناسبة جديدة في التقويم: $title',
                        'body': desc.isNotEmpty ? desc : 'تمت إضافة مناسبة جديدة في التقويم الجامعي بتاريخ $dateStr',
                        'notification_type': 'event',
                        'route_name': 'calendar',
                        'is_read': false,
                      });
                      FcmSenderService.sendToTopic(
                        topic: 'all_students',
                        title: 'مناسبة جديدة في التقويم: $title',
                        body: desc.isNotEmpty ? desc : 'تمت إضافة مناسبة جديدة في التقويم الجامعي بتاريخ $dateStr',
                        routeName: 'calendar',
                      );
                    } catch (_) {}
                  }

                  setState(() {
                    if (!eventDays.contains(clickedDay)) {
                      eventDays.add(clickedDay);
                    }
                  });
                  _showNotification('تمت إضافة المناسبة بنجاح!');
                } catch (e) {
                  _showNotification('فشل حفظ المناسبة: $e', isError: true);
                }
              },
              child: const Text('حفظ', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  // أدوات الواجهة المساعدة
  // ══════════════════════════════════════════════════════════════
  Widget _buildImageWidget(String path) {
    if (path.isEmpty) {
      return Container(
        color: Colors.grey[200],
        child: const Center(child: Icon(Icons.image, size: 40, color: Colors.grey)),
      );
    }
    if (path.startsWith('data:image')) {
      try {
        final commaIdx = path.indexOf(',');
        final base64Str = commaIdx != -1 ? path.substring(commaIdx + 1) : path;
        final bytes = base64Decode(base64Str);
        return Image.memory(
          bytes,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            color: Colors.grey[200],
            child: const Center(child: Icon(Icons.broken_image, size: 30, color: Colors.grey)),
          ),
        );
      } catch (e) {
        return Container(
          color: Colors.grey[200],
          child: const Center(child: Icon(Icons.broken_image, size: 30, color: Colors.grey)),
        );
      }
    }
    if (path.startsWith('http')) {
      return Image.network(
        path,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          color: Colors.grey[200],
          child: const Center(child: Icon(Icons.broken_image, size: 30, color: Colors.grey)),
        ),
      );
    }
    return Image.asset(
      path,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        color: Colors.grey[200],
        child: const Center(child: Icon(Icons.image, size: 30, color: Colors.grey)),
      ),
    );
  }

  Widget _buildDeviceImagePicker({
    required BuildContext context,
    required String currentImageUrl,
    required String? selectedFileName,
    required Function(String newImageUrl, String fileName) onImagePicked,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(Icons.photo_library_outlined, size: 18, color: primaryNavy),
              const SizedBox(width: 8),
              const Text(
                'اختيار صورة من الجهاز *',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: primaryNavy),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () async {
                  try {
                    final res = await FilePicker.platform.pickFiles(
                      type: FileType.custom,
                      allowedExtensions: ['jpg', 'jpeg', 'png', 'webp', 'gif'],
                      withData: true,
                    );
                    if (res != null && res.files.isNotEmpty) {
                      final file = res.files.single;
                      final bytes = file.bytes;
                      if (bytes != null) {
                        final ext = file.extension ?? 'png';
                        final base64String = 'data:image/$ext;base64,${base64Encode(bytes)}';
                        onImagePicked(base64String, file.name);
                      }
                    }
                  } catch (e) {
                    _showNotification('فشل اختيار الصورة: $e', isError: true);
                  }
                },
                icon: const Icon(Icons.upload_file, size: 16, color: Colors.white),
                label: const Text(
                  'اختيار من الجهاز',
                  style: TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentGold,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 60,
                  height: 60,
                  color: Colors.grey.shade200,
                  child: _buildImageWidget(currentImageUrl),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      selectedFileName != null && selectedFileName.isNotEmpty
                          ? 'الملف: $selectedFileName'
                          : (currentImageUrl.isNotEmpty
                              ? (currentImageUrl.startsWith('data:image') ? 'تم اختيار صورة من الجهاز بنجاح' : 'الصورة الحالية محددة')
                              : 'لم يتم اختيار صورة بعد'),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: (selectedFileName != null || currentImageUrl.startsWith('data:image'))
                            ? Colors.green.shade700
                            : Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'الصيغ المدعومة: JPG, PNG, WEBP',
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDevicePdfPicker({
    required BuildContext context,
    required String currentPdfUrl,
    required String? selectedFileName,
    required Function(String newPdfUrl, String fileName) onPdfPicked,
    required VoidCallback onClear,
  }) {
    final hasPdf = currentPdfUrl.trim().isNotEmpty;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.picture_as_pdf, size: 20, color: Colors.red.shade700),
              const SizedBox(width: 8),
              const Text(
                'ملف مجلة الدفعة (PDF) - اختياري',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: primaryNavy),
              ),
              const Spacer(),
              if (hasPdf)
                TextButton.icon(
                  onPressed: onClear,
                  icon: const Icon(Icons.close, size: 14, color: Colors.red),
                  label: const Text('إلغاء الملف', style: TextStyle(fontSize: 11, color: Colors.red)),
                ),
              ElevatedButton.icon(
                onPressed: () async {
                  try {
                    final res = await FilePicker.platform.pickFiles(
                      type: FileType.custom,
                      allowedExtensions: ['pdf'],
                      withData: true,
                    );
                    if (res != null && res.files.isNotEmpty) {
                      final file = res.files.single;
                      final bytes = file.bytes;
                      if (bytes != null) {
                        final base64String = 'data:application/pdf;base64,${base64Encode(bytes)}';
                        onPdfPicked(base64String, file.name);
                      }
                    }
                  } catch (e) {
                    _showNotification('فشل اختيار ملف الـ PDF: $e', isError: true);
                  }
                },
                icon: const Icon(Icons.attach_file, size: 16, color: Colors.white),
                label: const Text(
                  'اختيار PDF',
                  style: TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade800,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                hasPdf ? Icons.check_circle : Icons.info_outline,
                size: 16,
                color: hasPdf ? Colors.green : Colors.grey,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  selectedFileName != null && selectedFileName.isNotEmpty
                      ? 'تم اختيار الملف: $selectedFileName'
                      : (hasPdf
                          ? (currentPdfUrl.startsWith('data:application/pdf')
                              ? 'تم رفع ملف PDF بنجاح من الجهاز'
                              : 'الملف الحالي: $currentPdfUrl')
                          : 'لم يتم اختيار ملف PDF (اختياري - لن يكون هناك تفاعل عند الضغط على قراءة المجلة إذا لم يُرفع)'),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: hasPdf ? Colors.green.shade800 : Colors.grey.shade600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSubTabButton(String title, IconData icon) {
    final bool isSelected = activeSubTab == title;
    return Material(
      color: isSelected ? primaryNavy : const Color(0xFF4A5A85),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: () {
          setState(() => activeSubTab = title);
          widget.onPathChanged('الإعلانات > $title');
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13.5)),
              Icon(icon, color: Colors.white, size: 18),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomControls({
    required String addLabel,
    required VoidCallback onAddPressed,
    required VoidCallback onEditPressed,
    required VoidCallback onDeletePressed,
    required bool showAddButton,
    required bool showNotificationCheckbox,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (showNotificationCheckbox)
          Row(
            children: [
              Checkbox(
                value: sendNotification,
                activeColor: primaryNavy,
                onChanged: (val) => setState(() => sendNotification = val ?? false),
              ),
              const Text(
                'هل تريد النشر وإيصال إشعار ؟',
                style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: Colors.black87),
              ),
            ],
          )
        else
          const SizedBox.shrink(),
        Row(
          children: [
            _buildActionButton('حذف', Icons.delete_outline, Colors.red[700]!, onDeletePressed),
            const SizedBox(width: 10),
            _buildActionButton('تعديل', Icons.edit_outlined, primaryNavy, onEditPressed),
            if (showAddButton) ...[
              const SizedBox(width: 10),
              _buildActionButton(addLabel, Icons.add_circle_outline, accentGold, onAddPressed),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton(String title, IconData icon, Color color, VoidCallback onTap) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16, color: Colors.white),
      label: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        elevation: 2,
      ),
    );
  }
}