import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  final bool hideBottomNav;
  final String studentFullName;

  const ProfileScreen({
    super.key,
    this.hideBottomNav = false,
    this.studentFullName = 'عبدالله حمود محمد أبوطالب',
  });

  static const Color navyDark = Color(0xFF0A2451);
  static const Color textGray = Color(0xFF6B6B6B);
  static const Color gold = Color(0xFFD39706);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: SingleChildScrollView(
          child: Stack(
            children: [
              // 1. Background Layers
              _buildBackgrounds(),

              // 2. Main Content
              Column(
                children: [
                  const SizedBox(height: 55), // Top padding
                  
                  // AppBar Area
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.maybePop(context),
                          child: const Icon(
                            Icons.arrow_forward_rounded,
                            color: Colors.white,
                            size: 28,
                            textDirection: TextDirection.ltr, // Force pointing right
                          ),
                        ),
                        const Expanded(
                          child: Text(
                            'ملفي الشخصي',
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 28), // Placeholder on the left to center text
                      ],
                    ),
                  ),

                  // The card should start exactly at 175.25 from top.
                  // 55 (SizedBox) + 28 (AppBar approx) = 83.
                  // 175.25 - 83 = 92.25.
                  const SizedBox(height: 92.25),

                  // Profile Card
                  _buildProfileCard(),

                  const SizedBox(height: 25),

                  // Menu List
                  _buildMenuItems(),
                  
                  const SizedBox(height: 40),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBackgrounds() {
    return Column(
      children: [
        Container(
          height: 240, // Reduced slightly to match the look
          width: double.infinity,
          decoration: const BoxDecoration(
            color: navyDark,
          ),
          child: Stack(
            children: [
              Positioned(
                top: -50,
                right: -50,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.04),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Positioned(
                bottom: -20,
                right: -20,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: const BoxDecoration(
                    color: gold,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(100),
                      bottomLeft: Radius.circular(50),
                      topRight: Radius.circular(40),
                      bottomRight: Radius.circular(80),
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 20,
                left: -60,
                child: Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ),
        Container(
          height: 600, // Background for the list part
          color: Colors.white,
        ),
      ],
    );
  }

  Widget _buildProfileCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          // The White Card (width: 324 based on horizontal padding 18 on a 360 width screen, height ~154)
          Container(
            width: double.infinity,
            height: 154.76, // Setting height explicitly as requested
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(34),
                topRight: Radius.circular(24),
                bottomRight: Radius.circular(0),
                bottomLeft: Radius.circular(0),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(34),
                topRight: Radius.circular(24),
                bottomRight: Radius.circular(0),
                bottomLeft: Radius.circular(0),
              ),
              child: Stack(
                children: [
                  // Bottom Left Dark Blue Decoration
                  Positioned(
                    bottom: -15,
                    left: -20,
                    child: Container(
                      width: 70,
                      height: 70,
                      decoration: const BoxDecoration(
                        color: navyDark,
                        borderRadius: BorderRadius.only(
                          topRight: Radius.circular(50),
                          bottomRight: Radius.circular(30),
                          topLeft: Radius.circular(10),
                          bottomLeft: Radius.circular(50),
                        ),
                      ),
                    ),
                  ),
                  
                  // Card Content
                  Padding(
                    padding: const EdgeInsets.only(top: 55, bottom: 10, left: 16, right: 16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          studentFullName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: navyDark,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'الرقم الأكاديمي: 9876543210',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF6B6B6B),
                          ),
                        ),
                        const Spacer(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            const Text(
                              'تخصص: إدارة أعمال',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: textGray,
                              ),
                            ),
                            const Text(
                              'خريج',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: textGray,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Profile Avatar overlapping the top
          Positioned(
            top: -45.25,
            child: Container(
              width: 90.5,
              height: 90.5,
              padding: const EdgeInsets.all(3),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: CircleAvatar(
                radius: 45.25,
                backgroundColor: const Color(0xFFF2E8D0),
                child: ClipOval(
                  child: Image.asset(
                    'assets/images/avatar.png',
                    fit: BoxFit.cover,
                    width: 90.5,
                    height: 90.5,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(Icons.person, size: 50, color: gold);
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItems() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          _buildMenuItem(
            icon: Icons.person_outline_rounded,
            title: 'دليل الطالب الجامعي',
          ),
          _buildDivider(),
          _buildMenuItem(
            icon: Icons.favorite_border_rounded,
            title: 'تواصل إجتماعي',
          ),
          _buildDivider(),
          _buildMenuItem(
            icon: Icons.notifications_none_rounded,
            title: 'التنبيهات',
          ),
          _buildDivider(),
          _buildMenuItem(
            icon: Icons.shield_outlined,
            title: 'معلومات عنا',
          ),
          _buildDivider(),
          _buildMenuItem(
            icon: Icons.settings_outlined,
            title: 'إعدادات التطبيق',
          ),
          _buildDivider(),
          _buildMenuItem(
            icon: Icons.help_outline_rounded,
            title: 'المساعدة والدعم',
          ),
          _buildDivider(),
          _buildMenuItem(
            icon: Icons.logout_rounded,
            title: 'تسجيل الخروج',
            isLogout: true,
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    bool isLogout = false,
  }) {
    return InkWell(
      onTap: () {},
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            Icon(
              icon,
              color: isLogout ? Colors.black87 : const Color(0xFF4A4A4A),
              size: 26,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF4A4A4A),
                ),
              ),
            ),
            const Icon(
              Icons.chevron_left_rounded,
              color: Color(0xFFB0B0B0),
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(
      height: 1,
      thickness: 1,
      color: Color(0xFFF0F0F0),
    );
  }
}
