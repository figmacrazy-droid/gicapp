import 'package:flutter/material.dart';

class AnalysisView extends StatelessWidget {
  const AnalysisView({Key? key}) : super(key: key);

  static const Color primaryNavy = Color(0xFF0E1B4D);
  static const Color accentGold = Color(0xFFC5A059);

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('لوحة التحليل والإحصائيات', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: primaryNavy)),
            const SizedBox(height: 24),
            
            // بطاقات الإحصائيات العلوية
            Row(
              children: [
                _buildStatCard(title: 'إجمالي الطلاب المسجلين', value: '1,245', icon: Icons.people, color: Colors.blue),
                const SizedBox(width: 16),
                _buildStatCard(title: 'المستخدمين النشطين (التطبيق)', value: '890', icon: Icons.mobile_friendly, color: Colors.green),
                const SizedBox(width: 16),
                _buildStatCard(title: 'إجمالي التفاعلات (القلوب)', value: '3,412', icon: Icons.favorite, color: Colors.red),
              ],
            ),
            
            const SizedBox(height: 32),
            
            // القسم السفلي مقسوم نصفين
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // تفاعلات الطلاب (المنشورات التي عليها قلب)
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.favorite, color: Colors.red),
                            SizedBox(width: 8),
                            Text('أحدث تفاعلات الطلاب (إعجابات الإعلانات)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryNavy)),
                          ],
                        ),
                        const Divider(height: 24),
                        _buildActivityRow(studentName: 'أحمد محمد عبدالله', activity: 'أعجب بإعلان: مسابقة البرمجة', time: 'قبل 10 دقائق'),
                        _buildActivityRow(studentName: 'فاطمة علي السقاف', activity: 'أعجب بإعلان: جدول الامتحانات النصفي', time: 'قبل 45 دقيقة'),
                        _buildActivityRow(studentName: 'سالم عمر', activity: 'أعجب بإنجاز: فوز الكلية ببطولة الشطرنج', time: 'قبل ساعتين'),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(width: 24),
                
                // سجل دخول ونشاط الطلاب العام
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.history, color: primaryNavy),
                            SizedBox(width: 8),
                            Text('سجل نشاط الدخول للتطبيق (Logs)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryNavy)),
                          ],
                        ),
                        const Divider(height: 24),
                        _buildActivityRow(studentName: 'أحمد محمد عبدالله', activity: 'تسجيل دخول ناجح (تطبيق الجوال)', time: '02:30 PM', isLog: true),
                        _buildActivityRow(studentName: 'فاطمة علي السقاف', activity: 'تنزيل جدول المحاضرات (PDF)', time: '01:15 PM', isLog: true),
                        _buildActivityRow(studentName: 'سالم عمر', activity: 'تغيير كلمة المرور', time: '11:00 AM', isLog: true),
                      ],
                    ),
                  ),
                )
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({required String title, required String value, required IconData icon, required Color color}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
          boxShadow: [BoxShadow(color: color.withOpacity(0.05), blurRadius: 10)],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: primaryNavy)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityRow({required String studentName, required String activity, required String time, bool isLog = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(isLog ? Icons.check_circle : Icons.favorite, color: isLog ? Colors.green : Colors.red, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(studentName, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(activity, style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
              ],
            ),
          ),
          Text(time, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }
}
