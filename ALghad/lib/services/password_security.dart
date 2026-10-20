import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';

/// خدمة التشفير والتحقق الآمن لكلمات المرور والجلسات (Salted HMAC-SHA256)
class PasswordSecurity {
  static const String _prefix = 'gic\$v1\$';
  static const String _pepper = 'GIC_ALGHAD_SECURE_PEPPER_2026_V1';
  static const int _iterations = 1000;

  /// هل النص مشفر مسبقاً؟
  static bool isHashed(String? value) {
    if (value == null || value.isEmpty) return false;
    final trimmed = value.trim();
    return trimmed.startsWith(_prefix) ||
        trimmed.startsWith(r'$2a$') ||
        trimmed.startsWith(r'$2b$') ||
        trimmed.startsWith(r'$2y$');
  }

  /// توليد Salt عشوائي آمن (16 بايت = 32 حرف ست عشري)
  static String _generateSalt([int length = 16]) {
    final rng = Random.secure();
    final bytes = List<int>.generate(length, (_) => rng.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  /// توليد رمز جلسة عشوائي آمن (32 بايت = 64 حرف ست عشري)
  static String generateSessionToken() => _generateSalt(32);

  /// حساب الهاش المملح مع تكرارات متعددة ضد هجمات القوة الغاشمة
  static String _computeHash(String password, String saltHex) {
    final key = utf8.encode('$_pepper:$saltHex');
    final hmac = Hmac(sha256, key);
    List<int> digest = hmac.convert(utf8.encode(password)).bytes;
    for (int i = 1; i < _iterations; i++) {
      digest = hmac.convert(digest).bytes;
    }
    return digest.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  /// تشفير كلمة المرور (إذا كانت مشفرة مسبقاً تُعاد كما هي)
  static String hashPassword(String plainPassword) {
    final clean = plainPassword.trim();
    if (clean.isEmpty) return '';
    if (isHashed(clean)) return clean;
    final salt = _generateSalt(16);
    final hash = _computeHash(clean, salt);
    return '$_prefix$salt\$$hash';
  }

  /// مقارنة آمنة بثبات زمني (Constant-time comparison) لمنع هجمات التوقيت
  static bool _constantTimeEquals(String a, String b) {
    if (a.length != b.length) return false;
    int diff = 0;
    for (int i = 0; i < a.length; i++) {
      diff |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return diff == 0;
  }

  /// التحقق من صحة كلمة المرور المدخلة مقارنة بالمخزنة
  static bool verifyPassword(String inputPassword, String? storedPassword) {
    if (storedPassword == null || storedPassword.isEmpty) return false;
    final cleanInput = inputPassword.trim();
    final cleanStored = storedPassword.trim();
    if (cleanInput.isEmpty) return false;

    if (cleanStored.startsWith(_prefix)) {
      final parts = cleanStored.substring(_prefix.length).split('\$');
      if (parts.length != 2) return false;
      final salt = parts[0];
      final expectedHash = parts[1];
      final actualHash = _computeHash(cleanInput, salt);
      return _constantTimeEquals(actualHash, expectedHash);
    }

    // توافق مع السجلات النصية القديمة (يتم ترقيتها تلقائياً عند نجاح الدخول)
    return _constantTimeEquals(cleanInput, cleanStored);
  }
}
