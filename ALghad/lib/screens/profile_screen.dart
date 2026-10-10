import 'package:flutter/material.dart';
import '../models/app_models.dart';
import '../services/auth_service.dart';
import '../services/data_service.dart';
import 'dynamic_instruction_screen.dart';
import 'login_screen.dart';
import 'settings_screen.dart';
import 'social_media_screen.dart';
import 'university_guide_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const Color navyDark = Color(0xFF0B1E3D);
  static const Color accentGold = Color(0xFFD39706);

  StudentProfileModel? _student;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  void _loadProfile() async {
    final session = await AuthService.getSavedSession();
    setState(() {
      _student = session ??
          const StudentProfileModel(
            academicId: '2024000001',
            fullName: 'عبد الله أحمد الطالب',
            password: 'studentpassword',
            email: 'abdallah@alghad.edu.ye',
            specialty: 'علوم مختبرات طبية',
            level: 'المستوى الثاني',
            batch: 'الدفعة الخامسة',
            semester: 'الفصل الأول',
            group: 'المجموعة الأولى',
            studyShift: 'الفترة الصباحية',
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: navyDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'الملف الشخصي للطالب',
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
              children: [
                // 1. Top Card with Student Details
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: navyDark,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const CircleAvatar(
                            radius: 26,
                            backgroundColor: accentGold,
                            child: Icon(Icons.person, color: Colors.white, size: 30),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _student?.fullName ?? 'طالب الغد المشرق',
                                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'الرقم الأكاديمي: ${_student?.academicId ?? '----------'}',
                                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Divider(color: Colors.white24, height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildProfileMetaItem('التخصص:', _student?.specialty ?? 'علوم مختبرات'),
                          _buildProfileMetaItem('المستوى:', _student?.level ?? 'المستوى الثاني'),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // 2. Profile Options List
                _buildOptionTile(
                  icon: Icons.picture_as_pdf_outlined,
                  title: 'دليل الطالب الجامعي',
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (c) => const UniversityGuideScreen()));
                  },
                ),
                _buildOptionTile(
                  icon: Icons.share_outlined,
                  title: 'حسابات التواصل الاجتماعي',
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (c) => const SocialMediaScreen()));
                  },
                ),
                _buildOptionTile(
                  icon: Icons.info_outline_rounded,
                  title: 'معلومات عنا',
                  onTap: () async {
                    final info = await DataService.getAboutUsInfo();
                    if (context.mounted) {
                      Navigator.push(context, MaterialPageRoute(builder: (c) => DynamicInstructionScreen(info: info)));
                    }
                  },
                ),
                _buildOptionTile(
                  icon: Icons.settings_outlined,
                  title: 'إعدادات التطبيق',
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (c) => const SettingsScreen()));
                  },
                ),
                _buildOptionTile(
                  icon: Icons.help_outline_rounded,
                  title: 'المساعدة والدعم',
                  onTap: () async {
                    final info = await DataService.getHelpAndSupportInfo();
                    if (context.mounted) {
                      Navigator.push(context, MaterialPageRoute(builder: (c) => DynamicInstructionScreen(info: info)));
                    }
                  },
                ),
                const SizedBox(height: 16),
                _buildOptionTile(
                  icon: Icons.logout_rounded,
                  title: 'تسجيل الخروج',
                  titleColor: Colors.red,
                  iconColor: Colors.red,
                  onTap: _showLogoutConfirmationDialog,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileMetaItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white60, fontSize: 11)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(color: accentGold, fontSize: 13, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color titleColor = navyDark,
    Color iconColor = navyDark,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEEEEEE)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: ListTile(
        leading: Icon(icon, color: iconColor),
        title: Text(title, style: TextStyle(color: titleColor, fontWeight: FontWeight.bold, fontSize: 14)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }

  void _showLogoutConfirmationDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تسجيل الخروج'),
        content: const Text('هل أنت تأكد من تسجيل الخروج من التطبيق؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              await AuthService.clearSession();
              if (mounted) {
                Navigator.pop(ctx);
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('تسجيل الخروج', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
