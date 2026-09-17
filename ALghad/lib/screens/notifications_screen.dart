import 'package:flutter/material.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  // 🎨 ألوان التصميم
  static const Color whiteBg = Colors.white;
  static const Color navyDark = Color(0xFF0A2451);
  static const Color textGray = Color(0xFF8A8A8A);
  static const Color dividerColor = Color(0xFFF0F0F0);

  // 🎨 ألوان الأيقونات — خلفيات فقط
  static const Color iconBgGreen = Color(0xFFE8F5E9);
  static const Color iconBgBlue = Color(0xFFE3F2FD);

  // 📋 إشعارات اليوم
  final List<Map<String, dynamic>> _todayNotifications = [
    {
      'title': 'إعلان جدول الدراسة',
      'description':
      'طلابنا الأعزاء.. نحيطكم علما بأن الدراسة للمستوى الأول تبدأ يوم السبت القادم.',
      'time': '34 دقيقة',
      'icon': Icons.calendar_today_rounded,
      'iconBg': iconBgGreen,
    },
    {
      'title': 'إعلان جدول الدراسة',
      'description':
      'طلابنا الأعزاء.. نحيطكم علما بأن الدراسة للمستوى الأول تبدأ يوم السبت القادم.',
      'time': '1 ساعة',
      'icon': Icons.calendar_today_rounded,
      'iconBg': iconBgGreen,
    },
    {
      'title': 'إعلان جدول الدراسة',
      'description':
      'طلابنا الأعزاء.. نحيطكم علما بأن الدراسة للمستوى الأول تبدأ يوم السبت القادم.',
      'time': '8 ساعات',
      'icon': Icons.edit_calendar_rounded,
      'iconBg': iconBgGreen,
    },
  ];

  // 📋 إشعارات أمس
  final List<Map<String, dynamic>> _yesterdayNotifications = [
    {
      'title': 'عرض المولود النبوي الشريف',
      'description':
      'رسوم التسجيل مجانية حتى 20 ربيع الأول بمناسبة قدوم المولد النبوي الشريف.',
      'time': '1 يوم',
      'icon': Icons.calendar_today_rounded,
      'iconBg': iconBgBlue,
    },
  ];

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
              _buildAppBar(),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ═══════ اليوم ═══════
                      _buildSectionHeader('اليوم'),
                      ..._todayNotifications.asMap().entries.map((entry) {
                        final index = entry.key;
                        final notif = entry.value;
                        return Column(
                          children: [
                            _buildNotificationCard(notif),
                            if (index != _todayNotifications.length - 1)
                              _buildDivider(),
                          ],
                        );
                      }),

                      const SizedBox(height: 8),

                      // ═══════ أمس ═══════
                      _buildSectionHeader('أمس'),
                      ..._yesterdayNotifications.asMap().entries.map((entry) {
                        final index = entry.key;
                        final notif = entry.value;
                        return Column(
                          children: [
                            _buildNotificationCard(notif),
                            if (index !=
                                _yesterdayNotifications.length - 1)
                              _buildDivider(),
                          ],
                        );
                      }),

                      const SizedBox(height: 20),
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
  // 1) الشريط العلوي
  // ══════════════════════════════════════
  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(
              Icons.arrow_forward_rounded,
              color: navyDark,
              size: 24,
            ),
          ),
          const SizedBox(width: 4),
          const Expanded(
            child: Text(
              'الإشعارات',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: navyDark,
              ),
            ),
          ),
          TextButton.icon(
            onPressed: () {},
            icon: const Icon(
              Icons.refresh_rounded,
              size: 14,
              color: textGray,
            ),
            label: const Text(
              'تحديث',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: textGray,
              ),
            ),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 5,
              ),
              minimumSize: const Size(0, 0),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              backgroundColor: const Color(0xFFF5F5F5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════
  // 2) عنوان القسم
  // ══════════════════════════════════════
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: navyDark,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () {},
            child: const Text(
              'تحديد الكل كمقروء',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: textGray,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════
  // 3) خط فاصل
  // ══════════════════════════════════════
  Widget _buildDivider() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Divider(
        height: 1,
        thickness: 1,
        color: dividerColor,
      ),
    );
  }

  // ══════════════════════════════════════
  // 4) بطاقة إشعار
  // ══════════════════════════════════════
  Widget _buildNotificationCard(Map<String, dynamic> notif) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── الأيقونة (يمين) — دائرية ──
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: notif['iconBg'] as Color,
              shape: BoxShape.circle,   // ← ✅ دائرة
            ),
            child: Icon(
              notif['icon'] as IconData,
              color: navyDark,   // ← ✅ كحلي
              size: 20,
            ),
          ),
          const SizedBox(width: 12),

          // ── النصوص ──
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        notif['title'] as String,
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: navyDark,
                          height: 1.3,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      notif['time'] as String,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: textGray,
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  notif['description'] as String,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                    color: textGray,
                    height: 1.7,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}