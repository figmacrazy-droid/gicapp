import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';
import '../services/system_notification_service.dart';
import 'calendar_screen.dart';
import 'finance_screen.dart';
import 'schedules_view_screen.dart';
import 'student_results_screen.dart';

class NotificationItemModel {
  final String id;
  final String title;
  final String body;
  final String date;
  final String type; // 'general', 'schedule', 'result', 'event', 'finance'
  final String? routeName;
  final bool isRead;

  const NotificationItemModel({
    required this.id,
    required this.title,
    required this.body,
    required this.date,
    required this.type,
    this.routeName,
    this.isRead = false,
  });

  NotificationItemModel copyWith({bool? isRead}) {
    return NotificationItemModel(
      id: id,
      title: title,
      body: body,
      date: date,
      type: type,
      routeName: routeName,
      isRead: isRead ?? this.isRead,
    );
  }
}

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  static const Color navyDark = Color(0xFF0B1E3D);
  static const Color accentGold = Color(0xFFD39706);

  List<NotificationItemModel> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);
    try {
      final session = await AuthService.getSavedSession();
      final String? currentId = session?.academicId.trim();

      List? rawList;
      if (session?.sessionToken != null && session!.sessionToken!.isNotEmpty) {
        try {
          final rpcRes = await Supabase.instance.client.rpc(
            'app_get_notifications',
            params: {'p_token': session.sessionToken},
          );
          if (rpcRes is List) rawList = rpcRes;
        } catch (_) {}
      }

      if (rawList == null) {
        var query = Supabase.instance.client.from('notifications').select();
        if (currentId != null && currentId.isNotEmpty) {
          query = query.or('academic_id.eq.$currentId,academic_id.is.null');
        } else {
          query = query.filter('academic_id', 'is', null);
        }
        final res = await query.order('created_at', ascending: false);
        rawList = res as List;
      }

      final List list = rawList;

      if (list.isNotEmpty) {
        // تحديث قاعدة بيانات Supabase فوراً بأن الطالب قد قرأ جميع الإشعارات الموجهة له
        if (session?.sessionToken != null && session!.sessionToken!.isNotEmpty) {
          try {
            await Supabase.instance.client.rpc(
              'app_mark_notifications_read',
              params: {'p_token': session.sessionToken},
            );
          } catch (_) {}
        }
        if (currentId != null && currentId.isNotEmpty) {
          try {
            await Supabase.instance.client
                .from('notifications')
                .update({'is_read': true})
                .eq('academic_id', currentId)
                .eq('is_read', false);
          } catch (e) {
            debugPrint('Error marking notifications as read: $e');
          }
        }

        // إعلام خدمة إشعارات النظام بأن هذه المعرفات تم الاطلاع عليها لعدم تكرار التنبيه
        final ids = list.map((item) => item['id']?.toString() ?? '').where((id) => id.isNotEmpty).toList();
        SystemNotificationService.markIdsAsSeen(ids);

        // حذف وإخفاء الإشعارات فوراً من شريط إشعارات الهاتف عند فتح شاشة الإشعارات
        SystemNotificationService.clearAllSystemNotifications();

        final List<NotificationItemModel> loaded = list.map((item) {
          final String rawDate = item['created_at']?.toString() ?? '';
          String displayDate = 'الآن';
          if (rawDate.isNotEmpty) {
            final dt = DateTime.tryParse(rawDate)?.toLocal();
            if (dt != null) {
              final now = DateTime.now();
              if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
                final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
                final period = dt.hour >= 12 ? 'م' : 'ص';
                final minute = dt.minute.toString().padLeft(2, '0');
                displayDate = 'اليوم $hour:$minute $period';
              } else {
                displayDate = '${dt.year}/${dt.month.toString().padLeft(2, '0')}/${dt.day.toString().padLeft(2, '0')}';
              }
            }
          }

          return NotificationItemModel(
            id: item['id']?.toString() ?? '',
            title: item['title'] ?? 'تنبيه جديد',
            body: item['body'] ?? '',
            date: displayDate,
            type: item['notification_type'] ?? 'general',
            routeName: item['route_name'],
            isRead: true, // نظراً لفتح شاشة الإشعارات ورؤيتها بالكامل
          );
        }).toList();

        if (mounted) {
          setState(() {
            _notifications = loaded;
            _isLoading = false;
          });
        }
        return;
      }
    } catch (e) {
      debugPrint('Error loading notifications: $e');
    }

    // بدائل افتراضية في حال كانت القاعدة فارغة تماماً
    if (mounted) {
      setState(() {
        _notifications = const [
          NotificationItemModel(
            id: '1',
            title: 'أهلاً بكم في تطبيق كلية الغد المشرق! 🎉',
            body: 'تم تفعيل التنبيهات والإشعارات الفورية المباشرة لجميع الطلاب لمعرفة كل جديد فور نزوله.',
            date: 'اليوم',
            type: 'general',
            isRead: false,
          ),
          NotificationItemModel(
            id: '2',
            title: 'تم رفع جداول امتحانات النصف الأول 📅',
            body: 'قام الكنترول بنشر جداول الامتحانات النصفية لجميع الأقسام والتخصصات. يمكنك تنزيل الجدول والمعاينة الآن.',
            date: 'أمس',
            type: 'schedule',
            isRead: false,
          ),
        ];
        _isLoading = false;
      });
    }
  }

  Future<void> _handleNotificationTap(NotificationItemModel item, int index) async {
    // 1. تحديث حالة القراءة في Supabase محلياً وقاعدة البيانات وإخفاء الإشعار من شريط الهاتف
    SystemNotificationService.clearAllSystemNotifications();
    if (!item.isRead) {
      setState(() {
        _notifications[index] = item.copyWith(isRead: true);
      });
      try {
        await Supabase.instance.client
            .from('notifications')
            .update({'is_read': true})
            .eq('id', item.id);
      } catch (_) {}
    }

    if (!mounted) return;

    // 2. التوجيه إلى الشاشة المعنية بحسب مسار الإشعار
    final route = item.routeName?.toLowerCase() ?? '';
    if (route.contains('calendar') || item.type == 'event') {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const CalendarScreen()));
    } else if (route.contains('finance') || item.type == 'finance') {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const FinanceScreen()));
    } else if (route.contains('schedule') || item.type == 'schedule') {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const SchedulesViewScreen(title: 'الجداول الدراسية', scheduleType: 'study')));
    } else if (route.contains('result') || item.type == 'result') {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const StudentResultsScreen()));
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      final session = await AuthService.getSavedSession();
      final String? currentId = session?.academicId;

      var query = Supabase.instance.client
          .from('notifications')
          .update({'is_read': true});

      if (currentId != null && currentId.isNotEmpty) {
        await query.or('academic_id.eq.$currentId,academic_id.is.null');
      } else {
        await query.filter('academic_id', 'is', null);
      }

      _loadNotifications();
    } catch (_) {}
  }

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
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all_rounded, color: navyDark),
            tooltip: 'تحديد الكل كمقروء',
            onPressed: _markAllAsRead,
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: navyDark),
            tooltip: 'تحديث',
            onPressed: _loadNotifications,
          ),
        ],
      ),
      body: SafeArea(
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _notifications.isEmpty
                  ? const Center(
                      child: Text(
                        'لا توجد تنبيهات حالياً',
                        style: TextStyle(color: Colors.grey, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _notifications.length,
                      itemBuilder: (context, index) {
                        final item = _notifications[index];
                        return InkWell(
                          onTap: () => _handleNotificationTap(item, index),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: item.isRead ? Colors.white : const Color(0xFFFFFDF5),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: item.isRead ? Colors.grey.shade200 : accentGold.withOpacity(0.4),
                                width: item.isRead ? 1 : 1.5,
                              ),
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
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: item.isRead ? FontWeight.normal : FontWeight.bold,
                                      color: item.isRead ? Colors.grey : accentGold,
                                    ),
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