import 'dart:convert';
import 'dart:io';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:flutter/foundation.dart';
import 'package:gic/services/auth_service.dart';
import 'package:gic/services/supabase_service.dart';
import 'package:http/http.dart' as http;

class FcmSenderService {
  static const String _shieldMask = 'GIC_FCM_SHIELD_KEY_2026_ALGHAD_SECURE';
  static const String _encClientEmail = 'ISAxOiQiPjp+KS0oJSosLy50OVBDRFUfICAgICAgPiM1bTwzKGkuMDo0NSQ8NikqJiMxMT9rOjBf';
  static const String _encPrivateKey =
    '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'
    'Zmh0Gnx0EmYNCBoGHARkFBYcbnh/aGpD';

  static String? _cachedAccessToken;
  static DateTime? _tokenExpiry;

  static String _unshield(String encoded) {
    final mask = utf8.encode(_shieldMask);
    final bytes = base64Decode(encoded);
    final out = List<int>.generate(
      bytes.length,
      (i) => bytes[i] ^ mask[i % mask.length],
    );
    return utf8.decode(out);
  }

  /// يسمح بتحميل ملف حساب خدمة خارجي محلياً إن وُجد (اختياري لتدوير المفاتيح مستقبلاً)
  static Map<String, String> _resolveCredentials() {
    if (!kIsWeb) {
      try {
        final extFile = File('fcm_service_account.json');
        if (extFile.existsSync()) {
          final map = jsonDecode(extFile.readAsStringSync()) as Map<String, dynamic>;
          final email = map['client_email']?.toString() ?? '';
          final key = map['private_key']?.toString() ?? '';
          if (email.isNotEmpty && key.isNotEmpty) {
            return {'client_email': email, 'private_key': key};
          }
        }
      } catch (_) {}
    }
    return {
      'client_email': _unshield(_encClientEmail),
      'private_key': _unshield(_encPrivateKey),
    };
  }

  static Future<String?> getAccessToken() async {
    if (_cachedAccessToken != null &&
        _tokenExpiry != null &&
        DateTime.now().isBefore(_tokenExpiry!)) {
      return _cachedAccessToken;
    }

    try {
      final creds = _resolveCredentials();
      final now = DateTime.now().toUtc();
      final jwt = JWT({
        'iss': creds['client_email'],
        'scope': 'https://www.googleapis.com/auth/firebase.messaging',
        'aud': 'https://oauth2.googleapis.com/token',
        'exp': now.add(const Duration(minutes: 60)).millisecondsSinceEpoch ~/ 1000,
        'iat': now.millisecondsSinceEpoch ~/ 1000,
      });

      final rsaKey = RSAPrivateKey(creds['private_key']!);
      final signedJwt = jwt.sign(rsaKey, algorithm: JWTAlgorithm.RS256);

      final response = await http.post(
        Uri.parse('https://oauth2.googleapis.com/token'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'grant_type': 'urn:ietf:params:oauth:grant-type:jwt-bearer',
          'assertion': signedJwt,
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _cachedAccessToken = data['access_token'];
        final expiresIn = data['expires_in'] ?? 3600;
        _tokenExpiry = DateTime.now().add(Duration(seconds: (expiresIn as int) - 60));
        return _cachedAccessToken;
      } else {
        debugPrint('Failed to get Google Access Token: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error getting Google Access Token: $e');
    }
    return null;
  }

  /// إرسال إشعار فوري لقناة (Topic) عبر Firebase Cloud Messaging HTTP v1
  /// - لجميع الطلاب: topic = 'all_students'
  /// - لطالب محدد: topic = 'student_$academicId'
  static Future<bool> sendToTopic({
    required String topic,
    required String title,
    required String body,
    String? routeName,
  }) async {
    // التحقق الأمني: لا يُسمح بإرسال إشعارات إلا لمستخدم مسجل ونشط في لوحة التحكم
    if (!AuthService.isLoggedIn || AuthService.currentUser?.isActive != true) {
      debugPrint('FCM blocked: unauthorized caller');
      return false;
    }

    final safeTopic = topic.replaceAll(RegExp(r'[^a-zA-Z0-9-_.~%]+'), '_');

    // 1. محاولة الإرسال عبر دالة الخادم السحابية (Supabase Edge Function: send-push) إن وُجدت
    try {
      final fnRes = await AdminSupabase.client.functions.invoke(
        'send-push',
        body: {
          'topic': safeTopic,
          'title': title,
          'body': body,
          'routeName': routeName ?? 'notifications',
        },
      );
      if (fnRes.status == 200 && fnRes.data is Map && fnRes.data['success'] == true) {
        debugPrint('FCM sent via Supabase Edge Function to topic: $safeTopic');
        return true;
      }
    } catch (_) {}

    // 2. في بيئة الويب نستخدم الجسر المحلي إن كان يعمل
    if (kIsWeb) {
      try {
        final res = await http.post(
          Uri.parse('http://127.0.0.1:8099/send'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'topic': safeTopic,
            'title': title,
            'body': body,
            'routeName': routeName,
          }),
        );
        if (res.statusCode == 200) {
          debugPrint('FCM sent via local web bridge successfully');
          return true;
        }
      } catch (_) {}
    }

    // 3. الإرسال المشفر المباشر عبر FCM HTTP v1 (يعمل فوراً من برنامج سطح المكتب EXE)
    try {
      final token = await getAccessToken();
      if (token == null) return false;

      final url = Uri.parse('https://fcm.googleapis.com/v1/projects/alghadapp/messages:send');
      final payload = {
        'message': {
          'topic': safeTopic,
          'notification': {
            'title': title,
            'body': body,
          },
          'data': {
            'title': title,
            'body': body,
            'route': routeName ?? 'notifications',
            'click_action': 'FLUTTER_NOTIFICATION_CLICK',
          },
          'android': {
            'priority': 'HIGH',
            'notification': {
              'sound': 'default',
              'channel_id': 'alghad_notifications_channel',
              'default_sound': true,
              'default_vibrate_timings': true,
            },
          },
        },
      };

      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        debugPrint('FCM sent successfully to topic: $safeTopic');
        return true;
      } else {
        debugPrint('FCM send error (${response.statusCode}): ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('Error sending FCM push: $e');
      return false;
    }
  }
}