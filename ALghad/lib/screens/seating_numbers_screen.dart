import 'package:flutter/material.dart';
import '../models/app_models.dart';
import '../services/data_service.dart';
import '../services/auth_service.dart';

class SeatingNumbersScreen extends StatefulWidget {
  const SeatingNumbersScreen({super.key});

  @override
  State<SeatingNumbersScreen> createState() => _SeatingNumbersScreenState();
}

class _SeatingNumbersScreenState extends State<SeatingNumbersScreen> {
  static const Color navyDark = Color(0xFF0B1E3D);
  static const Color accentGold = Color(0xFFD39706);

  SeatingNumberModel? _resultData;
  bool _isLoading = true;
  String? _studentAcademicId;
  String? _studentName;

  @override
  void initState() {
    super.initState();
    _loadStudentSeatingNumber();
  }

  Future<void> _loadStudentSeatingNumber() async {
    setState(() => _isLoading = true);

    try {
      final session = await AuthService.getSavedSession();
      final academicId = session?.academicId ?? '2025010101';
      _studentAcademicId = academicId;
      _studentName = session?.fullName;

      final data = await DataService.searchSeatingNumber(academicId);
      if (mounted) {
        setState(() {
          _resultData = data;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

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
          'أرقام الجلوس والقاعات',
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
            tooltip: 'تحديث',
            onPressed: _loadStudentSeatingNumber,
          ),
        ],
      ),
      body: SafeArea(
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: _isLoading
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: navyDark),
                      SizedBox(height: 16),
                      Text(
                        'جارِ جلب بيانات رقم الجلوس والقاعة الامتحانية...',
                        style: TextStyle(color: navyDark, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadStudentSeatingNumber,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(20),
                    child: _resultData != null ? _buildSeatingCard() : _buildNotIssuedState(),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildSeatingCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: accentGold.withOpacity(0.4), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 12,
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
                  const Row(
                    children: [
                      Icon(Icons.badge_outlined, color: navyDark, size: 22),
                      SizedBox(width: 8),
                      Text(
                        'بطاقة كرت الجلوس الامتحاني',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: navyDark),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: accentGold,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(color: accentGold.withOpacity(0.3), blurRadius: 6, offset: const Offset(0, 2)),
                      ],
                    ),
                    child: Text(
                      'رقم الجلوس: ${_resultData!.seatingNumber}',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                ],
              ),
              const Divider(height: 28),
              _buildInfoRow('اسم الطالب:', _resultData!.studentName.isNotEmpty ? _resultData!.studentName : (_studentName ?? 'الطالب')),
              _buildInfoRow('الرقم الأكاديمي:', _resultData!.academicId),
              _buildInfoRow('التخصص الأكاديمي:', _resultData!.specialty),
              _buildInfoRow('الفصل الدراسي:', _resultData!.term),
              _buildInfoRow('القاعة الامتحانية:', _resultData!.hall, isHighlight: true),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF9E6),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: accentGold.withOpacity(0.3)),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.info_outline, color: accentGold, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'تعليمات وإرشادات هامة من الكنترول:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: navyDark),
                  ),
                ],
              ),
              SizedBox(height: 10),
              Text(
                '• الحضور إلى القاعة الامتحانية المحددة قبل موعد بدء الاختبار بـ 15 دقيقة على الأقل.\n• إبراز البطاقة الجامعية أو إثبات الهوية الشخصية للمراقب عند الدخول.\n• يمنع منعاً باتاً إدخال الهواتف المحمولة أو المذكرات داخل القاعات الامتحانية.',
                style: TextStyle(fontSize: 12.5, height: 1.6, color: Color(0xFF555555)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNotIssuedState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 60),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.assignment_late_outlined, size: 64, color: Colors.amber.shade800),
            ),
            const SizedBox(height: 24),
            const Text(
              'لم يتم نشر رقم الجلوس حتى الآن',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: navyDark),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'يقوم الكنترول حالياً بتجهيز جداول القاعات وتوزيع أرقام الجلوس للفصل الدراسي الحالي.\nستصلك رسالة إشعار فور اعتمادها ونشرها للطلاب.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13, height: 1.5),
              ),
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: _loadStudentSeatingNumber,
              icon: const Icon(Icons.refresh, color: Colors.white, size: 20),
              label: const Text('فحص مجدداً', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: navyDark,
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.black54),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: isHighlight ? const Color(0xFFB8860B) : navyDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
