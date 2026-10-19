import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:gic/view/login_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // تهيئة قاعدة البيانات للوحة التحكم
  await Supabase.initialize(
    url: 'https://mpcyblhdfecveamaessd.supabase.co',
    anonKey: 'sb_publishable__JN9KI2E5PMF680CUF-ydQ_DijaqBYH',
  );
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'كلية الغد الدولية - لوحة تحكم النظام الإداري',
      locale: const Locale('ar', ''),
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child!,
        );
      },
      home: const LoginScreen(),
    );
  }
}