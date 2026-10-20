import 'dart:convert';
import 'dart:io';
import 'package:gic/services/fcm_sender_service.dart';

/// جسر محلي اختياري لبيئة الويب فقط (يعتمد على FcmSenderService المشفر بدون أي مفاتيح نصية صريحة)
void main() async {
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 8099);
  // ignore: avoid_print
  print('FCM Bridge Server running on http://127.0.0.1:8099');

  await for (HttpRequest request in server) {
    request.response.headers.add('Access-Control-Allow-Origin', 'http://localhost');
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

        final ok = await FcmSenderService.sendToTopic(
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
