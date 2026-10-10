import 'package:flutter/material.dart';
import '../models/app_models.dart';
import '../services/data_service.dart';

class FinanceScreen extends StatelessWidget {
  const FinanceScreen({super.key});

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
          'الخدمات والإشعارات المالية',
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
          child: FutureBuilder<List<FinanceNotificationModel>>(
            future: DataService.getFinanceNotifications(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final notifications = snapshot.data ?? [];
              if (notifications.isEmpty) {
                return const Center(child: Text('لا توجد إشعارات مالية حالياً'));
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: notifications.length,
                itemBuilder: (context, index) {
                  final item = notifications[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2)),
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
                                item.title,
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: navyDark),
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
                          item.details,
                          style: const TextStyle(fontSize: 13, color: Color(0xFF4A4A4A), height: 1.4),
                        ),
                        if (item.amount != null) ...[
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              const Text('المبلغ المقرر: ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                              Text(
                                '${item.amount} ريال يمني',
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: accentGold),
                              ),
                            ],
                          ),
                        ],
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
