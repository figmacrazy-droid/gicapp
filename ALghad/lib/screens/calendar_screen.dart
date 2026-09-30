import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'profile_screen.dart';
import 'location_screen.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  int _currentNavIndex = 2; // 2 = Calendar tab active
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;

  static const Color navyDark = Color(0xFF0A2451);
  static const Color gold = Color(0xFFD39706);
  static const Color textGray = Color(0xFF6B6B6B);

  // 🗓️ قائمة إجازات السنة والأحداث الأكاديمية مرتبطة بالتواريخ
  final Map<DateTime, List<Map<String, dynamic>>> _events = {
    DateTime(2026, 9, 26): [
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
    ],
    DateTime(2026, 9, 30): [
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
    ],
    DateTime(2026, 10, 14): [
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
    ],
    DateTime(2026, 10, 18): [
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
    ],
  };

  List<Map<String, dynamic>> _getEventsForDay(DateTime day) {
    return _events[DateTime(day.year, day.month, day.day)] ?? [];
  }

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
        padding: const EdgeInsets.all(8),
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
        child: TableCalendar(
          locale: 'ar_SA',
          firstDay: DateTime(2026, 1, 1),
          lastDay: DateTime(2027, 12, 31),
          focusedDay: _focusedDay,
          selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
          calendarFormat: _calendarFormat,
          eventLoader: _getEventsForDay,
          startingDayOfWeek: StartingDayOfWeek.sunday,
          headerStyle: HeaderStyle(
            formatButtonVisible: false,
            titleCentered: true,
            titleTextStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            leftChevronIcon: const Icon(
              Icons.chevron_left_rounded,
              color: gold,
              size: 18,
            ),
            rightChevronIcon: const Icon(
              Icons.chevron_right_rounded,
              color: gold,
              size: 18,
            ),
            headerPadding: const EdgeInsets.symmetric(vertical: 2),
          ),
          daysOfWeekStyle: DaysOfWeekStyle(
            weekdayStyle: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Color(0xFFA0C0E0),
            ),
            weekendStyle: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Color(0xFFA0C0E0),
            ),
          ),
          calendarStyle: CalendarStyle(
            todayDecoration: BoxDecoration(
              color: gold.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            selectedDecoration: const BoxDecoration(
              color: gold,
              shape: BoxShape.circle,
            ),
            todayTextStyle: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
            selectedTextStyle: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: navyDark,
            ),
            defaultTextStyle: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
            weekendTextStyle: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
            outsideTextStyle: TextStyle(
              fontSize: 12,
              color: Colors.white.withOpacity(0.3),
            ),
            markerDecoration: BoxDecoration(
              color: gold,
              shape: BoxShape.circle,
            ),
            markersMaxCount: 3,
            markerSize: 4,
            cellMargin: EdgeInsets.zero,
            cellPadding: EdgeInsets.zero,
          ),
          onDaySelected: (selectedDay, focusedDay) {
            setState(() {
              _selectedDay = selectedDay;
              _focusedDay = focusedDay;
            });
          },
          onPageChanged: (focusedDay) {
            setState(() {
              _focusedDay = focusedDay;
            });
          },
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
    // عرض جميع الأحداث من جميع الأشهر
    final allEvents = _events.values.expand((e) => e).toList();

    if (allEvents.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Center(
          child: Text(
            'لا توجد أحداث',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: textGray,
            ),
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: allEvents.length,
      itemBuilder: (context, index) {
        final event = allEvents[index];
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
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
                          fontSize: 15,
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
                        size: 18,
                      ),
                    ),
                  ],
                ),

                // العنوان الفرعي
                Text(
                  event['subtitle'],
                  style: const TextStyle(
                    fontSize: 12,
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
                    fontSize: 10,
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
                        fontSize: 10,
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
                        fontSize: 10,
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
