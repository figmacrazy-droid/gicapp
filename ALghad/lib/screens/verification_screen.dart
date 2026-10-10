import 'package:flutter/material.dart';
import '../models/app_models.dart';
import '../services/auth_service.dart';
import 'home_screen.dart';

class VerificationScreen extends StatefulWidget {
  final StudentProfileModel student;

  const VerificationScreen({super.key, required this.student});

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  static const Color navyDark = Color(0xFF0B1E3D);

  final _otpController = TextEditingController();
  final String _mockOtp = '1234';
  bool _isVerifying = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: navyDark),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Icon(Icons.mark_email_read_outlined, size: 72, color: navyDark),
                const SizedBox(height: 20),
                const Text(
                  'كود التحقق من البريد الإلكتروني',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: navyDark),
                ),
                const SizedBox(height: 8),
                Text(
                  'تم إرسال رمز التحقق المؤلف من 4 أرقام إلى بريدك الإلكتروني:\n${widget.student.email}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13, color: Colors.grey, height: 1.5),
                ),
                const SizedBox(height: 30),
                TextField(
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 8),
                  maxLength: 4,
                  decoration: InputDecoration(
                    hintText: '----',
                    filled: true,
                    fillColor: const Color(0xFFF8F9FA),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'رمز التفعيل التجريبي للاختبار: $_mockOtp',
                  style: const TextStyle(fontSize: 12, color: Colors.amber, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isVerifying ? null : _verifyOtp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: navyDark,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                    ),
                    child: _isVerifying
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('تأكيد والدخول للتطبيق', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _verifyOtp() async {
    final input = _otpController.text.trim();
    if (input != _mockOtp) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('رمز التحقق غير صحيح. يرجى التأكد وإعادة المحاولة.'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isVerifying = true);

    // حفظ الجلسة محلياً ليعود إليها المستخدم بدون إدخال البيانات في المرات القادمة
    await AuthService.saveStudentSession(widget.student);

    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
        (route) => false,
      );
    }
  }
}