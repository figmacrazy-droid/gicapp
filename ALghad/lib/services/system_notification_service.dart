import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  static final Map<String, DateTime> _recentlyShownNotifications = {};
  static bool _isChecking = false;

  static const String _deliveredPrefKey = 'alghad_delivered_notification_ids';
  static const String _hasSeededPrefKey = 'alghad_has_seeded_notifications';

  /// تهيئة خدمة الإشعارات النظامية على الهاتف
  static Future<void> init(GlobalKey<NavigatorState> navigatorKey) async {
    _navKey = navigatorKey;
    await _loadDeliveredIdsFromPrefs();

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

        // إعداد واستقبال إشعارات Firebase Cloud Messaging السحابية
        try {
          final fcm = FirebaseMessaging.instance;
          await fcm.setAutoInitEnabled(true);
          await fcm.requestPermission(
            alert: true,
            badge: true,
            sound: true,
            provisional: false,
          );

          // 1. توليد رمز الجهاز أولاً لضمان جاهزية اشتراكات القنوات (Topics)
          final token = await fcm.getToken();
          if (token != null && token.isNotEmpty) {
            debugPrint('FCM Device Token: $token');
          }

          // 2. الاشتراك المؤكد في قناة الإشعارات العامة لجميع الطلاب
          await fcm.subscribeToTopic('all_students');

          // 3. إعادة الاشتراك تلقائياً عند تجديد رمز FCM من قبل النظام
          fcm.onTokenRefresh.listen((newToken) async {
            try {
              await fcm.subscribeToTopic('all_students');
              final activeId = _activeAcademicId;
              if (activeId != null && activeId.isNotEmpty) {
                final safeId = activeId.replaceAll(RegExp(r'[^a-zA-Z0-9-_.~%]+'), '_');
                await fcm.subscribeToTopic('student_$safeId');
              }
            } catch (_) {}
          });

          // الاستماع للإشعارات الواردة والتطبيق في الواجهة الأمامية (Foreground)
          FirebaseMessaging.onMessage.listen((RemoteMessage message) {
            final notif = message.notification;
            final title = notif?.title ?? message.data['title']?.toString() ?? 'إشعار جديد من الكلية';
            final body = notif?.body ?? message.data['body']?.toString() ?? '';
            if (title.isNotEmpty || body.isNotEmpty) {
              showSystemNotification(
                title: title,
                body: body,
                payload: 'notifications',
              );
            }
          });

          // التوجيه لشاشة الإشعارات عند النقر على إشعار وارد والتطبيق في الخلفية
          FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
            _handleNotificationClick('notifications');
          });
        } catch (fcmError) {
          debugPrint('FCM setup note: $fcmError');
        }

        _isInitialized = true;
      } catch (e) {
        debugPrint('Error initializing local notifications: $e');
      }
    }
  }

  /// تحميل الإشعارات التي تم إرسال تنبيه لها مسبقاً من الذاكرة الدائمة
  static Future<void> _loadDeliveredIdsFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_deliveredPrefKey) ?? [];
      _deliveredNotificationIds.addAll(list);
    } catch (_) {}
  }

  /// حفظ معرف إشعار تم إيصاله لمنع تكرار ظهوره مطلقاً عند إعادة فتح التطبيق
  static Future<void> _recordDeliveredId(String id) async {
    if (id.isEmpty) return;
    _deliveredNotificationIds.add(id);
    try {
      final prefs = await SharedPreferences.getInstance();
      // الاحتفاظ بآخر 500 معرف فقط لمنع تراكم الذاكرة
      final list = _deliveredNotificationIds.toList();
      final toSave = list.length > 500 ? list.sublist(list.length - 500) : list;
      await prefs.setStringList(_deliveredPrefKey, toSave);
    } catch (_) {}
  }

  /// تسجيل قائمة معرفات كمقروءة/معاينة لمنع إطلاق أي تنبيه نظامي عنها
  static Future<void> markIdsAsSeen(List<String> ids) async {
    if (ids.isEmpty) return;
    _deliveredNotificationIds.addAll(ids);
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = _deliveredNotificationIds.toList();
      final toSave = list.length > 500 ? list.sublist(list.length - 500) : list;
      await prefs.setStringList(_deliveredPrefKey, toSave);
    } catch (_) {}
  }

  /// الاستماع اللحظي لقاعدة البيانات وتوليد إشعار فوري في شريط الهاتف
  static void startRealtimeListener(String? currentStudentAcademicId) async {
    String? studentId = currentStudentAcademicId?.trim();
    if (studentId == null || studentId.isEmpty) {
      try {
        final session = await AuthService.getSavedSession();
        studentId = session?.academicId.trim();
      } catch (_) {}
    }

    // إذا تغير رقم الطالب السابق، نلغي اشتراك الرقم القديم فقط، ولا نلغي اشتراك نفس الطالب الحالي!
    final prevId = _activeAcademicId;
    if (prevId != null && prevId.isNotEmpty && prevId != studentId && !kIsWeb) {
      try {
        final safePrev = prevId.replaceAll(RegExp(r'[^a-zA-Z0-9-_.~%]+'), '_');
        await FirebaseMessaging.instance.unsubscribeFromTopic('student_$safePrev');
      } catch (_) {}
    }

    // إغلاق قناة Realtime القديمة فقط دون إلغاء اشتراكات FCM
    stopRealtimeListener(unsubscribeFcm: false);
    _activeAcademicId = studentId;

    if (!kIsWeb) {
      try {
        final fcm = FirebaseMessaging.instance;
        await fcm.getToken();
        await fcm.subscribeToTopic('all_students');
        if (studentId != null && studentId.isNotEmpty) {
          final safeId = studentId.replaceAll(RegExp(r'[^a-zA-Z0-9-_.~%]+'), '_');
          await fcm.subscribeToTopic('student_$safeId');
          debugPrint('Subscribed to FCM topics: all_students & student_$safeId');
        }
      } catch (e) {
        debugPrint('FCM topic subscribe note: $e');
      }
    }

    await _loadDeliveredIdsFromPrefs();

    // فحص التهيئة الأولية: عند أول تشغيل للتطبيق بعد التثبيت، نُسجّل الإشعارات التاريخية
    // كمعاينة مسبقاً حتى لا يتم إزعاج الطالب بتنبيهات قديمة عند تشغيل التطبيق لأول مرة
    try {
      final prefs = await SharedPreferences.getInstance();
      final hasSeeded = prefs.getBool(_hasSeededPrefKey) ?? false;
      if (!hasSeeded) {
        final supabase = Supabase.instance.client;
        var seedQuery = supabase.from('notifications').select('id');
        if (studentId != null && studentId.isNotEmpty) {
          seedQuery = seedQuery.or('academic_id.eq.$studentId,academic_id.is.null');
        } else {
          seedQuery = seedQuery.filter('academic_id', 'is', null);
        }
        final seedRes = await seedQuery.limit(50);
        if (seedRes.isNotEmpty) {
          for (var item in seedRes) {
            final sid = item['id']?.toString() ?? '';
            if (sid.isNotEmpty) _deliveredNotificationIds.add(sid);
          }
        }
        await prefs.setBool(_hasSeededPrefKey, true);
        await prefs.setStringList(_deliveredPrefKey, _deliveredNotificationIds.toList());
      }
    } catch (_) {}

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

    // فحص الإشعارات الجديدة مرة واحدة عند فتح التطبيق مع إلغاء المؤقت الدوري لمنع التكرار مع FCM
    _pollTimer?.cancel();
    _pollTimer = null;
    _checkForNewNotifications();
  }

  /// فحص الإشعارات الجديدة من قاعدة البيانات (فقط غير المقروءة والتي لم يصدر لها تنبيه)
  static Future<void> _checkForNewNotifications() async {
    if (_isChecking) return;
    _isChecking = true;
    try {
      final supabase = Supabase.instance.client;
      final studentId = _activeAcademicId;

      var query = supabase
          .from('notifications')
          .select('id, academic_id, title, body, created_at, is_read')
          .eq('is_read', false); // شرط أساسي: غير مقروءة فقط

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

        // إذا كان الإشعار تم عرضه أو تنبيهه مسبقاً، يتم تجاوزه تماماً
        if (_deliveredNotificationIds.contains(id)) continue;

        // إذا كان الإشعار قد تم قراءته (is_read == true)، نتجاوزه تماماً
        if (item['is_read'] == true) {
          await _recordDeliveredId(id);
          continue;
        }

        // إشعار جديد غير مقروء ولم يتم التنبيه عنه من قبل
        await _recordDeliveredId(id);
        final title = item['title']?.toString() ?? 'إشعار جديد من الكلية';
        final body = item['body']?.toString() ?? 'لديك تنبيه جديد في التطبيق';

        await showSystemNotification(
          title: title,
          body: body,
          payload: 'notifications',
        );
      }
    } catch (e) {
      debugPrint('Error polling notifications: $e');
    } finally {
      _isChecking = false;
    }
  }

  static void _processNotificationRecord(Map<String, dynamic> record) {
    final id = record['id']?.toString() ?? '';
    final targetId = record['academic_id']?.toString().trim();
    final title = record['title']?.toString() ?? 'إشعار جديد من الكلية';
    final body = record['body']?.toString() ?? 'لديك تنبيه جديد في التطبيق';
    final isRead = record['is_read'] == true;

    // إذا تمت قراءته أو سبق إيصاله يتم تجاهله
    if (isRead) return;
    if (id.isNotEmpty && _deliveredNotificationIds.contains(id)) return;
    if (id.isNotEmpty) _recordDeliveredId(id);

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

    // حماية قاطعة لمنع تكرار الإشعار:
    // إذا وصل نفس الإشعار (العنوان والمحتوى) خلال آخر 15 ثانية، يتم إهماله فوراً
    final dedupeKey = '${title.trim()}:::${body.trim()}';
    final now = DateTime.now();
    if (_recentlyShownNotifications.containsKey(dedupeKey)) {
      final diff = now.difference(_recentlyShownNotifications[dedupeKey]!).inSeconds;
      if (diff < 15) {
        debugPrint('[Notifications Deduplication]: Suppressed duplicate notification within ${diff}s: "$title"');
        return;
      }
    }
    _recentlyShownNotifications[dedupeKey] = now;

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

  /// حذف جميع الإشعارات من شريط إشعارات الهاتف العلوي (عند قراءتها في التطبيق)
  static Future<void> clearAllSystemNotifications() async {
    if (kIsWeb) return;
    try {
      await _notificationsPlugin.cancelAll();
      debugPrint('Cleared all notifications from system tray');
    } catch (e) {
      debugPrint('Error clearing system notifications: $e');
    }
  }

  /// حذف إشعار محدد من شريط إشعارات الهاتف
  static Future<void> cancelNotification(int id) async {
    if (kIsWeb) return;
    try {
      await _notificationsPlugin.cancel(id);
    } catch (e) {
      debugPrint('Error canceling system notification: $e');
    }
  }

  /// التوجيه التلقائي لشاشة الإشعارات عند النقر على إشعار الهاتف
  static void _handleNotificationClick(String? payload) {
    clearAllSystemNotifications();
    if (_navKey?.currentState != null) {
      _navKey!.currentState!.push(
        MaterialPageRoute(builder: (context) => const NotificationsScreen()),
      );
    }
  }

  /// إيقاف الاستماع عند تسجيل الخروج
  static void stopRealtimeListener({bool unsubscribeFcm = true}) {
    if (unsubscribeFcm && _activeAcademicId != null && _activeAcademicId!.isNotEmpty && !kIsWeb) {
      try {
        final safeId = _activeAcademicId!.replaceAll(RegExp(r'[^a-zA-Z0-9-_.~%]+'), '_');
        FirebaseMessaging.instance.unsubscribeFromTopic('student_$safeId');
      } catch (_) {}
      _activeAcademicId = null;
    }
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
