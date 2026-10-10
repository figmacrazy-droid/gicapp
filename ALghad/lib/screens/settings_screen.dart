import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const Color navyDark = Color(0xFF0B1E3D);

  String _selectedLanguage = 'العربية';
  final _oldPassController = TextEditingController();
  final _newPassController = TextEditingController();
  final _confirmPassController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: navyDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'إعدادات التطبيق',
          style: TextStyle(
            color: navyDark,
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Language Section
                const Text(
                  'لغة التطبيق (App Language):',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: navyDark),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('اختر اللغة الفعالة:', style: TextStyle(fontSize: 13, color: Colors.grey)),
                      DropdownButton<String>(
                        value: _selectedLanguage,
                        underline: const SizedBox(),
                        items: const [
                          DropdownMenuItem(value: 'العربية', child: Text('العربية (Arabic)')),
                          DropdownMenuItem(value: 'English', child: Text('English (الإنجليزية)')),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _selectedLanguage = val);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('تم تغيير لغة التطبيق إلى: $val')),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // 2. Change Password Section
                const Text(
                  'تغيير كلمة السر:',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: navyDark),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    children: [
                      TextField(
                        controller: _oldPassController,
                        obscureText: true,
                        decoration: _inputDecoration('كلمة السر الحالية'),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _newPassController,
                        obscureText: true,
                        decoration: _inputDecoration('كلمة السر الجديدة (أحرف فقط)'),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _confirmPassController,
                        obscureText: true,
                        decoration: _inputDecoration('تأكيد كلمة السر الجديدة'),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _changePassword,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: navyDark,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                          ),
                          child: const Text('حفظ كلمة السر الجديدة', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _changePassword() {
    final oldP = _oldPassController.text.trim();
    final newP = _newPassController.text.trim();
    final confP = _confirmPassController.text.trim();

    if (oldP.isEmpty || newP.isEmpty || confP.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى تعبئة جميع حقول كلمة السر'), backgroundColor: Colors.red),
      );
      return;
    }

    if (!RegExp(r'^[a-zA-Z\u0600-\u06FF\s]+$').hasMatch(newP)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('كلمة السر يجب أن تحتوي على أحرف فقط ولا تقبل أرقام أو رموز'), backgroundColor: Colors.red),
      );
      return;
    }

    if (newP != confP) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('كلمة السر الجديدة غير متطابقة مع التأكيد'), backgroundColor: Colors.red),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم تحديث كلمة السر بنجاح!'), backgroundColor: Colors.green),
    );
    _oldPassController.clear();
    _newPassController.clear();
    _confirmPassController.clear();
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: const Color(0xFFF8F9FA),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
    );
  }
}
