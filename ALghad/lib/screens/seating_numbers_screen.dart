import 'package:flutter/material.dart';
import '../models/app_models.dart';
import '../services/data_service.dart';

class SeatingNumbersScreen extends StatefulWidget {
  const SeatingNumbersScreen({super.key});

  @override
  State<SeatingNumbersScreen> createState() => _SeatingNumbersScreenState();
}

class _SeatingNumbersScreenState extends State<SeatingNumbersScreen> {
  static const Color navyDark = Color(0xFF0B1E3D);
  static const Color accentGold = Color(0xFFD39706);

  final TextEditingController _idController = TextEditingController();
  SeatingNumberModel? _resultData;
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
          'أرقام الجلوس',
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
                  'استعلام عن رقم الجلوس وقاعة الامتحان:',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: navyDark),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _idController,
                        decoration: InputDecoration(
                          hintText: 'أدخل الرقم الأكاديمي للطالب (مثال: 20240101)',
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
                      onPressed: _search,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: navyDark,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('بحث', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                if (_isLoading)
                  const Center(child: CircularProgressIndicator())
                else if (_resultData != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: accentGold.withOpacity(0.4)),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('بطاقة كرت الجلوس الامتحاني', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: navyDark)),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(color: accentGold, borderRadius: BorderRadius.circular(20)),
                              child: Text('رقم الجلوس: ${_resultData!.seatingNumber}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                            ),
                          ],
                        ),
                        const Divider(height: 24),
                        _buildInfoRow('الاسم الثلاثي/الكامل:', _resultData!.studentName),
                        _buildInfoRow('الرقم الأكاديمي:', _resultData!.academicId),
                        _buildInfoRow('التخصص الأكاديمي:', _resultData!.specialty),
                        _buildInfoRow('الفصل الدراسي:', _resultData!.term),
                        _buildInfoRow('القاعة الامتحانية:', _resultData!.hall),
                      ],
                    ),
                  ),
                ] else
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 40),
                      child: Text(
                        'يرجى إدخال الرقم الأكاديمي والضغط على بحث لعرض رقم الجلوس والقاعة.',
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

  void _search() async {
    setState(() => _isLoading = true);
    final data = await DataService.searchSeatingNumber(_idController.text.trim());
    setState(() {
      _resultData = data;
      _isLoading = false;
    });
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text('$label ', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: navyDark))),
        ],
      ),
    );
  }
}
