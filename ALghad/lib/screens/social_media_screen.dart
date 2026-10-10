import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/app_models.dart';
import '../services/data_service.dart';

class SocialMediaScreen extends StatelessWidget {
  const SocialMediaScreen({super.key});

  static const Color navyDark = Color(0xFF0B1E3D);

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
          'حسابات التواصل الاجتماعي',
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
          child: FutureBuilder<List<SocialMediaLinkModel>>(
            future: DataService.getSocialMediaLinks(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final links = snapshot.data ?? [];
              return ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: links.length,
                itemBuilder: (context, index) {
                  final item = links[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2)),
                      ],
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEBF3FF),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.public, color: navyDark, size: 24),
                      ),
                      title: Text(
                        item.platformName,
                        style: const TextStyle(fontWeight: FontWeight.bold, color: navyDark, fontSize: 14),
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                      onTap: () async {
                        final Uri uri = Uri.parse(item.url);
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri, mode: LaunchMode.externalApplication);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('تعذر فتح الرابط: ${item.url}')),
                          );
                        }
                      },
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
