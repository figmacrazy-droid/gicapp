import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/splash_screen.dart';
import 'services/auth_service.dart';
import 'services/system_notification_service.dart';

final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://mpcyblhdfecveamaessd.supabase.co',
    anonKey: 'sb_publishable__JN9KI2E5PMF680CUF-ydQ_DijaqBYH',
  );

  // تهيئة خدمة إشعارات شريط الهاتف
  await SystemNotificationService.init(appNavigatorKey);

  // بدء الاستماع للإشعارات الواردة للطالب
  try {
    final session = await AuthService.getSavedSession();
    SystemNotificationService.startRealtimeListener(session?.academicId);
  } catch (_) {}

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: appNavigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'GIC Login',
      theme: ThemeData(fontFamily: 'LamaSans', primarySwatch: Colors.blue),
      home: const SplashScreen(), // 🚀 شاشة الأنيميشن البداية
    );
  }
}