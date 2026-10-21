import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';
import '../services/fcm_sender_service.dart';
import '../services/auth_service.dart';
import '../services/permission_service.dart';
import '../widgets/desktop_scroll_view.dart';

class NotificationsManagementView extends StatefulWidget {
  final Function(String path)? onPathChanged;

  const NotificationsManagementView({Key? key, this.onPathChanged}) : super(key: key);

  @override
  State<NotificationsManagementView> createState() => _NotificationsManagementViewState();
}

// نموذج الطالب المستهدف داخل الإشعار
class NotificationTargetStudent {
  final String id; // معرف الإشعار في قاعدة البيانات
  final String academicId;
  final String studentName;
  final String specialty;
  final String batch;
  final String semester;
  bool isRead;
  final bool isDelivered;
  final DateTime createdAt;

  NotificationTargetStudent({
    required this.id,
    required this.academicId,
    required this.studentName,
    required this.specialty,
    required this.batch,
    required this.semester,
    required this.isRead,
    this.isDelivered = true,
    required this.createdAt,
  });
}

// نموذج مجموعة الإشعار (حملة إشعار)
class NotificationCampaign {
  final String groupKey;
  String title;
  String body;
  String type;
  final DateTime createdAt;
  final bool isBroadcast;
  List<NotificationTargetStudent> targets;

  NotificationCampaign({
    required this.groupKey,
    required this.title,
    required this.body,
    required this.type,
    required this.createdAt,
    required this.isBroadcast,
    required this.targets,
  });

  int get totalRecipients => targets.length;
  int get readCount => targets.where((t) => t.isRead).length;
  int get unreadCount => totalRecipients - readCount;
  double get readPercentage => totalRecipients > 0 ? (readCount / totalRecipients) * 100 : 0.0;
}

class _NotificationsManagementViewState extends State<NotificationsManagementView> {
  static const Color primaryNavy = Color(0xFF0E1B4D);
  static const Color accentGold = Color(0xFFC5A059);

  SupabaseClient get supabase => AdminSupabase.client;

  bool _isLoading = true;
  List<NotificationCampaign> _campaigns = [];
  Map<String, Map<String, dynamic>> _studentsMap = {}; // academicId -> student info

  // تفاصيل الإشعار المحدد للمعاينة
  NotificationCampaign? _selectedCampaign;
  final Set<String> _selectedStudentTargetIds = {}; // IDs of selected student targets

  // محركات البحث والفلترة
  String _searchQuery = '';
  String _filterType = 'الكل';
  String _filterStatus = 'الكل';

  bool _canNotif(String serviceKey, PermissionAction action) {
    return PermissionService.can('notifications', serviceKey, action);
  }

  bool get _isNotifReadOnly =>
      !_canNotif('send_notifications', PermissionAction.create) &&
      !_canNotif('notifications_history', PermissionAction.update) &&
      !_canNotif('notifications_history', PermissionAction.delete);

  void _showNoPermissionSnack([String msg = '⚠️ عذراً، حسابك يملك صلاحية قراءة فقط في قسم الإشعارات.']) {
    _showSnackbar(msg, isError: true);
  }

  String _normalizeDigits(String input) {
    const arabicDigits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    const englishDigits = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    String result = input.trim();
    for (int i = 0; i < 10; i++) {
      result = result.replaceAll(arabicDigits[i], englishDigits[i]);
    }
    return result;
  }

  Widget _buildReadOnlyBanner() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.amber.shade400, width: 1.2),
      ),
      child: Row(
        children: [
          Icon(Icons.lock_outline, color: Colors.amber.shade900, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'وضع القراءة فقط: حسابك يملك صلاحية استعراض سجل الإشعارات فقط، ولا يمكنك إرسال أو تعديل أو حذف الإشعارات.',
              style: TextStyle(
                color: Colors.amber.shade900,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        widget.onPathChanged?.call('الإشعارات > سجل الإشعارات وإدارة التنبيهات');
      }
    });
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    setState(() => _isLoading = true);
    try {
      // 1. جلب بيانات جميع الطلاب لربط أسمائهم وتخصصاتهم
      final studentsRes = await supabase.from('students').select(
        'academic_id, full_name, specialty, batch, semester, study_shift',
      );
      final sMap = <String, Map<String, dynamic>>{};
      for (var s in (studentsRes as List)) {
        final acadId = s['academic_id']?.toString() ?? '';
        if (acadId.isNotEmpty) {
          sMap[acadId] = Map<String, dynamic>.from(s as Map);
        }
      }
      _studentsMap = sMap;

      // 2. جلب جميع الإشعارات من Supabase
      final notifsRes = await supabase
          .from('notifications')
          .select()
          .order('created_at', ascending: false);

      final List notifsList = notifsRes as List;

      // 3. تجميع الإشعارات في حملات ومجموعات
      final Map<String, NotificationCampaign> campaignsMap = {};

      for (var row in notifsList) {
        final id = row['id']?.toString() ?? '';
        final acadId = row['academic_id']?.toString();
        final title = (row['title'] ?? 'إشعار').toString().trim();
        final body = (row['body'] ?? row['message'] ?? '').toString().trim();
        final type = (row['notification_type'] ?? 'general').toString();
        final rawDate = row['created_at']?.toString() ?? '';
        final createdAt = DateTime.tryParse(rawDate) ?? DateTime.now();
        final isRead = row['is_read'] == true;

        // مفتاح تجميع فريد للإشعار
        final timeKey = rawDate.length >= 16 ? rawDate.substring(0, 16) : rawDate;
        final isBroadcast = (acadId == null || acadId.isEmpty);
        final groupKey = isBroadcast
            ? 'broadcast_${id}_$title'
            : 'group_${title}_${body.hashCode}_$timeKey';

        if (!campaignsMap.containsKey(groupKey)) {
          campaignsMap[groupKey] = NotificationCampaign(
            groupKey: groupKey,
            title: title,
            body: body,
            type: type,
            createdAt: createdAt,
            isBroadcast: isBroadcast,
            targets: [],
          );
        }

        if (isBroadcast) {
          // إذا كان الإشعار عاماً لجميع الطلاب
          for (var entry in _studentsMap.entries) {
            campaignsMap[groupKey]!.targets.add(
              NotificationTargetStudent(
                id: id,
                academicId: entry.key,
                studentName: entry.value['full_name'] ?? 'طالب',
                specialty: entry.value['specialty'] ?? '',
                batch: entry.value['batch'] ?? '',
                semester: entry.value['semester'] ?? '',
                isRead: isRead,
                createdAt: createdAt,
              ),
            );
          }
        } else {
          // إشعار مخصص لطالب أو مجموعة طلاب محددين
          final studentInfo = _studentsMap[acadId];
          campaignsMap[groupKey]!.targets.add(
            NotificationTargetStudent(
              id: id,
              academicId: acadId,
              studentName: studentInfo?['full_name'] ?? 'طالب رقم $acadId',
              specialty: studentInfo?['specialty'] ?? 'غير محدد',
              batch: studentInfo?['batch'] ?? '',
              semester: studentInfo?['semester'] ?? '',
              isRead: isRead,
              createdAt: createdAt,
            ),
          );
        }
      }

      final loadedCampaigns = campaignsMap.values.toList();
      // فرز بالأحدث
      loadedCampaigns.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      if (mounted) {
        setState(() {
          _campaigns = loadedCampaigns;
          // تحديث الحملة المحددة إن وجدت
          if (_selectedCampaign != null) {
            _selectedCampaign = _campaigns.firstWhere(
              (c) => c.groupKey == _selectedCampaign!.groupKey,
              orElse: () => _selectedCampaign!,
            );
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading notifications: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        _showSnackbar('حدث خطأ أثناء تحميل سجل الإشعارات: $e', isError: true);
      }
    }
  }

  void _showSnackbar(String msg, {bool isError = false}) {
    String cleanMsg = msg;
    if (isError) {
      debugPrint('[Notifications Error]: $msg');
      if (cleanMsg.contains('PostgrestException') ||
          cleanMsg.contains('Exception') ||
          cleanMsg.contains('SocketException') ||
          cleanMsg.contains('code:')) {
        if (cleanMsg.contains('SocketException') || cleanMsg.contains('timed out')) {
          cleanMsg = 'تعذر الاتصال بالخادم، يرجى التحقق من اتصال الإنترنت';
        } else {
          final colonIdx = cleanMsg.indexOf(':');
          if (colonIdx > 0 && colonIdx < 40) {
            cleanMsg = cleanMsg.substring(0, colonIdx).trim() + '، يرجى المحاولة مجدداً';
          } else {
            cleanMsg = 'حدث خطأ أثناء تنفيذ العملية، يرجى إعادة المحاولة';
          }
        }
      }
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(cleanMsg, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: isError ? Colors.red.shade800 : Colors.green.shade800,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // --- دوال التحكم بالإشعار بالكامل ---

  // 1. حذف الإشعار بالكامل
  Future<void> _deleteCampaign(NotificationCampaign campaign) async {
    if (!_canNotif('notifications_history', PermissionAction.delete)) {
      _showNoPermissionSnack('⚠️ عذراً، حسابك لا يملك صلاحية حذف الإشعارات.');
      return;
    }
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text('تأكيد حذف الإشعار بالكامل'),
          ],
        ),
        content: Text('هل أنت متأكد من حذف الإشعار "${campaign.title}" لجميع الطلاب المستهدفين؟ سيتم حذفه من قاعدة البيانات ومن حسابات الطلاب.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('نعم، حذف نهائي', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final notifIds = campaign.targets.map((t) => t.id).toSet().toList();
      await supabase.from('notifications').delete().inFilter('id', notifIds);

      _showSnackbar('تم حذف الإشعار بالكامل بنجاح');
      if (_selectedCampaign?.groupKey == campaign.groupKey) {
        setState(() {
          _selectedCampaign = null;
          _selectedStudentTargetIds.clear();
        });
      }
      _loadAllData();
    } catch (e) {
      _showSnackbar('فشل حذف الإشعار: $e', isError: true);
    }
  }

  // 2. تعديل نص وعنوان الإشعار بالكامل
  Future<void> _editCampaign(NotificationCampaign campaign) async {
    if (!_canNotif('notifications_history', PermissionAction.update)) {
      _showNoPermissionSnack('⚠️ عذراً، حسابك لا يملك صلاحية تعديل الإشعارات.');
      return;
    }
    final titleCtrl = TextEditingController(text: campaign.title);
    final bodyCtrl = TextEditingController(text: campaign.body);

    final save = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تعديل الإشعار', style: TextStyle(color: primaryNavy, fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(
                  labelText: 'عنوان الإشعار',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.title, color: primaryNavy),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: bodyCtrl,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'نص الإشعار / الرسالة',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.message, color: primaryNavy),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: primaryNavy),
            child: const Text('حفظ التعديل', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (save != true) return;

    try {
      final newTitle = titleCtrl.text.trim();
      final newBody = bodyCtrl.text.trim();
      if (newTitle.isEmpty) {
        _showSnackbar('يجب إدخال عنوان للإشعار', isError: true);
        return;
      }

      final notifIds = campaign.targets.map((t) => t.id).toSet().toList();
      await supabase.from('notifications').update({
        'title': newTitle,
        'body': newBody,
        'is_read': false,
      }).inFilter('id', notifIds);

      // إرسال تنبيه سحابي فوري ومحدث عبر Firebase حتى والتطبيق مغلق
      if (campaign.isBroadcast || campaign.targets.length > 20) {
        FcmSenderService.sendToTopic(
          topic: 'all_students',
          title: newTitle,
          body: newBody,
          routeName: campaign.type,
        );
      } else {
        for (final t in campaign.targets) {
          if (t.academicId.isNotEmpty) {
            FcmSenderService.sendToTopic(
              topic: 'student_${t.academicId}',
              title: newTitle,
              body: newBody,
              routeName: campaign.type,
            );
          }
        }
      }

      _showSnackbar('تم تعديل الإشعار في قاعدة البيانات وإعادة إرساله للطلاب بنجاح');
      _loadAllData();
    } catch (e) {
      _showSnackbar('فشل تعديل الإشعار: $e', isError: true);
    }
  }

  // --- دوال التحكم بالطلاب المحددين (Checkbox Selection) ---

  // 3. حذف الإشعار للطلاب المحددين فقط
  Future<void> _deleteForSelectedStudents() async {
    if (_selectedStudentTargetIds.isEmpty || _selectedCampaign == null) return;

    final count = _selectedStudentTargetIds.length;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.delete_sweep, color: Colors.red),
            const SizedBox(width: 8),
            Text('حذف الإشعار لـ ($count) طلاب محددين'),
          ],
        ),
        content: Text('هل أنت متأكد من حذف الإشعار من حسابات الطلاب المحددين وعددهم ($count)؟ سيبقى الإشعار لباقي الطلاب.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('نعم، حذف للمحددين', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final selectedTargets = _selectedCampaign!.targets
          .where((t) => _selectedStudentTargetIds.contains(t.academicId))
          .toList();

      if (_selectedCampaign!.isBroadcast) {
        _showSnackbar('الإشعار العام مرسل لجميع الطلاب، لحذفه يتم حذف الإشعار بالكامل', isError: true);
        return;
      }

      final notifIds = selectedTargets.map((t) => t.id).toList();
      await supabase.from('notifications').delete().inFilter('id', notifIds);

      _showSnackbar('تم حذف الإشعار للطلاب المحددين بنجاح ($count طالب)');
      setState(() {
        _selectedStudentTargetIds.clear();
      });
      _loadAllData();
    } catch (e) {
      _showSnackbar('فشل حذف الإشعار للطلاب المحددين: $e', isError: true);
    }
  }

  // 4. تعديل الإشعار للطلاب المحددين فقط
  Future<void> _editForSelectedStudents() async {
    if (_selectedStudentTargetIds.isEmpty || _selectedCampaign == null) return;

    final count = _selectedStudentTargetIds.length;
    final titleCtrl = TextEditingController(text: _selectedCampaign!.title);
    final bodyCtrl = TextEditingController(text: _selectedCampaign!.body);

    final save = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('تعديل الإشعار لـ ($count) طلاب محددين', style: const TextStyle(color: primaryNavy, fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(labelText: 'عنوان الإشعار المخصص', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: bodyCtrl,
                maxLines: 4,
                decoration: const InputDecoration(labelText: 'نص الإشعار المخصص', border: OutlineInputBorder()),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: accentGold),
            child: const Text('تطبيق التعديل للمحددين', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (save != true) return;

    try {
      final selectedTargets = _selectedCampaign!.targets
          .where((t) => _selectedStudentTargetIds.contains(t.academicId))
          .toList();

      final notifIds = selectedTargets.map((t) => t.id).toList();
      final newTitle = titleCtrl.text.trim();
      final newBody = bodyCtrl.text.trim();
      await supabase.from('notifications').update({
        'title': newTitle,
        'body': newBody,
        'is_read': false,
      }).inFilter('id', notifIds);

      // إرسال تنبيه سحابي فوري ومحدث لكل طالب محدد عبر Firebase حتى والتطبيق مغلق
      for (final t in selectedTargets) {
        if (t.academicId.isNotEmpty) {
          FcmSenderService.sendToTopic(
            topic: 'student_${t.academicId}',
            title: newTitle,
            body: newBody,
            routeName: _selectedCampaign?.type,
          );
        }
      }

      _showSnackbar('تم تعديل الإشعار في قاعدة البيانات وإعادة إرساله للطلاب المحددين ($count طالب)');
      setState(() => _selectedStudentTargetIds.clear());
      _loadAllData();
    } catch (e) {
      _showSnackbar('فشل تعديل الإشعار: $e', isError: true);
    }
  }

  // 5. تبديل حالة القراءة يدوياً لطالب محدد
  Future<void> _toggleStudentReadStatus(NotificationTargetStudent target) async {
    try {
      final newStatus = !target.isRead;
      await supabase
          .from('notifications')
          .update({'is_read': newStatus})
          .eq('id', target.id);

      setState(() {
        target.isRead = newStatus;
      });
      _showSnackbar(newStatus ? 'تم وضع الإشعار كمقروء' : 'تم وضع الإشعار كغير مقروء');
    } catch (e) {
      _showSnackbar('فشل تحديث الحالة: $e', isError: true);
    }
  }

  // 6. حذف الإشعار لطالب مفرد
  Future<void> _deleteForSingleStudent(NotificationTargetStudent target) async {
    if (!_canNotif('notifications_history', PermissionAction.delete)) {
      _showNoPermissionSnack('⚠️ عذراً، حسابك لا يملك صلاحية حذف الإشعارات.');
      return;
    }
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تأكيد حذف الإشعار للطالب'),
        content: Text('هل أنت متأكد من حذف الإشعار عن الطالب: ${target.studentName} (${target.academicId})؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('حذف', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await supabase.from('notifications').delete().eq('id', target.id);
      _showSnackbar('تم حذف الإشعار للطالب بنجاح');
      _loadAllData();
    } catch (e) {
      _showSnackbar('فشل الحذف: $e', isError: true);
    }
  }

  // 7. إرسال إشعار جديد
  Future<void> _showSendNewNotificationDialog() async {
    if (!_canNotif('send_notifications', PermissionAction.create)) {
      _showNoPermissionSnack('⚠️ عذراً، حسابك لا يملك صلاحية إرسال إشعارات جديدة.');
      return;
    }
    final titleCtrl = TextEditingController();
    final bodyCtrl = TextEditingController();
    String targetMode = 'all'; // 'all', 'specialty', 'single'
    String selectedSpecialty = '';
    String singleAcademicId = '';
    String selectedType = 'general';

    final specialties = _studentsMap.values
        .map((s) => s['specialty']?.toString() ?? '')
        .where((s) => s.isNotEmpty)
        .toSet()
        .toList();

    if (specialties.isNotEmpty) selectedSpecialty = specialties.first;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.add_alert, color: accentGold),
              SizedBox(width: 8),
              Text('إرسال إشعار جديد للطلاب', style: TextStyle(color: primaryNavy, fontWeight: FontWeight.bold)),
            ],
          ),
          content: SizedBox(
            width: 550,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('الجهة المستهدفة:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Radio<String>(
                        value: 'all',
                        groupValue: targetMode,
                        onChanged: (v) => setDialogState(() => targetMode = v!),
                      ),
                      const Text('جميع الطلاب'),
                      const SizedBox(width: 16),
                      Radio<String>(
                        value: 'specialty',
                        groupValue: targetMode,
                        onChanged: (v) => setDialogState(() => targetMode = v!),
                      ),
                      const Text('تخصص محدد'),
                      const SizedBox(width: 16),
                      Radio<String>(
                        value: 'single',
                        groupValue: targetMode,
                        onChanged: (v) => setDialogState(() => targetMode = v!),
                      ),
                      const Text('طالب محدد'),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (targetMode == 'specialty') ...[
                    DropdownButtonFormField<String>(
                      value: selectedSpecialty,
                      decoration: const InputDecoration(labelText: 'اختر التخصص المستهدف', border: OutlineInputBorder()),
                      items: specialties.map((sp) => DropdownMenuItem(value: sp, child: Text(sp))).toList(),
                      onChanged: (v) => setDialogState(() => selectedSpecialty = v ?? ''),
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (targetMode == 'single') ...[
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'الرقم الأكاديمي للطالب',
                        hintText: 'مثال: 2025010101',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                      ),
                      onChanged: (v) => singleAcademicId = v.trim(),
                    ),
                    const SizedBox(height: 16),
                  ],
                  DropdownButtonFormField<String>(
                    value: selectedType,
                    decoration: const InputDecoration(labelText: 'نوع الإشعار', border: OutlineInputBorder()),
                    items: const [
                      DropdownMenuItem(value: 'general', child: Text('🔔 إشعار عام / إداري')),
                      DropdownMenuItem(value: 'schedule', child: Text('📚 إشعار جداول دراسية')),
                      DropdownMenuItem(value: 'finance', child: Text('💰 إشعار مالي ورسوم')),
                      DropdownMenuItem(value: 'result', child: Text('🎓 إشعار نتائج درجات')),
                      DropdownMenuItem(value: 'event', child: Text('📅 إشعار مناسبة وتقويم')),
                    ],
                    onChanged: (v) => setDialogState(() => selectedType = v ?? 'general'),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: titleCtrl,
                    decoration: const InputDecoration(
                      labelText: 'عنوان الإشعار *',
                      hintText: 'مثال: تنبيه بخصوص موعد بدء الاختبارات النصفية',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: bodyCtrl,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'نص الإشعار / الرسالة *',
                      hintText: 'اكتب نص الرسالة التي ستصل للطلاب على التطبيق...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
            ElevatedButton.icon(
              onPressed: () async {
                final title = titleCtrl.text.trim();
                final body = bodyCtrl.text.trim();
                if (title.isEmpty || body.isEmpty) {
                  _showSnackbar('يرجى كتابة عنوان الإشعار ونص الرسالة', isError: true);
                  return;
                }

                Navigator.pop(ctx);
                try {
                  final nowIso = DateTime.now().toIso8601String();

                  if (targetMode == 'all') {
                    // إرسال عام: إدراج لكل طالب مسجل لتمكين تتبع حالة القراءة بدقة
                    if (_studentsMap.isNotEmpty) {
                      final inserts = _studentsMap.keys.map((acadId) => {
                        'academic_id': acadId,
                        'title': title,
                        'body': body,
                        'notification_type': selectedType,
                        'route_name': selectedType,
                        'is_read': false,
                        'created_at': nowIso,
                      }).toList();
                      await supabase.from('notifications').insert(inserts);
                    } else {
                      await supabase.from('notifications').insert({
                        'academic_id': null,
                        'title': title,
                        'body': body,
                        'notification_type': selectedType,
                        'route_name': selectedType,
                        'is_read': false,
                        'created_at': nowIso,
                      });
                    }

                    // إرسال تنبيه فوري للهواتف حتى والتطبيق مغلق عبر Firebase
                    await FcmSenderService.sendToTopic(
                      topic: 'all_students',
                      title: title,
                      body: body,
                      routeName: selectedType,
                    );
                  } else if (targetMode == 'specialty') {
                    // استهداف طلاب تخصص محدد
                    final targetIds = _studentsMap.entries
                        .where((e) => e.value['specialty'] == selectedSpecialty)
                        .map((e) => e.key)
                        .toList();

                    if (targetIds.isEmpty) {
                      _showSnackbar('لا يوجد طلاب مسجلين في هذا التخصص', isError: true);
                      return;
                    }

                    final inserts = targetIds.map((acadId) => {
                      'academic_id': acadId,
                      'title': title,
                      'body': body,
                      'notification_type': selectedType,
                      'route_name': selectedType,
                      'is_read': false,
                      'created_at': nowIso,
                    }).toList();

                    await supabase.from('notifications').insert(inserts);

                    // إرسال تنبيه فوري لكل طالب في هذا التخصص عبر Firebase
                    for (final acadId in targetIds) {
                      await FcmSenderService.sendToTopic(
                        topic: 'student_$acadId',
                        title: title,
                        body: body,
                        routeName: selectedType,
                      );
                    }
                  } else {
                    // طالب مفرد
                    final normalizedId = _normalizeDigits(singleAcademicId);
                    if (normalizedId.isEmpty) {
                      _showSnackbar('يرجى إدخال الرقم الأكاديمي', isError: true);
                      return;
                    }

                    // التحقق من وجود الطالب في النظام قبل الإرسال لمنع أخطاء قيود الربط
                    final studentExists = _studentsMap.containsKey(normalizedId);
                    if (!studentExists) {
                      final checkRes = await supabase.from('students').select('academic_id').eq('academic_id', normalizedId).maybeSingle();
                      if (checkRes == null) {
                        _showSnackbar('⚠️ الرقم الأكاديمي ($normalizedId) غير مسجل في جدول الطلاب!', isError: true);
                        return;
                      }
                    }

                    await supabase.from('notifications').insert({
                      'academic_id': normalizedId,
                      'title': title,
                      'body': body,
                      'notification_type': selectedType,
                      'route_name': selectedType,
                      'is_read': false,
                      'created_at': nowIso,
                    });

                    // إرسال تنبيه فوري للطالب المحدد عبر Firebase
                    await FcmSenderService.sendToTopic(
                      topic: 'student_$normalizedId',
                      title: title,
                      body: body,
                      routeName: selectedType,
                    );
                  }

                  _showSnackbar('تم إرسال الإشعار بنجاح وإيصاله للطلاب!');
                  _loadAllData();
                } catch (e) {
                  final errStr = e.toString();
                  if (errStr.contains('23503')) {
                    _showSnackbar('فشل الإرسال: الرقم الأكاديمي غير مسجل في قاعدة البيانات', isError: true);
                  } else {
                    _showSnackbar('فشل إرسال الإشعار: $e', isError: true);
                  }
                }
              },
              icon: const Icon(Icons.send, color: Colors.white, size: 18),
              label: const Text('إرسال الإشعار فوراً', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(backgroundColor: primaryNavy, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14)),
            ),
          ],
        ),
      ),
    );
  }

  // --- واجهة المستخدم الرئيسية (Build) ---

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: accentGold),
            SizedBox(height: 16),
            Text('جاري تحميل سجل الإشعارات وإحصائيات الطلاب...', style: TextStyle(fontSize: 16, color: primaryNavy, fontWeight: FontWeight.bold)),
          ],
        ),
      );
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        color: const Color(0xFFF4F6F9),
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ترويسة الصفحة
            _buildHeader(),
            const SizedBox(height: 20),

            if (_isNotifReadOnly) _buildReadOnlyBanner(),

            // بطاقات الإحصائيات العلوية
            _buildStatsCards(),
            const SizedBox(height: 20),

            // محتوى الشاشة (إما سجل الإشعارات أو تفاصيل الإشعار المحدد)
            Expanded(
              child: _selectedCampaign == null
                  ? _buildCampaignsList()
                  : _buildCampaignDetailsView(_selectedCampaign!),
            ),
          ],
        ),
      ),
    );
  }

  // 1. ترويسة الصفحة
  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.notifications_active, color: accentGold, size: 28),
                const SizedBox(width: 10),
                Text(
                  _selectedCampaign == null ? 'سجل الإشعارات والتنبيهات المباشرة' : 'تفاصيل الإشعار والطلاب المخصص لهم',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: primaryNavy),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              _selectedCampaign == null
                  ? 'متابعة وصول الإشعارات، حالة القراءة لدى الطلاب، وإمكانية التعديل والحذف الجماعي أو الفردي'
                  : 'يمكنك مراجعة كل طالب هل وصله الإشعار وهل قرأه، وتحديد الطلاب لحذف الإشعار أو تعديله لهم',
              style: const TextStyle(fontSize: 13, color: Colors.grey),
            ),
          ],
        ),
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.refresh, color: primaryNavy),
              tooltip: 'تحديث البيانات',
              onPressed: _loadAllData,
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: _showSendNewNotificationDialog,
              icon: const Icon(Icons.add, color: Colors.white, size: 18),
              label: const Text('إرسال إشعار جديد', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: accentGold,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // 2. بطاقات الإحصائيات
  Widget _buildStatsCards() {
    final totalCampaigns = _campaigns.length;
    int totalRecipients = 0;
    int totalRead = 0;
    int totalUnread = 0;

    for (var c in _campaigns) {
      totalRecipients += c.totalRecipients;
      totalRead += c.readCount;
      totalUnread += c.unreadCount;
    }

    final overallReadRate = totalRecipients > 0 ? (totalRead / totalRecipients) * 100 : 0.0;

    return Row(
      children: [
        _buildStatCard('إجمالي حملات الإشعارات', '$totalCampaigns', Icons.campaign, Colors.blue.shade700),
        const SizedBox(width: 16),
        _buildStatCard('إجمالي الطلاب المستهدفين', '$totalRecipients', Icons.people_alt, primaryNavy),
        const SizedBox(width: 16),
        _buildStatCard('تمت القراءة (${overallReadRate.toStringAsFixed(1)}%)', '$totalRead', Icons.done_all, Colors.green.shade700),
        const SizedBox(width: 16),
        _buildStatCard('لم تُقرأ بعد', '$totalUnread', Icons.mark_email_unread_outlined, Colors.orange.shade800),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 6)],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 3. عرض سجل الإشعارات (القائمة الرئيسية)
  Widget _buildCampaignsList() {
    final filtered = _campaigns.where((c) {
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchTitle = c.title.toLowerCase().contains(q);
        final matchBody = c.body.toLowerCase().contains(q);
        if (!matchTitle && !matchBody) return false;
      }
      if (_filterType != 'الكل' && c.type != _filterType) return false;
      if (_filterStatus == 'مقروء بالكامل' && c.unreadCount > 0) return false;
      if (_filterStatus == 'يحتوي على غير مقروء' && c.unreadCount == 0) return false;
      return true;
    }).toList();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          // شريط البحث والفلترة
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'ابحث في الإشعارات بالعنوان أو النص...',
                      prefixIcon: const Icon(Icons.search, color: primaryNavy),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onChanged: (v) => setState(() => _searchQuery = v.trim()),
                  ),
                ),
                const SizedBox(width: 16),
                DropdownButton<String>(
                  value: _filterType,
                  underline: const SizedBox(),
                  items: const [
                    DropdownMenuItem(value: 'الكل', child: Text('جميع الأنواع')),
                    DropdownMenuItem(value: 'general', child: Text('🔔 عام')),
                    DropdownMenuItem(value: 'schedule', child: Text('📚 جداول')),
                    DropdownMenuItem(value: 'finance', child: Text('💰 مالي')),
                    DropdownMenuItem(value: 'result', child: Text('🎓 نتائج')),
                    DropdownMenuItem(value: 'event', child: Text('📅 تقويم')),
                  ],
                  onChanged: (v) => setState(() => _filterType = v ?? 'الكل'),
                ),
                const SizedBox(width: 16),
                DropdownButton<String>(
                  value: _filterStatus,
                  underline: const SizedBox(),
                  items: const [
                    DropdownMenuItem(value: 'الكل', child: Text('جميع الحالات')),
                    DropdownMenuItem(value: 'مقروء بالكامل', child: Text('✅ مقروء بالكامل')),
                    DropdownMenuItem(value: 'يحتوي على غير مقروء', child: Text('⏳ يحتوي على غير مقروء')),
                  ],
                  onChanged: (v) => setState(() => _filterStatus = v ?? 'الكل'),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // قائمة الإشعارات
          Expanded(
            child: filtered.isEmpty
                ? const Center(
                    child: Text('لا توجد إشعارات مطابقة لمعايير البحث', style: TextStyle(color: Colors.grey, fontSize: 16)),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (ctx, idx) {
                      final c = filtered[idx];
                      return _buildCampaignCard(c);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // بطاقة إشعار منفرد في السجل
  Widget _buildCampaignCard(NotificationCampaign c) {
    final typeBadge = _getTypeBadge(c.type);
    final dateStr = '${c.createdAt.year}/${c.createdAt.month.toString().padLeft(2, '0')}/${c.createdAt.day.toString().padLeft(2, '0')} - ${c.createdAt.hour}:${c.createdAt.minute.toString().padLeft(2, '0')}';

    return InkWell(
      onTap: () {
        setState(() {
          _selectedCampaign = c;
          _selectedStudentTargetIds.clear();
        });
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.015), blurRadius: 4)],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // أيقونة النوع
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: primaryNavy.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(typeBadge['icon'] as IconData, color: primaryNavy, size: 24),
            ),
            const SizedBox(width: 16),

            // تفاصيل الإشعار
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        c.title,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: primaryNavy),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: (typeBadge['color'] as Color).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          typeBadge['label'] as String,
                          style: TextStyle(color: typeBadge['color'] as Color, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const Spacer(),
                      Text(dateStr, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    c.body,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade800, height: 1.4),
                  ),
                  const SizedBox(height: 12),

                  // مؤشرات الوصول والقراءة
                  Row(
                    children: [
                      // المستهدفين
                      Row(
                        children: [
                          const Icon(Icons.people_outline, size: 16, color: Colors.blueGrey),
                          const SizedBox(width: 4),
                          Text(
                            c.isBroadcast ? 'مخصص لجميع الطلاب (${c.totalRecipients})' : 'مخصص لـ (${c.totalRecipients}) طالب',
                            style: const TextStyle(fontSize: 12, color: Colors.blueGrey, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(width: 24),

                      // حالة القراءة
                      Row(
                        children: [
                          Icon(
                            c.unreadCount == 0 ? Icons.done_all : Icons.visibility_outlined,
                            size: 16,
                            color: c.unreadCount == 0 ? Colors.green.shade700 : Colors.orange.shade800,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'تمت القراءة: ${c.readCount} من أصل ${c.totalRecipients} (${c.readPercentage.toStringAsFixed(0)}%)',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: c.unreadCount == 0 ? Colors.green.shade700 : Colors.orange.shade800,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),

            // أزرار سريعة
            Column(
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _selectedCampaign = c;
                      _selectedStudentTargetIds.clear();
                    });
                  },
                  icon: const Icon(Icons.visibility, size: 15, color: Colors.white),
                  label: const Text('معاينة الطلاب', style: TextStyle(fontSize: 12, color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryNavy,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, size: 18, color: Colors.blueGrey),
                      tooltip: 'تعديل الإشعار',
                      onPressed: () => _editCampaign(c),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                      tooltip: 'حذف الإشعار بالكامل',
                      onPressed: () => _deleteCampaign(c),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // 4. عرض تفاصيل الإشعار المحدد وقائمة الطلاب المستهدفين
  Widget _buildCampaignDetailsView(NotificationCampaign campaign) {
    final bool allSelected = campaign.targets.isNotEmpty &&
        _selectedStudentTargetIds.length == campaign.targets.length;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          // شريط معلومات الإشعار والأزرار العلوية
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: () {
                        setState(() {
                          _selectedCampaign = null;
                          _selectedStudentTargetIds.clear();
                        });
                      },
                      icon: const Icon(Icons.arrow_forward, size: 16),
                      label: const Text('العودة لسجل الإشعارات'),
                      style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10)),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        'الإشعار: ${campaign.title}',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryNavy),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _editCampaign(campaign),
                      icon: const Icon(Icons.edit, size: 16, color: Colors.white),
                      label: const Text('تعديل الإشعار', style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(backgroundColor: primaryNavy),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton.icon(
                      onPressed: () => _deleteCampaign(campaign),
                      icon: const Icon(Icons.delete_forever, size: 16, color: Colors.white),
                      label: const Text('حذف الإشعار بالكامل', style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('نص الرسالة:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                      const SizedBox(height: 4),
                      Text(campaign.body, style: const TextStyle(fontSize: 14, color: Colors.black87, height: 1.4)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // شريط إجراءات التحديد المجمع (Bulk Selection Toolbar)
          if (_selectedStudentTargetIds.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: accentGold.withOpacity(0.15),
              child: Row(
                children: [
                  const Icon(Icons.checklist, color: primaryNavy),
                  const SizedBox(width: 8),
                  Text(
                    'تم تحديد (${_selectedStudentTargetIds.length}) من أصل (${campaign.totalRecipients}) طلاب',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: primaryNavy, fontSize: 14),
                  ),
                  const Spacer(),
                  ElevatedButton.icon(
                    onPressed: _editForSelectedStudents,
                    icon: const Icon(Icons.edit, size: 16, color: Colors.white),
                    label: const Text('تعديل الإشعار للمحددين', style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(backgroundColor: primaryNavy),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    onPressed: _deleteForSelectedStudents,
                    icon: const Icon(Icons.delete_sweep, size: 16, color: Colors.white),
                    label: const Text('حذف الإشعار للمحددين', style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade800),
                  ),
                  const SizedBox(width: 10),
                  TextButton(
                    onPressed: () => setState(() => _selectedStudentTargetIds.clear()),
                    child: const Text('إلغاء التحديد'),
                  ),
                ],
              ),
            ),

          // جدول الطلاب المخصص لهم الإشعار
          Expanded(
            child: DesktopTableScrollView(
              child: DataTable(
                headingRowColor: MaterialStateProperty.all(primaryNavy),
                headingTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                dataRowHeight: 56,
                columns: [
                  DataColumn(
                    label: Row(
                      children: [
                        Checkbox(
                          value: allSelected,
                          checkColor: primaryNavy,
                          activeColor: Colors.white,
                          onChanged: (val) {
                            setState(() {
                              if (val == true) {
                                _selectedStudentTargetIds.clear();
                                for (var t in campaign.targets) {
                                  _selectedStudentTargetIds.add(t.academicId);
                                }
                              } else {
                                _selectedStudentTargetIds.clear();
                              }
                            });
                          },
                        ),
                        const Text('تحديد الكل', style: TextStyle(color: Colors.white)),
                      ],
                    ),
                  ),
                  const DataColumn(label: Text('م')),
                  const DataColumn(label: Text('الرقم الأكاديمي')),
                  const DataColumn(label: Text('اسم الطالب رباعي')),
                  const DataColumn(label: Text('التخصص / الدفعة')),
                  const DataColumn(label: Text('حالة الوصول')),
                  const DataColumn(label: Text('حالة القراءة')),
                  const DataColumn(label: Text('إجراءات')),
                ],
                rows: campaign.targets.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final t = entry.value;
                  final isSelected = _selectedStudentTargetIds.contains(t.academicId);

                  return DataRow(
                    selected: isSelected,
                    onSelectChanged: (val) {
                      setState(() {
                        if (val == true) {
                          _selectedStudentTargetIds.add(t.academicId);
                        } else {
                          _selectedStudentTargetIds.remove(t.academicId);
                        }
                      });
                    },
                    cells: [
                      DataCell(
                        Checkbox(
                          value: isSelected,
                          activeColor: accentGold,
                          onChanged: (val) {
                            setState(() {
                              if (val == true) {
                                _selectedStudentTargetIds.add(t.academicId);
                              } else {
                                _selectedStudentTargetIds.remove(t.academicId);
                              }
                            });
                          },
                        ),
                      ),
                      DataCell(Text('${idx + 1}')),
                      DataCell(Text(t.academicId, style: const TextStyle(fontWeight: FontWeight.bold))),
                      DataCell(Text(t.studentName, style: const TextStyle(fontWeight: FontWeight.w600))),
                      DataCell(Text('${t.specialty} ${t.batch.isNotEmpty ? "(${t.batch})" : ""}')),
                      // حالة الوصول (هل وصل الإشعار للطالب)
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.green.shade300),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.send_rounded, size: 13, color: Colors.green.shade700),
                              const SizedBox(width: 4),
                              Text('تم البث سحابياً', style: TextStyle(color: Colors.green.shade800, fontSize: 11.5, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                      // حالة القراءة (هل قرأ الطالب الإشعار)
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: t.isRead ? Colors.blue.shade50 : Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: t.isRead ? Colors.blue.shade300 : Colors.orange.shade300),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                t.isRead ? Icons.done_all : Icons.access_time,
                                size: 14,
                                color: t.isRead ? Colors.blue.shade700 : Colors.orange.shade800,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                t.isRead ? 'تمت القراءة' : 'لم يُقرأ بعد',
                                style: TextStyle(
                                  color: t.isRead ? Colors.blue.shade800 : Colors.orange.shade900,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // إجراءات على سطر الطالب
                      DataCell(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(
                                t.isRead ? Icons.mark_email_unread_outlined : Icons.mark_email_read_outlined,
                                size: 18,
                                color: primaryNavy,
                              ),
                              tooltip: t.isRead ? 'تعيين كغير مقروء' : 'تعيين كمقروء',
                              onPressed: () => _toggleStudentReadStatus(t),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                              tooltip: 'حذف الإشعار عن هذا الطالب',
                              onPressed: () => _deleteForSingleStudent(t),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
        ),
        ],
      ),
    );
  }

  // أداة مساعدة لأيقونة ولون نوع الإشعار
  Map<String, dynamic> _getTypeBadge(String type) {
    switch (type) {
      case 'result':
        return {'label': 'نتائج ودرجات', 'icon': Icons.school, 'color': Colors.purple.shade700};
      case 'finance':
        return {'label': 'رسوم ومالية', 'icon': Icons.attach_money, 'color': Colors.teal.shade700};
      case 'schedule':
        return {'label': 'جداول دراسية', 'icon': Icons.calendar_month, 'color': Colors.blue.shade700};
      case 'event':
        return {'label': 'تقويم ومناسبات', 'icon': Icons.event_available, 'color': Colors.amber.shade800};
      case 'general':
      default:
        return {'label': 'إشعار عام', 'icon': Icons.notifications_active, 'color': primaryNavy};
    }
  }
}
