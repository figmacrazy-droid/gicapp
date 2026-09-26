import 'package:flutter/material.dart';

class AppColors {
  // اللون البرتقالي / الذهبي
  static const Color gold = Color(0xFFD39706);
  static const Color orange = Color(0xFFD39706);

  // لون الكتابة الرمادي
  static const Color textGrey = Color(0xFFC9C9C9);

  // الأبيض
  static const Color white = Color(0xFFFFFFFF);

  // 🌑 الخلفية الكُحلي — تدرج يميل للون الفاتح مع الحفاظ على بعض الغموض
  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.centerRight,
    end: Alignment.centerLeft,
    colors: [
      Color(0xFF091527),
      Color(0xFF061839),
      Color(0xFF002766),
    ],
    stops: [0.0, 0.4, 1.0],
  );

  // 🌊 الزر الكحلي — متوافق مع الخلفية
  static const LinearGradient buttonGradient = LinearGradient(
    begin: Alignment.centerRight,
    end: Alignment.centerLeft,
    colors: [
      Color(0xFF091527),
      Color(0xFF061839),
      Color(0xFF002766),
    ],
    stops: [0.0, 0.4, 1.0],
  );
}