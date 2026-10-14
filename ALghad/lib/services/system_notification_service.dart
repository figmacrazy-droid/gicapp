import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../screens/notifications_screen.dart';

class SystemNotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static GlobalKey<NavigatorState>? _navKey;
  static RealtimeChannel? _realtimeChannel;
  static bool _isInitialized = false;

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
        final AndroidNotificationChannel channel = const AndroidNotificationChannel(
          'alghad_notifications_channel',
          'إشعارات كلية الغد الدولية',
          description: 'قناة التنبيهات الرسمية لطلاب كلية الغد',
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
        );

        await _notificationsPlugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>()
            ?.createNotificationChannel(channel);

        // طلب الإذن في أندرويد 13 فما فوق
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
  static void startRealtimeListener(String? currentStudentAcademicId) {
    // إلغاء الاشتراك القديم إن وجد لمنع التكرار
    stopRealtimeListener();

    try {
      final supabase = Supabase.instance.client;
      _realtimeChannel = supabase.channel('student_push_notifications');

      _realtimeChannel!.onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'notifications',
        callback: (payload) {
          final newRecord = payload.newRecord;
          final targetId = newRecord['academic_id']?.toString();
          final title = newRecord['title']?.toString() ?? 'إشعار جديد من الكلية';
          final body = newRecord['body']?.toString() ?? 'لديك تنبيه جديد في التطبيق';

          // التحقق: هل الإشعار موجه لهذا الطالب تحديداً أم عام لكافة الطلاب
          if (targetId == null ||
              targetId.isEmpty ||
              (currentStudentAcademicId != null &&
                  targetId == currentStudentAcademicId)) {
            showSystemNotification(
              title: title,
              body: body,
              payload: 'notifications',
            );
          }
        },
      ).subscribe();
    } catch (e) {
      debugPrint('Error starting Supabase notification listener: $e');
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
        showWhen: true,
        enableVibration: true,
        playSound: true,
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
    if (_realtimeChannel != null) {
      try {
        Supabase.instance.client.removeChannel(_realtimeChannel!);
      } catch (_) {}
      _realtimeChannel = null;
    }
  }
}
