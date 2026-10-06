import 'package:flutter/material.dart';

class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  static const Color whiteBg = Colors.white;
  static const Color navyDark = Color(0xFF0B1E3D);
  static const Color goldColor = Color(0xFFD39706);

  // Favorite states for items
  final Map<int, bool> _favorites = {
    0: true,  // First card favorite by default
    1: false, // Second card unfavorite by default
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: whiteBg,
      body: SafeArea(
        bottom: false,
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Column(
            children: [
              _buildAppBar(context),
              const Divider(height: 1, color: Color(0xFFF0F0F0)),
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                  children: [
                    // Card 1: المركز الأول وكأس البطولة (Width: 312, Height: 327)
                    Center(
                      child: _buildAchievementCard(
                        id: 0,
                        title: 'المركز الأول وكأس البطولة 🥇🏆',
                        dateText: 'September 25, 2026',
                        description: 'للطالب عبدالله عبد العزيز من كلية الغد الدولية 😎\nفي البطولة الخامسة للسباحة بين طلبة الجامعات\nوالكليات اليمنية.',
                        bannerImagePath: 'assets/images/achievements_banner_1.png',
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Card 2: عنوان الخبر (Width: 312, Height: 327)
                    Center(
                      child: _buildAchievementCard(
                        id: 1,
                        title: 'عنوان الخبر',
                        dateText: 'تاريخ الخبر',
                        description: 'نص الخبر',
                        bannerImagePath: 'assets/images/achievements_banner_2.png',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          InkWell(
            onTap: () => Navigator.pop(context),
            borderRadius: BorderRadius.circular(8),
            child: const Padding(
              padding: EdgeInsets.all(4.0),
              child: Icon(
                Icons.arrow_forward_rounded,
                color: navyDark,
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            'إنجازاتنا',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: navyDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementCard({
    required int id,
    required String title,
    required String dateText,
    required String description,
    required String bannerImagePath,
  }) {
    final isFav = _favorites[id] ?? false;

    return Container(
      width: 312.0,
      height: 327.0,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Column(
          children: [
            // Top Banner Image section (Height: 145)
            SizedBox(
              height: 145,
              width: double.infinity,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Image.asset(
                      bannerImagePath,
                      fit: BoxFit.cover,
                    ),
                  ),
                  // Heart Favorite Icon Button
                  Positioned(
                    left: 10,
                    top: 10,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _favorites[id] = !isFav;
                        });
                      },
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE2E7EA).withOpacity(0.85),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Icon(
                            isFav ? Icons.favorite : Icons.favorite_border,
                            size: 16,
                            color: isFav ? const Color(0xFFE53935) : navyDark,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Middle Content section
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    const SizedBox(height: 2),
                    // Title
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: navyDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Date line
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today_outlined,
                          size: 13,
                          color: goldColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          dateText,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: goldColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // Description
                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF6E6E6E),
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const Divider(height: 1, color: Color(0xFFEEEEEE)),

            // Bottom Action Bar (Height: 46)
            SizedBox(
              height: 46,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Read More Details Action
                    InkWell(
                      onTap: () {},
                      child: const Row(
                        children: [
                          Icon(
                            Icons.menu_book_outlined,
                            size: 16,
                            color: navyDark,
                          ),
                          SizedBox(width: 5),
                          Text(
                            'قراءة المزيد من التفاصيل',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: navyDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Watch Video Action
                    InkWell(
                      onTap: () {},
                      child: const Row(
                        children: [
                          Icon(
                            Icons.play_circle_outline_rounded,
                            size: 16,
                            color: navyDark,
                          ),
                          SizedBox(width: 5),
                          Text(
                            'مشاهدة',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: navyDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
