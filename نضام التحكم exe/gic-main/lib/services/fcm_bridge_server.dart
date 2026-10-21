import 'dart:convert';
import 'dart:io';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:http/http.dart' as http;

const String _shieldMask = 'GIC_FCM_SHIELD_KEY_2026_ALGHAD_SECURE';
const String _encClientEmail = 'ISAxOiQiPjp+KS0oJSosLy50OVBDRFUfICAgICAgPiM1bTwzKGkuMDo0NSQ8NikqJiMxMT9rOjBf';
const String _encPrivateKey =
    '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'
    'Zmh0Gnx0EmYNCBoGHARkFBYcbnh/aGpD';

String _unshield(String encoded) {
  final mask = utf8.encode(_shieldMask);
  final bytes = base64Decode(encoded);
  final out = List<int>.generate(
    bytes.length,
    (i) => bytes[i] ^ mask[i % mask.length],
  );
  return utf8.decode(out);
}

Future<bool> _sendDirectFcm({
  required String topic,
  required String title,
  required String body,
  String? routeName,
}) async {
  try {
    final email = _unshield(_encClientEmail);
    final key = _unshield(_encPrivateKey);
    final now = DateTime.now().toUtc();
    final jwt = JWT({
      'iss': email,
      'scope': 'https://www.googleapis.com/auth/firebase.messaging',
      'aud': 'https://oauth2.googleapis.com/token',
      'exp': now.add(const Duration(minutes: 60)).millisecondsSinceEpoch ~/ 1000,
      'iat': now.millisecondsSinceEpoch ~/ 1000,
    });
    final rsaKey = RSAPrivateKey(key);
    final signedJwt = jwt.sign(rsaKey, algorithm: JWTAlgorithm.RS256);

    final tokenRes = await http.post(
      Uri.parse('https://oauth2.googleapis.com/token'),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'grant_type': 'urn:ietf:params:oauth:grant-type:jwt-bearer',
        'assertion': signedJwt,
      },
    );
    if (tokenRes.statusCode != 200) return false;
    final token = jsonDecode(tokenRes.body)['access_token'];
    final safeTopic = topic.replaceAll(RegExp(r'[^a-zA-Z0-9-_.~%]+'), '_');

    final res = await http.post(
      Uri.parse('https://fcm.googleapis.com/v1/projects/alghadapp/messages:send'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode({
        'message': {
          'topic': safeTopic,
          'notification': {'title': title, 'body': body},
          'data': {
            'title': title,
            'body': body,
            'route': routeName ?? 'notifications',
            'click_action': 'FLUTTER_NOTIFICATION_CLICK',
          },
          'android': {
            'priority': 'HIGH',
            'ttl': '2419200s',
            'notification': {
              'sound': 'default',
              'channel_id': 'alghad_notifications_channel',
              'default_sound': true,
              'default_vibrate_timings': true,
              'notification_priority': 'PRIORITY_MAX',
              'visibility': 'PUBLIC',
            },
          },
        },
      }),
    );
    return res.statusCode == 200;
  } catch (_) {
    return false;
  }
}

/// جسر محلي مستقل لبيئة الويب (Pure Dart بدون أي اعتماد على مكتبات Flutter UI)
void main() async {
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 8099);
  // ignore: avoid_print
  print('FCM Bridge Server running on http://127.0.0.1:8099');

  await for (HttpRequest request in server) {
    request.response.headers.add('Access-Control-Allow-Origin', '*');
    request.response.headers.add('Access-Control-Allow-Methods', 'POST, OPTIONS');
    request.response.headers.add('Access-Control-Allow-Headers', 'Content-Type');

    if (request.method == 'OPTIONS') {
      request.response.statusCode = HttpStatus.ok;
      await request.response.close();
      continue;
    }

    if (request.method == 'POST' && request.uri.path == '/send') {
      try {
        final content = await utf8.decoder.bind(request).join();
        final data = jsonDecode(content) as Map<String, dynamic>;
        final topic = data['topic']?.toString() ?? 'all_students';
        final title = data['title']?.toString() ?? 'إشعار جديد';
        final body = data['body']?.toString() ?? '';
        final route = data['routeName']?.toString();

        final ok = await _sendDirectFcm(
          topic: topic,
          title: title,
          body: body,
          routeName: route,
        );

        request.response.statusCode = ok ? HttpStatus.ok : HttpStatus.internalServerError;
        request.response.write(jsonEncode({'success': ok}));
      } catch (e) {
        request.response.statusCode = HttpStatus.badRequest;
        request.response.write(jsonEncode({'error': e.toString()}));
      }
    } else {
      request.response.statusCode = HttpStatus.ok;
      request.response.write('FCM Bridge is Active');
    }
    await request.response.close();
  }
}
