import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';

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
  bool _isSavingPassword = false;

  @override
  void dispose() {
    _oldPassController.dispose();
    _newPassController.dispose();
    _confirmPassController.dispose();
    super.dispose();
  }

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
                const SizedBox(height: 6),
                const Text(
                  'مسموح بالأحرف والأرقام والرموز (! @ #) فقط.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
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
                        decoration: _inputDecoration('كلمة السر الجديدة (أحرف، أرقام، !@# فقط)'),
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
                          onPressed: _isSavingPassword ? null : _changePassword,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: navyDark,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                          ),
                          child: _isSavingPassword
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                                )
                              : const Text('حفظ كلمة السر الجديدة', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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

  Future<void> _changePassword() async {
    final oldP = _oldPassController.text.trim();
    final newP = _newPassController.text.trim();
    final confP = _confirmPassController.text.trim();

    if (oldP.isEmpty || newP.isEmpty || confP.isEmpty) {
      _showMsg('يرجى تعبئة جميع حقول كلمة السر', isError: true);
      return;
    }

    if (newP.length < 6) {
      _showMsg('كلمة السر الجديدة يجب أن تكون 6 خانات على الأقل', isError: true);
      return;
    }

    // السماح فقط بالأحرف، الأرقام، وهذه الرموز الثلاثة فقط: ! @ #
    final validRegex = RegExp(r'^[a-zA-Z0-9\u0600-\u06FF!@#]+$');
    if (!validRegex.hasMatch(newP)) {
      _showMsg('كلمة السر تقبل فقط الأحرف، الأرقام، والرموز (! @ #) فقط', isError: true);
      return;
    }

    if (newP != confP) {
      _showMsg('كلمة السر الجديدة غير متطابقة مع التأكيد', isError: true);
      return;
    }

    setState(() => _isSavingPassword = true);

    try {
      final session = await AuthService.getSavedSession();
      if (session == null || session.academicId.isEmpty) {
        _showMsg('تعذر التعرف على جلسة الطالب الحالية، يرجى إعادة تسجيل الدخول', isError: true);
        return;
      }

      // 1. التحقق من مطابقة كلمة السر القديمة مع المسجل في Supabase
      final studentRes = await Supabase.instance.client
          .from('students')
          .select('id, academic_id, password')
          .eq('academic_id', session.academicId)
          .maybeSingle();

      if (studentRes == null) {
        _showMsg('لم يتم العثور على حساب الطالب في قاعدة البيانات', isError: true);
        return;
      }

      final dbPassword = (studentRes['password'] ?? '').toString();
      if (dbPassword != oldP) {
        _showMsg('كلمة السر الحالية غير صحيحة', isError: true);
        return;
      }

      // 2. تحديث كلمة السر في جدول students في Supabase
      await Supabase.instance.client
          .from('students')
          .update({'password': newP})
          .eq('academic_id', session.academicId);

      // 3. تحديث الجلسة المحفوظة في الهاتف
      final updatedProfile = session.copyWith(password: newP);
      await AuthService.saveStudentSession(updatedProfile);

      _showMsg('تم تغيير وتحديث كلمة السر في قاعدة البيانات بنجاح!');
      _oldPassController.clear();
      _newPassController.clear();
      _confirmPassController.clear();
    } catch (e) {
      _showMsg('فشل تحديث كلمة السر: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isSavingPassword = false);
    }
  }

  void _showMsg(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, textDirection: TextDirection.rtl),
        backgroundColor: isError ? Colors.red.shade700 : Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
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
