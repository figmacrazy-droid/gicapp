import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class AllSpecialtiesScreen extends StatefulWidget {
  const AllSpecialtiesScreen({super.key});

  @override
  State<AllSpecialtiesScreen> createState() => _AllSpecialtiesScreenState();
}

class _AllSpecialtiesScreenState extends State<AllSpecialtiesScreen> {
  static const Color whiteBg = Colors.white;
  static const Color navyDark = Color(0xFF0A2451);
  static const Color textGray = Color(0xFF6B6B6B);

  List<Map<String, String>> _dynamicSpecialties = [];

  @override
  void initState() {
    super.initState();
    _loadSpecialties();
  }

  Future<void> _loadSpecialties() async {
    try {
      final res = await Supabase.instance.client
          .from('specialties')
          .select()
          .order('display_order', ascending: true);
      final list = res as List;
      if (list.isNotEmpty && mounted) {
        setState(() {
          _dynamicSpecialties = list.map((item) {
            final degree = item['degree_type'] ?? 'بكالوريوس';
            final title = item['title'] ?? '';
            String loc = item['location']?.toString() ?? 'صنعاء - دارس';
            String yt = '';
            if (loc.contains('|')) {
              final parts = loc.split('|');
              loc = parts[0];
              yt = parts.sublist(1).join('|');
            } else if (loc.startsWith('http')) {
              yt = loc;
              loc = 'صنعاء - دارس';
            }
            return {
              'title': '$degree\n$title',
              'visits': '${item['visits_count'] ?? '1,200'}',
              'image': (item['image_url'] != null && item['image_url'].toString().isNotEmpty)
                  ? item['image_url'].toString()
                  : 'assets/images/specialty_1.png',
              'youtube_url': yt,
            };
          }).toList();
        });
      }
    } catch (_) {}
  }

  Future<void> _openSpecialtyVideo(String? url, String title) async {
    if (url != null && url.trim().isNotEmpty) {
      final uri = Uri.parse(url.trim());
      try {
        final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
        if (!launched) {
          await launchUrl(uri, mode: LaunchMode.platformDefault);
        }
        return;
      } catch (e) {
        debugPrint('Could not launch youtube url: $e');
      }
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('سيتم توفير فيديو استكشاف لتخصص ($title) قريباً'),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  final List<Map<String, String>> _specialties = const [
    {
      'title': 'بكالوريوس\nإدارة أعمال',
      'visits': '6,635',
      'image': 'assets/images/specialty_1.png',
    },
    {
      'title': 'بكالوريوس\nإدارة صحية',
      'visits': '5,420',
      'image': 'assets/images/specialty_2.png',
    },
    {
      'title': 'بكالوريوس الأمن\nالسيبراني والشبكات',
      'visits': '5,180',
      'image': 'assets/images/specialty_3.png',
    },
    {
      'title': 'بكالوريوس الجرافيكس\nوالوسائط المتعددة',
      'visits': '4,980',
      'image': 'assets/images/specialty_4.png',
    },
    {
      'title': 'بكالوريوس\nالمحاسبة',
      'visits': '4,750',
      'image': 'assets/images/specialty_5.png',
    },
    {
      'title': 'بكالوريوس\nتقنية المعلومات',
      'visits': '4,520',
      'image': 'assets/images/specialty_6.png',
    },
    {
      'title': 'بكالوريوس\nهندسة التعدين',
      'visits': '4,320',
      'image': 'assets/images/specialty_7.png',
    },
    {
      'title': 'بكالوريوس هندسة الديكور\nوالتصميم الداخلي',
      'visits': '3,980',
      'image': 'assets/images/specialty_8.png',
    },
    {
      'title': 'تخصص\nالتمريض',
      'visits': '3,750',
      'image': 'assets/images/specialty_9.png',
    },
    {
      'title': 'تخصص القبالة\nوالتوليد',
      'visits': '3,540',
      'image': 'assets/images/specialty_10.png',
    },
    {
      'title': 'تخصص المختبرات\nالطبية',
      'visits': '3,210',
      'image': 'assets/images/specialty_11.png',
    },
    {
      'title': 'تخصص\nالصيدلة',
      'visits': '2,980',
      'image': 'assets/images/specialty_12.png',
    },
    {
      'title': 'تخصص\nتصميم الأزياء',
      'visits': '2,650',
      'image': 'assets/images/specialty_13.png',
    },
    {
      'title': 'تخصص فني\nتخدير وإنعاش',
      'visits': '2,340',
      'image': 'assets/images/specialty_14.png',
    },
    {
      'title': 'تخصص فني\nعمليات',
      'visits': '2,180',
      'image': 'assets/images/specialty_15.png',
    },
  ];

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
              _buildAppBar(),
              Expanded(
                child: Builder(
                  builder: (context) {
                    final items = _dynamicSpecialties.isNotEmpty ? _dynamicSpecialties : _specialties;
                    return GridView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                      itemCount: items.length,
                      gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 14,
                        crossAxisSpacing: 14,
                        childAspectRatio: 0.62,
                      ),
                      itemBuilder: (context, i) {
                        final item = items[i];
                        return _buildSpecialtyCard(
                          title: item['title']!,
                          visits: item['visits']!,
                          imagePath: item['image']!,
                          youtubeUrl: item['youtube_url'],
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(
              Icons.arrow_forward_rounded,
              color: navyDark,
              size: 26,
            ),
          ),
          const SizedBox(width: 4),
          const Expanded(
            child: Text(
              'جميع التخصصات',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: navyDark,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFF2F2F2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${_specialties.length} تخصص',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: navyDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecialtyCard({
    required String title,
    required String visits,
    required String imagePath,
    String? youtubeUrl,
  }) {
    return GestureDetector(
      onTap: () => _openSpecialtyVideo(youtubeUrl, title),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: const Color(0xFFE5E5E5),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── الصورة (تملأ المربع كامل) ──
              Expanded(
                flex: 5,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    imagePath.startsWith('data:image')
                        ? Builder(
                            builder: (context) {
                              try {
                                final commaIdx = imagePath.indexOf(',');
                                final b64 = commaIdx != -1 ? imagePath.substring(commaIdx + 1) : imagePath;
                                return Image.memory(
                                  base64Decode(b64),
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    color: const Color(0xFFF2E8D0),
                                    child: const Center(
                                      child: Icon(Icons.image_outlined, size: 36, color: Color(0xFF9E7A2F)),
                                    ),
                                  ),
                                );
                              } catch (_) {
                                return Container(
                                  color: const Color(0xFFF2E8D0),
                                  child: const Center(
                                    child: Icon(Icons.image_outlined, size: 36, color: Color(0xFF9E7A2F)),
                                  ),
                                );
                              }
                            },
                          )
                        : imagePath.startsWith('http')
                            ? Image.network(
                                imagePath,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: const Color(0xFFF2E8D0),
                                    child: const Center(
                                      child: Icon(
                                        Icons.image_outlined,
                                        size: 36,
                                        color: Color(0xFF9E7A2F),
                                      ),
                                    ),
                                  );
                                },
                              )
                            : Image.asset(
                                imagePath,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: const Color(0xFFF2E8D0),
                                    child: const Center(
                                      child: Icon(
                                        Icons.image_outlined,
                                        size: 36,
                                        color: Color(0xFF9E7A2F),
                                      ),
                                    ),
                                  );
                                },
                              ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.85),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.favorite_border_rounded,
                        size: 14,
                        color: Color(0xFF6B6B6B),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── النصوص ──
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14, // Increased font size
                        fontWeight: FontWeight.w800,
                        color: navyDark,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Row(
                      children: [
                        ...List.generate(5, (index) {
                          return const Icon(
                            Icons.star_rounded,
                            size: 11,
                            color: Color(0xFFF4B400),
                          );
                        }),
                        const SizedBox(width: 3),
                        Flexible(
                          child: Text(
                            '($visits)',
                            style: const TextStyle(
                              fontSize: 9,
                              color: textGray,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 1.5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F5F5),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: const Text(
                            'صناع',
                            style: TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.w700,
                              color: navyDark,
                            ),
                          ),
                        ),
                        const SizedBox(width: 3),
                        const Text(
                          '- دارس',
                          style: TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.w600,
                            color: textGray,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: navyDark,
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: const Icon(
                            Icons.play_arrow_rounded,
                            size: 14,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
    );
  }
}