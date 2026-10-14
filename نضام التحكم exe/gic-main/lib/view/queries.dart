import 'package:flutter/material.dart';
import 'notifications_management_view.dart';

// إعادة تصدير NotificationsManagementView لضمان التوافق الكامل مع أي استيراد سابق
class QueriesView extends StatelessWidget {
  final Function(String path)? onPathChanged;

  const QueriesView({Key? key, this.onPathChanged}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return NotificationsManagementView(onPathChanged: onPathChanged);
  }
}
