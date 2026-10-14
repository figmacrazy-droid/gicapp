import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/app_models.dart';
import '../services/data_service.dart';

class AlumniScreen extends StatelessWidget {
  const AlumniScreen({super.key});

  static const Color navyDark = Color(0xFF0B1E3D);
  static const Color goldColor = Color(0xFFD39706);

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
          'خريجي الغد',
          style: TextStyle(
            color: navyDark,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: FutureBuilder<List<AlumniBatchModel>>(
            future: DataService.getAlumniBatches(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final batches = snapshot.data ?? [];
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: batches.length,
                itemBuilder: (context, index) {
                  final batch = batches[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 20),
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                          child: SizedBox(
                            height: 140,
                            width: double.infinity,
                            child: Builder(
                              builder: (context) {
                                final img = batch.bannerImagePath;
                                if (img.startsWith('data:image')) {
                                  try {
                                    final commaIdx = img.indexOf(',');
                                    final b64 = commaIdx != -1 ? img.substring(commaIdx + 1) : img;
                                    return Image.memory(
                                      base64Decode(b64),
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Container(color: navyDark, child: const Icon(Icons.school, color: Colors.white, size: 50)),
                                    );
                                  } catch (_) {
                                    return Container(color: navyDark, child: const Icon(Icons.school, color: Colors.white, size: 50));
                                  }
                                } else if (img.startsWith('http')) {
                                  return Image.network(
                                    img,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(color: navyDark, child: const Icon(Icons.school, color: Colors.white, size: 50)),
                                  );
                                }
                                return Image.asset(
                                  img,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(color: navyDark, child: const Icon(Icons.school, color: Colors.white, size: 50)),
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
                              Text(
                                batch.title,
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: navyDark),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.school_outlined, size: 16, color: goldColor),
                                  const SizedBox(width: 4),
                                  Text(
                                    batch.batchName,
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: goldColor),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    batch.graduatesCount,
                                    style: const TextStyle(fontSize: 12, color: Color(0xFF8E8E93)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const Divider(height: 1, color: Color(0xFFEEEEEE)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              InkWell(
                                onTap: () async {
                                  final pdfUrl = batch.magazinePdfUrl;
                                  if (pdfUrl != null && pdfUrl.trim().isNotEmpty) {
                                    final Uri uri = Uri.parse(pdfUrl.trim());
                                    if (await canLaunchUrl(uri)) {
                                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                                    }
                                  }
                                },
                                child: const Row(
                                  children: [
                                    Icon(Icons.menu_book_outlined, size: 18, color: navyDark),
                                    SizedBox(width: 5),
                                    Text('قراءة مجلة الدفعة', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: navyDark)),
                                  ],
                                ),
                              ),
                              InkWell(
                                onTap: () async {
                                  final ytUrl = batch.ceremonyYoutubeUrl;
                                  if (ytUrl != null && ytUrl.trim().isNotEmpty) {
                                    final Uri uri = Uri.parse(ytUrl.trim());
                                    if (await canLaunchUrl(uri)) {
                                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                                    }
                                  }
                                },
                                child: const Row(
                                  children: [
                                    Icon(Icons.play_circle_outline_rounded, size: 18, color: Colors.red),
                                    SizedBox(width: 5),
                                    Text('مشاهدة الحفل', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.red)),
                                  ],
                                ),
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
