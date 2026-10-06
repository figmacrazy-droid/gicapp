import 'package:flutter/material.dart';

class AlumniScreen extends StatefulWidget {
  const AlumniScreen({super.key});

  @override
  State<AlumniScreen> createState() => _AlumniScreenState();
}

class _AlumniScreenState extends State<AlumniScreen> {
  static const Color whiteBg = Colors.white;
  static const Color navyDark = Color(0xFF0B1E3D);
  static const Color goldColor = Color(0xFFD39706);

  // Favorite states for items
  final Map<int, bool> _favorites = {
    0: true,  // First card favorite by default as in design image
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
                    // Card 1: دفعة سفراء الغد (Width: 312, Height: 291)
                    Center(
                      child: _buildAlumniCard(
                        id: 0,
                        title: 'دفعة سفراء الغد',
                        batchName: 'الدفعة الخامسة',
                        graduatesCount: '(000 خريج)',
                        rating: 5,
                        bannerImagePath: 'assets/images/alumni_banner_1.png',
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Card 2: دفعة عظماء الغد (Width: 312, Height: 291)
                    Center(
                      child: _buildAlumniCard(
                        id: 1,
                        title: 'دفعة عظماء الغد',
                        batchName: 'الدفعة الرابعة',
                        graduatesCount: '(000 خريج)',
                        rating: 4,
                        bannerImagePath: 'assets/images/alumni_banner_2.png',
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
            'خريجي الغد',
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

  Widget _buildAlumniCard({
    required int id,
    required String title,
    required String batchName,
    required String graduatesCount,
    required int rating,
    required String bannerImagePath,
  }) {
    final isFav = _favorites[id] ?? false;

    return Container(
      width: 312.0,
      height: 291.0,
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
            // Top Banner Image section (Height: 140)
            SizedBox(
              height: 140,
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
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
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
                    // Batch Name
                    Row(
                      children: [
                        const Icon(
                          Icons.school_outlined,
                          size: 15,
                          color: goldColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          batchName,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: goldColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Rating & Count
                    Row(
                      children: [
                        Text(
                          graduatesCount,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF8E8E93),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Row(
                          children: List.generate(5, (index) {
                            return Icon(
                              Icons.star,
                              size: 13,
                              color: index < rating
                                  ? const Color(0xFFFFB800)
                                  : const Color(0xFFD6D6D6),
                            );
                          }),
                        ),
                      ],
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
                    // Magazine Read Action
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
                            'قراءة مجلة الدفعة',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: navyDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Watch Ceremony Action
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
                            'مشاهدة الحفل',
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
