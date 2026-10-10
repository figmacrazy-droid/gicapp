import 'package:flutter/material.dart';
import '../models/app_models.dart';
import '../services/data_service.dart';

class StudentResultsScreen extends StatefulWidget {
  const StudentResultsScreen({super.key});

  @override
  State<StudentResultsScreen> createState() => _StudentResultsScreenState();
}

class _StudentResultsScreenState extends State<StudentResultsScreen> {
  static const Color navyDark = Color(0xFF0B1E3D);
  static const Color accentGold = Color(0xFFD39706);

  final TextEditingController _idController = TextEditingController();
  StudentResultModel? _results;
  bool _isLoading = false;

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
          'نتائج الامتحانات الأكاديمية',
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'استعلام عن النتيجة الأكاديمية:',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: navyDark),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _idController,
                        decoration: InputDecoration(
                          hintText: 'أدخل الرقم الأكاديمي (مثال: 20240101)',
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: _fetchResults,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: navyDark,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('عرض النتيجة', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                if (_isLoading)
                  const Center(child: CircularProgressIndicator())
                else if (_results != null) ...[
                  // Student Header Info Box
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: navyDark,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _results!.studentName,
                              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(color: accentGold, borderRadius: BorderRadius.circular(20)),
                              child: Text(_results!.grade, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text('الرقم الأكاديمي: ${_results!.academicId}', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                        Text('التخصص: ${_results!.specialty}', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                        Text('الدفعة: ${_results!.batch}', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text('تفاصيل درجات المواد (ديناميكياً بحسب المواد المرجعة):',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: navyDark)),
                  const SizedBox(height: 10),
                  // Dynamic Subject Table
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          color: Colors.grey.shade100,
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('اسم المادة', style: TextStyle(fontWeight: FontWeight.bold, color: navyDark)),
                              Text('الدرجة / 100', style: TextStyle(fontWeight: FontWeight.bold, color: navyDark)),
                            ],
                          ),
                        ),
                        const Divider(height: 1),
                        ..._results!.subjects.entries.map((entry) {
                          return Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(child: Text(entry.key, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
                                Text(
                                  '${entry.value}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: entry.value >= 50 ? Colors.green.shade700 : Colors.red,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Summary Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF8E1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: accentGold.withOpacity(0.5)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(
                          children: [
                            const Text('المجموع الكلي', style: TextStyle(fontSize: 12, color: Colors.grey)),
                            const SizedBox(height: 4),
                            Text('${_results!.totalMarks}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: navyDark)),
                          ],
                        ),
                        Container(width: 1, height: 30, color: Colors.grey.shade300),
                        Column(
                          children: [
                            const Text('المعدل التراكمي', style: TextStyle(fontSize: 12, color: Colors.grey)),
                            const SizedBox(height: 4),
                            Text('${_results!.gpa}%', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: accentGold)),
                          ],
                        ),
                        Container(width: 1, height: 30, color: Colors.grey.shade300),
                        Column(
                          children: [
                            const Text('التقدير العام', style: TextStyle(fontSize: 12, color: Colors.grey)),
                            const SizedBox(height: 4),
                            Text(_results!.grade, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: navyDark)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ] else
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 40),
                      child: Text(
                        'أدخل الرقم الأكاديمي ثم اضغط عرض النتيجة.',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _fetchResults() async {
    setState(() => _isLoading = true);
    final data = await DataService.getStudentResults(_idController.text.trim());
    setState(() {
      _results = data;
      _isLoading = false;
    });
  }
}
