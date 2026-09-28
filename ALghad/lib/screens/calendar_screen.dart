import 'package:flutter/material.dart';
import 'profile_screen.dart';
import 'location_screen.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  int _currentNavIndex = 2; // 2 = Calendar tab active
  String _selectedMonth = 'Sep';
  int _selectedYear = 2026;

  static const Color navyDark = Color(0xFF0A2451);
  static const Color gold = Color(0xFFD39706);
  static const Color textGray = Color(0xFF6B6B6B);
  static const Color lightGray = Color(0xFFF2F2F2);

  // 🗓️ قائمة إجازات السنة والأحداث الأكاديمية
  final List<Map<String, dynamic>> _events = [
    {
      'id': '1',
      'title': 'إجازة رسمية',
      'subtitle': 'بمناسبة عيد ثورة 26 سبتمبر',
      'description': 'نتمنى لكم إجازة سعيدة',
      'dayName': 'السبت',
      'dayNumber': '26',
      'views': '450',
      'isFavorite': true,
      'isHoliday': true,
      'dateTag': '26 سبتمبر 2026',
    },
    {
      'id': '2',
      'title': 'حفل تكريم الأوائل',
      'subtitle': 'جميع المستويات',
      'description': 'الدعوة عامة لجميع الطلاب',
      'dayName': 'الأربعاء',
      'dayNumber': '30',
      'views': '602',
      'isFavorite': false,
      'isHoliday': false,
      'dateTag': '30 سبتمبر 2026',
    },
    {
      'id': '3',
      'title': 'إجازة عيد الجلاء 14 أكتوبر',
      'subtitle': 'إجازة رسمية لجميع الكليات',
      'description': 'تعطل الدراسة في جميع الأقسام',
      'dayName': 'الأربعاء',
      'dayNumber': '14',
      'views': '512',
      'isFavorite': true,
      'isHoliday': true,
      'dateTag': '14 أكتوبر 2026',
    },
    {
      'id': '4',
      'title': 'بدء الاختبارات النصفية',
      'subtitle': 'الفصل الدراسي الأول',
      'description': 'جدول الاختبارات معلن في شؤون الطلاب',
      'dayName': 'الأحد',
      'dayNumber': '18',
      'views': '780',
      'isFavorite': false,
      'isHoliday': false,
      'dateTag': '18 أكتوبر 2026',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Column(
            children: [
              // 1. الشريط العلوي (App Bar)
              _buildTopAppBar(),

              // 2. المحتوى القابل للتمرير
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      const SizedBox(height: 12),

                      // 3. تقويم الشهر (Rectangle 371)
                      _buildCalendarBox(),

                      const SizedBox(height: 19), // 19px حسب مقاسات Figma

                      // 4. رأس شريط الأحداث والقوائم
                      _buildEventsHeader(),

                      const SizedBox(height: 10),

                      // 5. قائمة كروت الإجازات والأحداث
                      _buildEventsList(),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),

              // 6. شريط التنقل السفلي
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
  Widget _buildTopAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(
                  Icons.arrow_forward_rounded,
                  color: navyDark,
                  size: 26,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'تقويم الغد',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: navyDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════
  // 2) مربع التقويم الأكاديمي (W: 312, H: 302)
  // ══════════════════════════════════════
  Widget _buildCalendarBox() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        width: 312,
        height: 302,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: navyDark,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: navyDark.withOpacity(0.25),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            // أزرار تحديد الشهر والسنة
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Icon(
                  Icons.chevron_left_rounded,
                  color: gold,
                  size: 28,
                ),
                Row(
                  children: [
                    // زر الشهر
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: gold,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          Text(
                            _selectedMonth,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: navyDark,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            size: 18,
                            color: navyDark,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // زر السنة
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: gold,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          Text(
                            '$_selectedYear',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: navyDark,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            size: 18,
                            color: navyDark,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: gold,
                  size: 28,
                ),
              ],
            ),

            const SizedBox(height: 12),

            // أسماء أيام الأسبوع
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: const [
                _DayNameHeader('Su'),
                _DayNameHeader('Mo'),
                _DayNameHeader('Tu'),
                _DayNameHeader('We'),
                _DayNameHeader('Th'),
                _DayNameHeader('Fr'),
                _DayNameHeader('Sa'),
              ],
            ),

            const SizedBox(height: 8),
            const Divider(color: Colors.white12, height: 1),
            const SizedBox(height: 8),

            // شبكة أيام الشهر
            Expanded(
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 35, // 5 أسابيع
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  mainAxisSpacing: 4,
                  crossAxisSpacing: 4,
                ),
                itemBuilder: (context, index) {
                  final dayNumber = index + 1;
                  if (dayNumber > 30) {
                    final nextMonthDay = dayNumber - 30;
                    return Center(
                      child: Text(
                        '$nextMonthDay',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withOpacity(0.3),
                        ),
                      ),
                    );
                  }

                  // يوم 25: إجازة مميزة بشعار درع ذهبي
                  final bool isSpecialBadgeDay = (dayNumber == 25);
                  // أيام 26 و 30: أيام بها تنبيهات/جرس
                  final bool hasNotification = (dayNumber == 26 || dayNumber == 30);

                  if (isSpecialBadgeDay) {
                    return Container(
                      decoration: BoxDecoration(
                        color: gold,
                        shape: BoxShape.rectangle,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          const Icon(
                            Icons.shield_rounded,
                            color: gold,
                            size: 26,
                          ),
                          Text(
                            '$dayNumber',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              color: navyDark,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      Text(
                        '$dayNumber',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      if (hasNotification)
                        const Positioned(
                          top: 2,
                          right: 2,
                          child: Icon(
                            Icons.notifications_active_rounded,
                            size: 10,
                            color: gold,
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════
  // 3) عنوان أحداث قادمة وسجل الأحداث
  // ══════════════════════════════════════
  Widget _buildEventsHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'أحداث قادمة',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w900,
              color: navyDark,
            ),
          ),
          Row(
            children: const [
              Text(
                'سجل الأحداث',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: textGray,
                ),
              ),
              SizedBox(width: 4),
              Icon(
                Icons.swap_vert_rounded,
                size: 18,
                color: textGray,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════
  // 4) كروت الأحداث والإجازات الرسمية (W: 312, H: 126)
  // ══════════════════════════════════════
  Widget _buildEventsList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _events.length,
      itemBuilder: (context, index) {
        final event = _events[index];
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
          child: _buildEventCard(event),
        );
      },
    );
  }

  Widget _buildEventCard(Map<String, dynamic> event) {
    final bool isFavorite = event['isFavorite'] ?? false;

    return Container(
      width: 312,
      height: 126,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE5E5E5),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // القسم الأيمن: شعار الكلية داخل مربع كحلي مميز
          Container(
            width: 95,
            height: 102,
            decoration: BoxDecoration(
              color: navyDark,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Image.asset(
                'assets/images/gic_shield.png',
                width: 70,
                height: 70,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(
                    Icons.school_rounded,
                    color: gold,
                    size: 40,
                  );
                },
              ),
            ),
          ),

          const SizedBox(width: 12),

          // القسم الأيسر: تفاصيل الإجازة / الحدث
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // السطر العلوي: العنوان والمفضلة
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        event['title'],
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: navyDark,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          event['isFavorite'] = !isFavorite;
                        });
                      },
                      child: Icon(
                        isFavorite
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        color: isFavorite ? const Color(0xFFE53935) : textGray,
                        size: 20,
                      ),
                    ),
                  ],
                ),

                // العنوان الفرعي
                Text(
                  event['subtitle'],
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: navyDark,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),

                // الوصف
                Text(
                  event['description'],
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: textGray,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),

                // السطر السفلي: اليوم وتعداد المشاهدات
                Row(
                  children: [
                    Text(
                      '${event['dayName']} ${event['dayNumber']}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: navyDark,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 1,
                      height: 10,
                      color: const Color(0xFFD0D0D0),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${event['views']} مشاهدة',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: textGray,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════
  // 5) شريط التنقل السفلي
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
                Navigator.popUntil(context, (route) => route.isFirst);
              } else if (i == 1) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const LocationScreen(),
                  ),
                );
              } else if (i == 3) {
                Navigator.push(
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

class _DayNameHeader extends StatelessWidget {
  final String text;
  const _DayNameHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.bold,
        color: Color(0xFFA0C0E0),
      ),
    );
  }
}
