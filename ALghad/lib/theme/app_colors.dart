import 'package:flutter/material.dart';

class AppColors {
  static const Color gold = Color(0xFFD4A51C);

  // 🌑 الخلفية — من اليسار لليمين
  //    من كحلي غامق (#03102E) → كحلي أغمق (#01081B) → شبه أسود (#000208)
  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [
      Color(0xFF03102E),
      Color(0xFF01081B),
      Color(0xFF000208),
    ],
    stops: [0.0, 0.5, 1.0],
  );

  // 🌊 الزر — معكوس على الخلفية (من اليمين لليسار)
  //    من كحلي غامق (#03102E) على اليمين → شبه أسود (#000208) على اليسار
  static const LinearGradient buttonGradient = LinearGradient(
    begin: Alignment.centerRight,   // ← يبدأ من اليمين
    end: Alignment.centerLeft,      // ← ينتهي عند اليسار
    colors: [
      Color(0xFF03102E), // نفس لون الخلفية الأول
      Color(0xFF01081B), // نفس لون الخلفية الثاني
      Color(0xFF000208), // نفس لون الخلفية الثالث
    ],
    stops: [0.0, 0.5, 1.0],
  );
}