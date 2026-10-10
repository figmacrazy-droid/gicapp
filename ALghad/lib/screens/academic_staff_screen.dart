import 'package:flutter/material.dart';
import '../models/app_models.dart';
import '../services/data_service.dart';

class AcademicStaffScreen extends StatelessWidget {
  const AcademicStaffScreen({super.key});

  static const Color navyDark = Color(0xFF0B1E3D);
  static const Color accentGold = Color(0xFFD39706);

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
          'الكادر الأكاديمي والتدريسي',
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
          child: FutureBuilder<List<AcademicStaffModel>>(
            future: DataService.getAcademicStaff(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final staffList = snapshot.data ?? [];
              if (staffList.isEmpty) {
                return const Center(child: Text('لا يوجد أعضاء كادر حالياً'));
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: staffList.length,
                itemBuilder: (context, index) {
                  final staff = staffList[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              width: 70,
                              height: 70,
                              color: Colors.grey.shade200,
                              child: staff.photoUrl.startsWith('http')
                                  ? Image.network(staff.photoUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.person, size: 40, color: navyDark))
                                  : Image.asset(
                                      staff.photoUrl,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => const Icon(Icons.person, size: 40, color: navyDark),
                                    ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  staff.name,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: navyDark,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  staff.specialty,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: accentGold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.work_outline, size: 14, color: Colors.grey),
                                    const SizedBox(width: 4),
                                    Text(
                                      staff.experienceYears,
                                      style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                                    ),
                                  ],
                                ),
                                if (staff.bio != null) ...[
                                  const SizedBox(height: 6),
                                  Text(
                                    staff.bio!,
                                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600, height: 1.4),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
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
