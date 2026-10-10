import 'package:flutter/material.dart';

class NotificationItemModel {
  final String id;
  final String title;
  final String body;
  final String date;
  final String type; // 'general', 'schedule', 'result', 'event', 'finance'
  final bool isRead;

  const NotificationItemModel({
    required this.id,
    required this.title,
    required this.body,
    required this.date,
    required this.type,
    this.isRead = false,
  });
}

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  static const Color navyDark = Color(0xFF0B1E3D);
  static const Color accentGold = Color(0xFFD39706);

  final List<NotificationItemModel> _notifications = [
    const NotificationItemModel(
      id: '1',
      title: 'أهلاً بكم في تطبيق كلية الغد المشرق! 🎉',
      body: 'تم تفعيل التنبيهات والإشعارات الفورية المباشرة لجميع الطلاب لمعرفة كل جديد فور نزوله.',
      date: 'اليوم 10:30 ص',
      type: 'general',
      isRead: false,
    ),
    const NotificationItemModel(
      id: '2',
      title: 'تم رفع جداول امتحانات النصف الأول 📅',
      body: 'قام الكنترول بنشر جداول الامتحانات النصفية لجميع الأقسام والتخصصات. يمكنك تنزيل الجدول والمعاينة الآن.',
      date: 'أمس 02:15 م',
      type: 'schedule',
      isRead: false,
    ),
    const NotificationItemModel(
      id: '3',
      title: 'حدث جديد في الكالندر الأكاديمي ⭐️',
      body: 'افتتاح المعرض العلمي الأول لطلاب المختبرات والصيدلة.',
      date: 'قبل يومين',
      type: 'event',
      isRead: true,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: navyDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'مركز الإشعارات والتنبيهات الفورية',
          style: TextStyle(
            color: navyDark,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _notifications.length,
            itemBuilder: (context, index) {
              final item = _notifications[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: item.isRead ? Colors.white : const Color(0xFFFFFDF5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: item.isRead ? Colors.grey.shade200 : accentGold.withOpacity(0.4)),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2)),
                  ],
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(14),
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _getNotificationColor(item.type).withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(_getNotificationIcon(item.type), color: _getNotificationColor(item.type), size: 24),
                  ),
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: item.isRead ? FontWeight.bold : FontWeight.w900,
                            color: navyDark,
                          ),
                        ),
                      ),
                      Text(
                        item.date,
                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      item.body,
                      style: const TextStyle(fontSize: 12, color: Color(0xFF555555), height: 1.4),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'schedule':
        return Icons.calendar_month;
      case 'result':
        return Icons.school;
      case 'event':
        return Icons.star;
      case 'finance':
        return Icons.account_balance_wallet;
      default:
        return Icons.notifications_active;
    }
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'schedule':
        return Colors.blue;
      case 'result':
        return Colors.green;
      case 'event':
        return accentGold;
      case 'finance':
        return Colors.purple;
      default:
        return navyDark;
    }
  }
}