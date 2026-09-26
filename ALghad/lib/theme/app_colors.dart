import 'package:flutter/material.dart';

class AppColors {
  // اللون البرتقالي / الذهبي
  static const Color gold = Color(0xFFD39706);
  static const Color orange = Color(0xFFD39706);

  // لون الكتابة الرمادي
  static const Color textGrey = Color(0xFFC9C9C9);

  // الأبيض
  static const Color white = Color(0xFFFFFFFF);

  // 🌑 الخلفية الكُحلي — تدرج يميل للون الفاتح أكثر
  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.centerRight,
    end: Alignment.centerLeft,
    colors: [
      Color(0xFF091527),
      Color(0xFF002060),
      Color(0xFF003380), // Added a slightly lighter shade at the end
    ],
    stops: [0.0, 0.25, 1.0],
  );

  // 🌊 الزر الكحلي — تدرج يميل للون الفاتح أكثر
  static const LinearGradient buttonGradient = LinearGradient(
    begin: Alignment.centerRight,
    end: Alignment.centerLeft,
    colors: [
      Color(0xFF091527),
      Color(0xFF002060),
      Color(0xFF003380),
    ],
    stops: [0.0, 0.25, 1.0],
  );
}