import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../screens/notifications_screen.dart';
import 'auth_service.dart';

class SystemNotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static GlobalKey<NavigatorState>? _navKey;
  static RealtimeChannel? _realtimeChannel;
  static Timer? _pollTimer;
  static bool _isInitialized = false;
  static String? _activeAcademicId;
  static final Set<String> _deliveredNotificationIds = {};
  static DateTime _listenerStartTime = DateTime.now().subtract(const Duration(minutes: 5));

  /// تهيئة خدمة الإشعارات النظامية على الهاتف
  static Future<void> init(GlobalKey<NavigatorState> navigatorKey) async {
    _navKey = navigatorKey;
    if (_isInitialized) return;

    if (!kIsWeb) {
      try {
        const AndroidInitializationSettings androidSettings =
            AndroidInitializationSettings('@mipmap/ic_launcher');

        const DarwinInitializationSettings iosSettings =
            DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

        const InitializationSettings initSettings = InitializationSettings(
          android: androidSettings,
          iOS: iosSettings,
        );

        await _notificationsPlugin.initialize(
          initSettings,
          onDidReceiveNotificationResponse: (NotificationResponse response) {
            _handleNotificationClick(response.payload);
          },
        );

        // إنشاء قناة إشعارات عالية الأهمية للأندرويد
        const AndroidNotificationChannel channel = AndroidNotificationChannel(
          'alghad_notifications_channel',
          'إشعارات كلية الغد الدولية',
          description: 'قناة التنبيهات الرسمية لطلاب كلية الغد',
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
          showBadge: true,
        );

        await _notificationsPlugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>()
            ?.createNotificationChannel(channel);

        // طلب الإذن الصريح في أندرويد 13 فما فوق
        await _notificationsPlugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>()
            ?.requestNotificationsPermission();

        _isInitialized = true;
      } catch (e) {
        debugPrint('Error initializing local notifications: $e');
      }
    }
  }

  /// الاستماع اللحظي لقاعدة البيانات وتوليد إشعار فوري في شريط الهاتف
  static void startRealtimeListener(String? currentStudentAcademicId) async {
    // إلغاء الاشتراك القديم إن وجد لمنع التكرار
    stopRealtimeListener();

    String? studentId = currentStudentAcademicId?.trim();
    if (studentId == null || studentId.isEmpty) {
      try {
        final session = await AuthService.getSavedSession();
        studentId = session?.academicId.trim();
      } catch (_) {}
    }
    _activeAcademicId = studentId;
    _listenerStartTime = DateTime.now().subtract(const Duration(minutes: 5));

    // 1. الاستماع المباشر عبر Supabase Realtime
    try {
      final supabase = Supabase.instance.client;
      _realtimeChannel = supabase.channel('student_push_notifications_${DateTime.now().millisecondsSinceEpoch}');

      _realtimeChannel!.onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'notifications',
        callback: (payload) {
          final newRecord = payload.newRecord;
          _processNotificationRecord(newRecord);
        },
      ).subscribe();
    } catch (e) {
      debugPrint('Error starting Supabase notification listener: $e');
    }

    // 2. فحص دوري متزامن (Polling) كل 4 ثوانٍ لضمان وصول الإشعار دائماً حتى لو تعطل الويب سوكت
    _pollTimer?.cancel();
    // تشغيل فحص فوري
    _checkForNewNotifications();
    _pollTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      _checkForNewNotifications();
    });
  }

  /// فحص الإشعارات الجديدة من قاعدة البيانات
  static Future<void> _checkForNewNotifications() async {
    try {
      final supabase = Supabase.instance.client;
      final studentId = _activeAcademicId;

      var query = supabase
          .from('notifications')
          .select('id, academic_id, title, body, created_at, is_read')
          .eq('is_read', false);

      if (studentId != null && studentId.isNotEmpty) {
        query = query.or('academic_id.eq.$studentId,academic_id.is.null');
      } else {
        query = query.filter('academic_id', 'is', null);
      }

      final res = await query.order('created_at', ascending: false).limit(10);
      final List items = res as List;

      for (var item in items) {
        final id = item['id']?.toString() ?? '';
        if (id.isEmpty) continue;

        // التحقق من تاريخ الإشعار لعدم تكرار الإشعارات القديمة
        final rawDate = item['created_at']?.toString() ?? '';
        if (rawDate.isNotEmpty) {
          final dt = DateTime.tryParse(rawDate);
          if (dt != null && dt.isBefore(_listenerStartTime)) {
            _deliveredNotificationIds.add(id);
            continue;
          }
        }

        if (!_deliveredNotificationIds.contains(id)) {
          _deliveredNotificationIds.add(id);
          final title = item['title']?.toString() ?? 'إشعار جديد من الكلية';
          final body = item['body']?.toString() ?? 'لديك تنبيه جديد في التطبيق';
          await showSystemNotification(
            title: title,
            body: body,
            payload: 'notifications',
          );
        }
      }
    } catch (e) {
      debugPrint('Error polling notifications: $e');
    }
  }

  static void _processNotificationRecord(Map<String, dynamic> record) {
    final id = record['id']?.toString() ?? '';
    final targetId = record['academic_id']?.toString().trim();
    final title = record['title']?.toString() ?? 'إشعار جديد من الكلية';
    final body = record['body']?.toString() ?? 'لديك تنبيه جديد في التطبيق';

    if (id.isNotEmpty && _deliveredNotificationIds.contains(id)) return;
    if (id.isNotEmpty) _deliveredNotificationIds.add(id);

    // التحقق: هل الإشعار موجه لهذا الطالب تحديداً أم عام لكافة الطلاب
    if (targetId == null ||
        targetId.isEmpty ||
        targetId.toLowerCase() == 'all' ||
        (_activeAcademicId != null && targetId == _activeAcademicId)) {
      showSystemNotification(
        title: title,
        body: body,
        payload: 'notifications',
      );
    }
  }

  /// إظهار الإشعار في شريط الهاتف العلوي (Notification Tray)
  static Future<void> showSystemNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    if (kIsWeb) return;

    try {
      final int notifId = Random().nextInt(1000000);

      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        'alghad_notifications_channel',
        'إشعارات كلية الغد الدولية',
        channelDescription: 'قناة التنبيهات الرسمية لطلاب كلية الغد',
        importance: Importance.max,
        priority: Priority.high,
        ticker: 'إشعار جديد',
        showWhen: true,
        enableVibration: true,
        playSound: true,
        channelShowBadge: true,
        category: AndroidNotificationCategory.message,
        styleInformation: BigTextStyleInformation(''),
      );

      const NotificationDetails platformDetails =
          NotificationDetails(android: androidDetails);

      await _notificationsPlugin.show(
        notifId,
        title,
        body,
        platformDetails,
        payload: payload ?? 'notifications',
      );
    } catch (e) {
      debugPrint('Error showing local notification: $e');
    }
  }

  /// التوجيه التلقائي لشاشة الإشعارات عند النقر على إشعار الهاتف
  static void _handleNotificationClick(String? payload) {
    if (_navKey?.currentState != null) {
      _navKey!.currentState!.push(
        MaterialPageRoute(builder: (context) => const NotificationsScreen()),
      );
    }
  }

  /// إيقاف الاستماع عند تسجيل الخروج
  static void stopRealtimeListener() {
    _pollTimer?.cancel();
    _pollTimer = null;
    if (_realtimeChannel != null) {
      try {
        Supabase.instance.client.removeChannel(_realtimeChannel!);
      } catch (_) {}
      _realtimeChannel = null;
    }
  }
}
