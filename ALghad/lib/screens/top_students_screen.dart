import 'package:flutter/material.dart';
import '../models/app_models.dart';
import '../services/data_service.dart';

class TopStudentsScreen extends StatelessWidget {
  const TopStudentsScreen({super.key});

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
          'لوحة أوائل الطلاب',
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
          child: FutureBuilder<List<TopStudentModel>>(
            future: DataService.getTopStudents(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final topStudents = snapshot.data ?? [];
              if (topStudents.isEmpty) {
                return const Center(child: Text('لا يوجد أوائل مسجلين حالياً'));
              }

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF8E1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: accentGold.withOpacity(0.5)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.emoji_events, color: accentGold, size: 28),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'قائمة الشرف والطلبة المتفوقين المرفوعة مباشرة من كنترول الكلية.',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: navyDark),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Table container resembling Excel sheet formatting
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey.shade300),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2)),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            headingRowColor: WidgetStateProperty.all(navyDark),
                            headingTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                            dataRowMaxHeight: 50,
                            columns: const [
                              DataColumn(label: Text('الترتيب')),
                              DataColumn(label: Text('اسم الطالب')),
                              DataColumn(label: Text('التخصص')),
                              DataColumn(label: Text('المعدل')),
                              DataColumn(label: Text('الدفعة')),
                            ],
                            rows: topStudents.map((student) {
                              final isTop3 = student.rank <= 3;
                              return DataRow(
                                color: WidgetStateProperty.all(
                                  student.rank % 2 == 0 ? Colors.grey.shade50 : Colors.white,
                                ),
                                cells: [
                                  DataCell(
                                    Row(
                                      children: [
                                        if (isTop3)
                                          const Icon(Icons.star, color: accentGold, size: 16)
                                        else
                                          const SizedBox(width: 16),
                                        const SizedBox(width: 4),
                                        Text('${student.rank}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  ),
                                  DataCell(Text(student.studentName, style: const TextStyle(fontWeight: FontWeight.bold))),
                                  DataCell(Text(student.specialty)),
                                  DataCell(
                                    Text(
                                      '${student.gpa}%',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: isTop3 ? accentGold : navyDark,
                                      ),
                                    ),
                                  ),
                                  DataCell(Text(student.batch)),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
