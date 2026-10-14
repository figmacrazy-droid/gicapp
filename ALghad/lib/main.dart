import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://mpcyblhdfecveamaessd.supabase.co',
    anonKey: 'sb_publishable__JN9KI2E5PMF680CUF-ydQ_DijaqBYH',
  );

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
      debugShowCheckedModeBanner: false,
      title: 'GIC Login',
      theme: ThemeData(fontFamily: 'LamaSans', primarySwatch: Colors.blue),
      home: const SplashScreen(), // 🚀 شاشة الأنيميشن البداية
    );
  }
}