import 'dart:convert';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class FcmSenderService {
  static const String _clientEmail =
      "firebase-adminsdk-fbsvc@alghadapp.iam.gserviceaccount.com";
  static const String _privateKey =
      "-----BEGIN PRIVATE KEY-----\nMIIEvgIBADANBgkqhkiG9w0BAQEFAASCBKgwggSkAgEAAoIBAQDfLwDzTPkmGigk\nTmokTD9I+AmnknuHQ37/bMYmvWg7RHm+wUpC8Ez750ehxrPj+Dk9GJTIJ4GnQwJe\n41dkziQmOtu0scY25V9TPsZjkAli8g6OC752O1h8QBuROUgFkGBnhbZlPu4XUjNd\njpnWsUHPHzUrDgYCFM51c8Tng74Q/iPz4dRBZf7Y6qPvMCd8OiFyfcJtUfu1fHA+\nRm1jqohIodF5aKUVTA/QgVHw3T1l5UYkl5bG/ti5P5L9UeiTTbJy0OXMfQseH117\nyuGUTBIYGWjZGRGa1XIzRD5CBVwPw1rxDZQEpI24xd4UCrkIPhEIV/clM/bsOfZf\ndPzVmfo5AgMBAAECggEAUcyUeJf5qTFlDQmAdZVMjJ38S+KwS789SLjBV2mMTkym\noneNlEMmtBzscCq3vBI6SF4+Ca4RIxC4SbbhTR0QusJPzEZr86rV6VjUtaERD6bQ\nFtfPEt5lbATDFdL8xq1H6Cll1G3gLcP+94dQcxO8nwE9J26YXSLrGLk5rfDnNKqB\noyboJ+A2/c3jDs8JRVhBXxjPguCvrVekGPcxq9gLFJx8kZTE+v1+Lp839pMjxe6B\ngiiHp1R2xgM2w7TymfUAa7N2TNNRTXzqgBNdHOw+jKKhCWa/Fl1GKKrm5hO6NPZZ\n13lhWJ6YRsRLFHrxrxj18QVF4rFa1mYvjRSQSBWwEQKBgQDwARrRcvfosPShdif0\nUGZdLSt8WB3dWuv/xOhfsmgWCPR+JByPizCdSlF5C27O2CNkjtrCShAHVHlquEVT\nQ0I4p3FXSN7TFmr9odJN9hWVRmFHljzqpGMhYSwsgZPlFwIo0PKAomb8i3DaCEvi\nPFtJrsFmf7ONXmgri9G+AJG2pwKBgQDuDuh72WHdDS3j0EaRgoXO2aeNBjzqfiA4\nBiSZ6p9vrxOrmanNftOEIS3F/dNxUDdg6sPYSJ+LUwSwXB2ccZmKPhhMebXbQZLz\npJ6cvO94P5Ewm6m236KRjoMp0/C3NaBBMofclNgjWEFtrXdoqI8gFj1DspjzmKMM\nOw9CG5vEHwKBgGDA0ULmijJwQ+5jZ7ACSYH+l61FCKUX5lPx2YvarENV0NqZTDpB\n7pM6RqX5ie4xC/OZ826n1NZfo6L2LlxmnOeh+PsrEUkfnHorJlDvh7vp54Wod15Q\nbvYh6mD2y9xq7h/uPBTHY6UjwZbkCVNm6ZZGsQjVKlkvWedUMnXaXOO5AoGBAJks\n/IhcOm0awtFYPV/5ZRHQ2M+UGPQlTaPeyARFhGs/ct+ykyDHn1/gXWyNQ1Ug8VEq\nHfP33riuJVE5JFB6g/oAtG/YzJwU2HJvFSPzKf7soAZv0sb5pMgVs+3hEn1AQypQ\nUj0rhNtROWBSAohUFSvnQ2pg66uqJheDlPDLhPGvAoGBAMUwdB6tJ78n+tktmBrk\nEwNcnRYhRQqs4yaugy8Fuxqdx3Deivj3+DzPi6ukmoKg6tVA6y2btHODgqHwEWF1\nZkunVCOQnOne8Ps4Ce0ALXFLxq7e2OB94tcVlOpeLLFZ6pqAvYGtVmHt8WPbat4H\nZiHahcM37EwJCplIdtV4JSlE\n-----END PRIVATE KEY-----\n";

  static String? _cachedAccessToken;
  static DateTime? _tokenExpiry;

  /// الحصول على Google OAuth2 Access Token مع التخزين المؤقت
  static Future<String?> _getAccessToken() async {
    if (_cachedAccessToken != null &&
        _tokenExpiry != null &&
        DateTime.now().isBefore(_tokenExpiry!)) {
      return _cachedAccessToken;
    }

    try {
      final now = DateTime.now().toUtc();
      final jwt = JWT({
        'iss': _clientEmail,
        'scope': 'https://www.googleapis.com/auth/firebase.messaging',
        'aud': 'https://oauth2.googleapis.com/token',
        'exp': now.add(const Duration(minutes: 60)).millisecondsSinceEpoch ~/ 1000,
        'iat': now.millisecondsSinceEpoch ~/ 1000,
      });

      final rsaKey = RSAPrivateKey(_privateKey);
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
        _tokenExpiry = DateTime.now().add(Duration(seconds: expiresIn - 60));
        return _cachedAccessToken;
      } else {
        debugPrint('Failed to get Google Access Token: ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('Error getting Google Access Token: $e');
      return null;
    }
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
    try {
      final token = await _getAccessToken();
      if (token == null) return false;

      // تهيئة اسم القناة ليكون صالحاً في Firebase
      final safeTopic = topic.replaceAll(RegExp(r'[^a-zA-Z0-9-_.~%]+'), '_');

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
