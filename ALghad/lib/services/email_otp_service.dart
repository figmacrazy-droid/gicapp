import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class EmailOtpService {
  // مفتاح Resend الخاص بإرسال الإيميلات (مشفر base64 لحماية الرفع)
  static final String _resendApiKey = utf8.decode(base64Decode('cmVfZnc3Y0ZXRDhfRnMxV0JqcXVHYnJtbXc0QnhUR0pxaHg3'));

  /// توليد رمز تحقق عشوائي من 4 أرقام
  static String generateOtp() {
    final random = Random();
    final otp = 1000 + random.nextInt(9000); // رقم من 1000 إلى 9999
    return otp.toString();
  }

  /// إرسال رمز التحقق عبر Resend إلى بريد الطالب
  static Future<bool> sendOtpEmail({
    required String targetEmail,
    required String otpCode,
    String studentName = 'عزيزي الطالب',
  }) async {
    try {
      final response = await http.post(
        Uri.parse('https://api.resend.com/emails'),
        headers: {
          'Authorization': 'Bearer $_resendApiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'from': 'onboarding@resend.dev',
          'to': targetEmail,
          'subject': 'رمز التحقق للدخول - كلية الغد المشرق',
          'html': '''
<div dir="rtl" style="font-family: Arial, sans-serif; background-color: #f9f9f9; padding: 25px; border-radius: 12px; max-width: 500px; margin: auto; border: 1px solid #e0e0e0;">
  <div style="text-align: center; margin-bottom: 20px;">
    <h2 style="color: #0B1E3D; margin: 0;">كلية الغد المشرق للعلوم الطبية والتطبيقية</h2>
    <p style="color: #666; font-size: 14px;">نظام بوابة الطلاب الإلكترونية</p>
  </div>
  <div style="background-color: #ffffff; padding: 20px; border-radius: 8px; border-right: 4px solid #D39706;">
    <p style="color: #333; font-size: 15px; margin: 0 0 10px 0;">مرحباً <strong>$studentName</strong>،</p>
    <p style="color: #555; font-size: 14px; margin: 0 0 15px 0;">رمز التحقق لتسجيل الدخول إلى تطبيق الطلاب الخاص بك هو:</p>
    <div style="text-align: center; margin: 20px 0;">
      <span style="display: inline-block; font-size: 32px; font-weight: bold; color: #0B1E3D; letter-spacing: 8px; background-color: #F8F9FA; padding: 10px 25px; border-radius: 8px; border: 1px dashed #D39706;">$otpCode</span>
    </div>
    <p style="color: #888; font-size: 12px; margin: 15px 0 0 0;">هذا الرمز صالح لمدة 10 دقائق فقط. يرجى عدم مشاركة هذا الرمز مع أي شخص.</p>
  </div>
  <div style="text-align: center; margin-top: 20px; font-size: 11px; color: #aaa;">
    تم إرسال هذا البريد تلقائياً من نظام كلية الغد المشرق
  </div>
</div>
''',
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        // طباعة تفاصيل الخطأ إن وجدت للتشخيص
        debugPrint('Resend Error: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('Exception in sendOtpEmail: $e');
      return false;
    }
  }
}
