import 'package:flutter/material.dart';
import 'profile_screen.dart';
import 'location_screen.dart';
import 'home_screen.dart';

class CalendarScreen extends StatefulWidget {
  final bool hideBottomNav;
  const CalendarScreen({super.key, this.hideBottomNav = false});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  // التاريخ المعروض والمحدد
  late DateTime _focusedDate;
  late DateTime _selectedDate;

  // فرز الأحداث
  bool _sortAscending = true;

  // ألوان التصميم المطابقة للصورة المطلوبة بدقة
  static const Color navyDark = Color(0xFF071B42);
  static const Color goldYellow = Color(0xFFE5A912);
  static const Color textGray = Color(0xFF6B7280);
  static const Color cardBorder = Color(0xFFEDEDED);

  // أسماء الشهور بالإنجليزية كما في التصميم (Sep, Oct, ...)
  final List<String> _monthNames = const [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];

  // أسماء الأيام بالإنجليزية وباللون الذهبي
  final List<String> _weekDays = const [
    'Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa'
  ];

  // قاعدة بيانات الأحداث والفعاليات
  late Map<String, List<Map<String, dynamic>>> _eventsData;

  @override
  void initState() {
    super.initState();
    // ضبط التاريخ الافتراضي على سبتمبر 2026 واليوم 25 كما في التصميم المطلوب
    _focusedDate = DateTime(2026, 9, 25);
    _selectedDate = DateTime(2026, 9, 25);

    _eventsData = {
      '2026-09-26': [
        {
          'id': '1',
          'title': 'إجازة رسمية',
          'subtitle': 'بمناسبة عيد ثورة 26 سبتمبر',
          'highlight': 'نتمنى لكم إجازة سعيدة.',
          'footer': 'السبت 26  |  450 مشاهدة',
          'isFavorite': true,
          'dayNumber': 26,
        }
      ],
      '2026-09-30': [
        {
          'id': '2',
          'title': 'حفل تكريم الأوائل',
          'subtitle': 'جميع المستويات',
          'highlight': 'الدعوة عامة.',
          'footer': 'الأربعاء 30  |  602 مشاهدة',
          'isFavorite': false,
          'dayNumber': 30,
        }
      ],
    };
  }

  String _dateKey(DateTime d) {
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  bool _hasEventOnDay(DateTime day) {
    return _eventsData.containsKey(_dateKey(day));
  }

  void _onPrevMonth() {
    setState(() {
      _focusedDate = DateTime(_focusedDate.year, _focusedDate.month - 1, 1);
    });
  }

  void _onNextMonth() {
    setState(() {
      _focusedDate = DateTime(_focusedDate.year, _focusedDate.month + 1, 1);
    });
  }

  void _selectDay(DateTime day) {
    setState(() {
      _selectedDate = day;
      if (day.month != _focusedDate.month) {
        _focusedDate = DateTime(day.year, day.month, 1);
      }
    });
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
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Column(
                    children: [
                      const SizedBox(height: 6),

                      // بطاقة التقويم الكحلية التفاعلية
                      _buildCalendarCard(),

                      const SizedBox(height: 22),

                      // عنوان "أحداث قادمة" و "سجل الأحداث"
                      _buildEventsHeader(),

                      const SizedBox(height: 14),

                      // قائمة كروت الأحداث
                      _buildEventsList(),
                    ],
                  ),
                ),
              ),

              // 3. شريط التنقل السفلي
              if (!widget.hideBottomNav) _buildBottomNav(),
            ],
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════
  // 1) الشريط العلوي (App Bar)
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
                onTap: () => Navigator.maybePop(context),
                child: const Icon(
                  Icons.arrow_forward_rounded,
                  color: navyDark,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              const Text(
                'تقويم الغد',
                style: TextStyle(
                  fontSize: 22,
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
  // 2) بطاقة التقويم التفاعلية
  // ══════════════════════════════════════
  Widget _buildCalendarCard() {
    return Container(
      width: 320,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
      decoration: BoxDecoration(
        color: navyDark,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: navyDark.withValues(alpha: 0.35),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // شريط اختيار الشهر والسنة
          _buildMonthYearHeader(),

          const SizedBox(height: 16),

          // شريط أسماء الأيام بالإنجليزية وباللون الذهبي
          _buildDaysOfWeek(),

          const SizedBox(height: 10),

          // شبكة أيام الشهر التفاعلية
          _buildDaysGrid(),
        ],
      ),
    );
  }

  // ترويسة التقويم (الأسهم والكبسولات الذهبية)
  Widget _buildMonthYearHeader() {
    final currentMonthName = _monthNames[_focusedDate.month - 1];
    final currentYear = _focusedDate.year.toString();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // سهم السابق <
        IconButton(
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          icon: const Icon(
            Icons.chevron_left_rounded,
            color: goldYellow,
            size: 28,
          ),
          onPressed: _onPrevMonth,
        ),

        // كبسولة الشهر وكبسولة السنة
        Row(
          children: [
            // زر اختيار الشهر
            GestureDetector(
              onTap: _showMonthPicker,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                decoration: BoxDecoration(
                  color: goldYellow,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Text(
                      currentMonthName,
                      style: const TextStyle(
                        color: navyDark,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: navyDark,
                      size: 18,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(width: 10),

            // زر اختيار السنة
            GestureDetector(
              onTap: _showYearPicker,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                decoration: BoxDecoration(
                  color: goldYellow,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Text(
                      currentYear,
                      style: const TextStyle(
                        color: navyDark,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: navyDark,
                      size: 18,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),

        // سهم التالي >
        IconButton(
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          icon: const Icon(
            Icons.chevron_right_rounded,
            color: goldYellow,
            size: 28,
          ),
          onPressed: _onNextMonth,
        ),
      ],
    );
  }

  // صف أيام الأسبوع (Su Mo Tu We Th Fr Sa)
  Widget _buildDaysOfWeek() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: _weekDays.map((day) {
        return SizedBox(
          width: 36,
          child: Text(
            day,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: goldYellow,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        );
      }).toList(),
    );
  }

  // شبكة الأيام التفاعلية المحسوبة بدقة
  Widget _buildDaysGrid() {
    final year = _focusedDate.year;
    final month = _focusedDate.month;

    final firstDayOfMonth = DateTime(year, month, 1);
    final daysInMonth = DateTime(year, month + 1, 0).day;

    // في التقويم ذو البداية بالأحد (Sunday = 7 في Dart -> 0 في نظامنا)
    final startingWeekday = firstDayOfMonth.weekday % 7; // الأحد = 0, الاثنين = 1 ...

    final totalCells = ((startingWeekday + daysInMonth) > 35) ? 42 : 35;

    final List<Widget> dayWidgets = [];

    for (int i = 0; i < totalCells; i++) {
      if (i < startingWeekday) {
        // أيام الشهر السابق
        final prevMonthLastDay = DateTime(year, month, 0).day;
        final dayNum = prevMonthLastDay - (startingWeekday - i - 1);
        final date = DateTime(year, month - 1, dayNum);
        dayWidgets.add(_buildOutsideDayCell(date));
      } else if (i < startingWeekday + daysInMonth) {
        // أيام الشهر الحالي
        final dayNum = i - startingWeekday + 1;
        final date = DateTime(year, month, dayNum);
        dayWidgets.add(_buildCurrentMonthDayCell(date));
      } else {
        // أيام الشهر التالي
        final dayNum = i - (startingWeekday + daysInMonth) + 1;
        final date = DateTime(year, month + 1, dayNum);
        dayWidgets.add(_buildOutsideDayCell(date));
      }
    }

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 7,
      mainAxisSpacing: 8,
      crossAxisSpacing: 2,
      childAspectRatio: 1.0,
      children: dayWidgets,
    );
  }

  // خلية اليوم في الشهر الحالي
  Widget _buildCurrentMonthDayCell(DateTime date) {
    final isSelected = date.year == _selectedDate.year &&
        date.month == _selectedDate.month &&
        date.day == _selectedDate.day;

    final hasEvent = _hasEventOnDay(date);

    return GestureDetector(
      onTap: () => _selectDay(date),
      behavior: HitTestBehavior.opaque,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // في حال كان هذا اليوم هو المحدد، نعرض الدرع الذهبي
          if (isSelected)
            Container(
              width: 32,
              height: 36,
              decoration: const BoxDecoration(
                color: goldYellow,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(8),
                  topRight: Radius.circular(8),
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                '${date.day}',
                style: const TextStyle(
                  color: navyDark,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
            )
          else
            Text(
              '${date.day}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),

          // جرس التنبيه الذهبي في زاوية اليوم الذي يحتوي على حدث
          if (hasEvent)
            Positioned(
              top: 0,
              right: 4,
              child: Stack(
                children: const [
                  Icon(
                    Icons.notifications_active_rounded,
                    color: goldYellow,
                    size: 13,
                  ),
                  Positioned(
                    top: 1,
                    right: 1,
                    child: CircleAvatar(
                      radius: 2,
                      backgroundColor: Colors.red,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // خلية الأيام خارج الشهر
  Widget _buildOutsideDayCell(DateTime date) {
    return GestureDetector(
      onTap: () => _selectDay(date),
      behavior: HitTestBehavior.opaque,
      child: Center(
        child: Text(
          '${date.day}',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.35),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════
  // 3) عنوان أحداث قادمة وسجل الأحداث
  // ══════════════════════════════════════
  Widget _buildEventsHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 26),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'أحداث قادمة',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: navyDark,
            ),
          ),
          GestureDetector(
            onTap: () {
              setState(() {
                _sortAscending = !_sortAscending;
              });
            },
            child: Row(
              children: const [
                Icon(
                  Icons.swap_vert_rounded,
                  size: 18,
                  color: textGray,
                ),
                SizedBox(width: 4),
                Text(
                  'سجل الأحداث',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: textGray,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════
  // 4) قائمة كروت الأحداث والإجازات
  // ══════════════════════════════════════
  Widget _buildEventsList() {
    List<Map<String, dynamic>> list = [];

    // إذا تم تحديد يوم يحتوي على حدث، نظهره أولاً
    final selectedEvents = _eventsData[_dateKey(_selectedDate)];
    if (selectedEvents != null && selectedEvents.isNotEmpty) {
      list = List.from(selectedEvents);
    } else {
      list = _eventsData.values.expand((e) => e).toList();
    }

    if (!_sortAscending) {
      list = list.reversed.toList();
    }

    return Column(
      children: list.map((event) => _buildEventCard(event)).toList(),
    );
  }

  Widget _buildEventCard(Map<String, dynamic> event) {
    final bool isFavorite = event['isFavorite'] ?? false;

    return Container(
      width: 320,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: cardBorder,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // صورة شعار الكلية داخل المربع الكحلي المميز
          Container(
            width: 88,
            height: 94,
            decoration: BoxDecoration(
              color: navyDark,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Image.asset(
                'assets/images/gic_shield.png',
                width: 65,
                height: 65,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(
                    Icons.school_rounded,
                    color: goldYellow,
                    size: 40,
                  );
                },
              ),
            ),
          ),

          const SizedBox(width: 12),

          // النصوص والتفاصيل
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // العنوان وزر القلب التفاعلي
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      event['title'],
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: navyDark,
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
                        color: isFavorite
                            ? const Color(0xFFE53935)
                            : textGray,
                        size: 20,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 3),

                // الوصف الفرعي
                Text(
                  event['subtitle'],
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: textGray,
                  ),
                ),

                const SizedBox(height: 3),

                // النص المميز باللون الذهبي
                Text(
                  event['highlight'],
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: goldYellow,
                  ),
                ),

                const SizedBox(height: 8),

                // السطر السفلي (التاريخ وعدد المشاهدات)
                Text(
                  event['footer'],
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: textGray,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════
  // 5) شريط التنقل السفلي المطابق للتصميم
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
          // الرئيسية (يمين في RTL)
          _buildNavItem(Icons.home_outlined, () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const HomeScreen()),
              );
            }
          }),

          // خريطة / موقع
          _buildNavItem(Icons.location_on_outlined, () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const LocationScreen()),
            );
          }),

          // تقويم (مفعل بالدائرة الرمادية الزرقاء الفاتحة)
          _buildNavItem(
            Icons.calendar_month_rounded,
            () {},
            isActive: true,
          ),

          // بروفايل (يسار في RTL)
          _buildNavItem(Icons.person_outline_rounded, () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const ProfileScreen()),
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

  // ══════════════════════════════════════
  // نوافذ اختيار الشهر والسنة السريعة
  // ══════════════════════════════════════
  void _showMonthPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return Container(
          padding: const EdgeInsets.all(16),
          height: 250,
          child: GridView.builder(
            itemCount: 12,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              childAspectRatio: 2,
            ),
            itemBuilder: (ctx, i) {
              final isCurrent = (_focusedDate.month - 1) == i;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _focusedDate = DateTime(_focusedDate.year, i + 1, 1);
                  });
                  Navigator.pop(ctx);
                },
                child: Container(
                  margin: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isCurrent ? goldYellow : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    _monthNames[i],
                    style: TextStyle(
                      color: isCurrent ? navyDark : Colors.black87,
                      fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  void _showYearPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return Container(
          padding: const EdgeInsets.all(16),
          height: 250,
          child: ListView.builder(
            itemCount: 10,
            itemBuilder: (ctx, i) {
              final year = 2024 + i;
              final isCurrent = _focusedDate.year == year;
              return ListTile(
                title: Text(
                  '$year',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isCurrent ? goldYellow : Colors.black87,
                    fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                onTap: () {
                  setState(() {
                    _focusedDate = DateTime(year, _focusedDate.month, 1);
                  });
                  Navigator.pop(ctx);
                },
              );
            },
          ),
        );
      },
    );
  }
}
