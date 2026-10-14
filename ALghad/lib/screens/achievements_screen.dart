import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/app_models.dart';
import '../services/data_service.dart';

class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  static const Color navyDark = Color(0xFF0B1E3D);
  static const Color accentGold = Color(0xFFD39706);

  final Map<String, bool> _expandedState = {};

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
          'إنجازاتنا',
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
          child: FutureBuilder<List<AchievementModel>>(
            future: DataService.getAchievements(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final achievements = snapshot.data ?? [];
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: achievements.length,
                itemBuilder: (context, index) {
                  final item = achievements[index];
                  final isExpanded = _expandedState[item.id] ?? false;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 3)),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                          child: Container(
                            height: 150,
                            width: double.infinity,
                            color: Colors.grey.shade200,
                            child: Builder(
                              builder: (context) {
                                final img = item.imageUrl;
                                if (img.startsWith('data:image')) {
                                  try {
                                    final commaIdx = img.indexOf(',');
                                    final b64 = commaIdx != -1 ? img.substring(commaIdx + 1) : img;
                                    return Image.memory(
                                      base64Decode(b64),
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => const Icon(Icons.star, size: 50, color: accentGold),
                                    );
                                  } catch (_) {
                                    return const Icon(Icons.star, size: 50, color: accentGold);
                                  }
                                } else if (img.startsWith('http')) {
                                  return Image.network(
                                    img,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => const Icon(Icons.star, size: 50, color: accentGold),
                                  );
                                }
                                return Image.asset(
                                  img,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const Icon(Icons.star, size: 50, color: accentGold),
                                );
                              },
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      item.title,
                                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: navyDark),
                                    ),
                                  ),
                                  Text(
                                    item.date,
                                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                item.description,
                                maxLines: isExpanded ? 100 : 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 13, color: Color(0xFF4A4A4A), height: 1.5),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  TextButton(
                                    onPressed: () {
                                      setState(() {
                                        _expandedState[item.id] = !isExpanded;
                                      });
                                    },
                                    child: Text(
                                      isExpanded ? 'عرض أقل' : 'قراءة المزيد',
                                      style: const TextStyle(color: accentGold, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  if (item.youtubeUrl != null) ...[
                                    ElevatedButton.icon(
                                      onPressed: () async {
                                        final Uri uri = Uri.parse(item.youtubeUrl!);
                                        if (await canLaunchUrl(uri)) {
                                          await launchUrl(uri, mode: LaunchMode.externalApplication);
                                        }
                                      },
                                      icon: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 18),
                                      label: const Text('مشاهدة', style: TextStyle(color: Colors.white, fontSize: 12)),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red.shade700,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
