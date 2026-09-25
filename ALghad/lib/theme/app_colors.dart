import 'package:flutter/material.dart';

class AppColors {
  // اللون البرتقالي / الذهبي
  static const Color gold = Color(0xFFD39706);
  static const Color orange = Color(0xFFD39706);

  // لون الكتابة الرمادي
  static const Color textGrey = Color(0xFFC9C9C9);

  // الأبيض
  static const Color white = Color(0xFFFFFFFF);

  // 🌑 الخلفية الكُحلي — تدرج ثلاثة ألوان (0A131D → 091527 → 002060)
  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [
      Color(0xFF0A131D),
      Color(0xFF091527),
      Color(0xFF002060),
    ],
    stops: [0.0, 0.5, 1.0],
  );

  // 🌊 الزر الكحلي — معكوس على الخلفية
  static const LinearGradient buttonGradient = LinearGradient(
    begin: Alignment.centerRight,
    end: Alignment.centerLeft,
    colors: [
      Color(0xFF0A131D),
      Color(0xFF091527),
      Color(0xFF002060),
    ],
    stops: [0.0, 0.5, 1.0],
  );
}