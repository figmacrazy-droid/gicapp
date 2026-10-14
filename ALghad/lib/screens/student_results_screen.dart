import 'package:flutter/material.dart';
import '../models/app_models.dart';
import '../services/data_service.dart';
import '../services/auth_service.dart';

class StudentResultsScreen extends StatefulWidget {
  const StudentResultsScreen({super.key});

  @override
  State<StudentResultsScreen> createState() => _StudentResultsScreenState();
}

class _StudentResultsScreenState extends State<StudentResultsScreen> {
  static const Color navyDark = Color(0xFF0B1E3D);
  static const Color accentGold = Color(0xFFD39706);

  StudentResultModel? _results;
  int _selectedTermIndex = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadResults();
  }

  Future<void> _loadResults() async {
    setState(() => _isLoading = true);
    try {
      final session = await AuthService.getSavedSession();
      final String currentId = session?.academicId ?? '2025010101';
      final data = await DataService.getStudentResults(currentId);
      if (mounted) {
        setState(() {
          _results = data;
          _selectedTermIndex = 0;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    TermResultModel? activeTerm;
    if (_results != null) {
      if (_results!.terms.isNotEmpty && _selectedTermIndex < _results!.terms.length) {
        activeTerm = _results!.terms[_selectedTermIndex];
      } else {
        activeTerm = TermResultModel(
          termName: 'الفصل الدراسي الحالي',
          subjects: _results!.subjects,
          totalMarks: _results!.totalMarks,
          gpa: _results!.gpa,
          grade: _results!.grade,
        );
      }
    }

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
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: navyDark),
            tooltip: 'تحديث النتيجة',
            onPressed: _loadResults,
          ),
        ],
      ),
      body: SafeArea(
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _results == null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.assignment_late_outlined, size: 64, color: Colors.grey.shade400),
                          const SizedBox(height: 16),
                          const Text(
                            'لا توجد نتائج مسجلة حتى الآن لهذا الحساب الأكاديمي',
                            style: TextStyle(color: Colors.grey, fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            onPressed: _loadResults,
                            icon: const Icon(Icons.refresh, size: 18),
                            label: const Text('إعادة المحاولة'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: navyDark,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ],
                      ),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 1. بطاقة معلومات الطالب
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: navyDark,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: navyDark.withOpacity(0.18),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        _results!.studentName,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 17,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                                      decoration: BoxDecoration(
                                        color: accentGold,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        activeTerm?.grade ?? _results!.grade,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'الرقم الأكاديمي: ${_results!.academicId}',
                                  style: const TextStyle(color: Colors.white70, fontSize: 13.5),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'التخصص: ${_results!.specialty}',
                                  style: const TextStyle(color: Colors.white70, fontSize: 13.5),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'الدفعة: ${_results!.batch}',
                                  style: const TextStyle(color: Colors.white70, fontSize: 13.5),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 20),

                          // 2. محدد الفصول والنتائج (الأحدث دائماً في الأمام)
                          if (_results!.terms.isNotEmpty) ...[
                            Row(
                              children: [
                                const Icon(Icons.history_edu_rounded, size: 20, color: navyDark),
                                const SizedBox(width: 8),
                                const Text(
                                  'الفصول والامتحانات الأكاديمية:',
                                  style: TextStyle(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.bold,
                                    color: navyDark,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            SizedBox(
                              height: 42,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: _results!.terms.length,
                                separatorBuilder: (_, __) => const SizedBox(width: 10),
                                itemBuilder: (context, index) {
                                  final term = _results!.terms[index];
                                  final isSelected = index == _selectedTermIndex;
                                  final isLatest = index == 0;

                                  return InkWell(
                                    onTap: () => setState(() => _selectedTermIndex = index),
                                    borderRadius: BorderRadius.circular(10),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: isSelected ? navyDark : Colors.white,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: isSelected ? accentGold : Colors.grey.shade300,
                                          width: isSelected ? 1.8 : 1.0,
                                        ),
                                        boxShadow: [
                                          if (isSelected)
                                            BoxShadow(
                                              color: navyDark.withOpacity(0.12),
                                              blurRadius: 6,
                                              offset: const Offset(0, 2),
                                            ),
                                        ],
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          if (isLatest) ...[
                                            Icon(
                                              Icons.star_rounded,
                                              size: 16,
                                              color: isSelected ? accentGold : Colors.amber.shade700,
                                            ),
                                            const SizedBox(width: 5),
                                          ],
                                          Text(
                                            isLatest ? '${term.termName} (الأحدث)' : term.termName,
                                            style: TextStyle(
                                              fontSize: 12.5,
                                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                              color: isSelected ? Colors.white : Colors.black87,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],

                          // 3. ترويسة الجدول
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'كشف الدرجات: ${activeTerm?.termName ?? ""}',
                                style: const TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.bold,
                                  color: navyDark,
                                ),
                              ),
                              if (activeTerm?.academicYear != null)
                                Text(
                                  activeTerm!.academicYear!,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          // 4. جدول كشف الدرجات
                          Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade300),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                // ترويسة الأعمدة
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
                                  ),
                                  child: const Row(
                                    children: [
                                      Expanded(
                                        flex: 3,
                                        child: Text(
                                          'اسم المادة',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: navyDark,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 1,
                                        child: Text(
                                          'الدرجة',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: navyDark,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 1,
                                        child: Text(
                                          'الحالة',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: navyDark,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Divider(height: 1),

                                // صفوف المواد
                                ...((activeTerm?.subjects ?? _results!.subjects).entries.map((entry) {
                                  final isPassed = entry.value >= 50;
                                  return Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                    decoration: BoxDecoration(
                                      border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          flex: 3,
                                          child: Text(
                                            entry.key,
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          flex: 1,
                                          child: Text(
                                            entry.value.toStringAsFixed(
                                              entry.value.truncateToDouble() == entry.value ? 0 : 1,
                                            ),
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                              color: isPassed ? Colors.green.shade800 : Colors.red.shade800,
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          flex: 1,
                                          child: Center(
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                              decoration: BoxDecoration(
                                                color: isPassed ? Colors.green.shade50 : Colors.red.shade50,
                                                borderRadius: BorderRadius.circular(6),
                                                border: Border.all(
                                                  color: isPassed ? Colors.green.shade300 : Colors.red.shade300,
                                                  width: 0.8,
                                                ),
                                              ),
                                              child: Text(
                                                isPassed ? 'ناجح' : 'دور ثان',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                  color: isPassed ? Colors.green.shade800 : Colors.red.shade800,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                })),
                              ],
                            ),
                          ),

                          const SizedBox(height: 20),

                          // 5. بطاقة ملخص النتيجة المحسوبة في ملف الإكسل
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
                                    Text(
                                      '${activeTerm?.totalMarks ?? _results!.totalMarks}',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: navyDark,
                                      ),
                                    ),
                                  ],
                                ),
                                Container(width: 1, height: 32, color: Colors.grey.shade300),
                                Column(
                                  children: [
                                    const Text('المعدل التراكمي', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${activeTerm?.gpa ?? _results!.gpa}%',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: accentGold,
                                      ),
                                    ),
                                  ],
                                ),
                                Container(width: 1, height: 32, color: Colors.grey.shade300),
                                Column(
                                  children: [
                                    const Text('التقدير العام', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                    const SizedBox(height: 4),
                                    Text(
                                      activeTerm?.grade ?? _results!.grade,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: navyDark,
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
      ),
    );
  }
}
