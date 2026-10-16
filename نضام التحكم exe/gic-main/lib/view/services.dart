import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart' as xl;
import 'package:gic/services/supabase_service.dart';
import 'package:gic/services/fcm_sender_service.dart';
import 'package:gic/utils/file_exporter.dart';

class ServicesView extends StatefulWidget {
  final Function(String path) onServiceTap;

  const ServicesView({
    Key? key,
    required this.onServiceTap,
  }) : super(key: key);

  @override
  State<ServicesView> createState() => _ServicesViewState();
}

class _ServicesViewState extends State<ServicesView> {
  static const Color primaryNavy = Color(0xFF0E1B4D);
  static const Color accentGold = Color(0xFFC5A059);
  static const Color dropDownBg = Color(0xFFDCDCDC);

  String? openServiceTitle;
  String currentPath = 'الخدمات';
  String? selectedSubService;

  // --- وحدات التحكم للتعليمات النصية (Instructions) ---
  final TextEditingController _instructionTitleController = TextEditingController();
  final TextEditingController _instructionSubtitleController = TextEditingController();
  final TextEditingController _instructionStepsController = TextEditingController();
  final TextEditingController _instructionNoteController = TextEditingController();
  final TextEditingController _instructionUrlController = TextEditingController();
  bool _isSavingInstruction = false;

  // --- وحدات التحكم للجداول (Schedules) ---
  final TextEditingController _scheduleTitleController = TextEditingController();
  final TextEditingController _scheduleUrlController = TextEditingController();
  final TextEditingController _scheduleSpecialtyController = TextEditingController();
  final TextEditingController _scheduleBatchController = TextEditingController();
  final TextEditingController _scheduleTermController = TextEditingController();
  List<Map<String, dynamic>> _schedulesList = [];
  bool _isLoadingSchedules = false;
  bool _isSavingSchedule = false;
  dynamic _editingScheduleId;
  Uint8List? _selectedScheduleFileBytes;
  String? _selectedScheduleFileName;
  String? _selectedScheduleFileUrl;
  bool _isPdfSchedule = true;

  // خيارات الشجرة الأكاديمية (يتم جلبها ديناميكياً وحصرياً من جدول academic_tree)
  List<Map<String, dynamic>> _treeNodes = [];
  List<String> _specialtiesOptions = [];
  List<String> _batchesOptions = [];
  List<String> _termsOptions = [];
  bool _isLoadingTree = false;

  // --- وحدات التحكم للكادر الأكاديمي (Staff) ---
  final TextEditingController _staffNameController = TextEditingController();
  final TextEditingController _staffSpecialtyController = TextEditingController();
  final TextEditingController _staffExpController = TextEditingController();
  final TextEditingController _staffBioController = TextEditingController();
  final TextEditingController _staffPhotoController = TextEditingController();
  List<Map<String, dynamic>> _staffList = [];
  bool _isLoadingStaff = false;

  // --- وحدات التحكم للتخصصات (Specialties) ---
  final TextEditingController _specTitleController = TextEditingController();
  final TextEditingController _specDegreeController = TextEditingController(text: 'بكالوريوس');
  final TextEditingController _specLocationController = TextEditingController(text: 'صنعاء - المقر الرئيسي');
  final TextEditingController _specImageController = TextEditingController();
  List<Map<String, dynamic>> _specList = [];
  bool _isLoadingSpecs = false;

  // --- وحدات التحكم للكنترول (Control / Excel) ---
  final TextEditingController _manualAcademicIdController = TextEditingController();
  final TextEditingController _manualParam1Controller = TextEditingController();
  final TextEditingController _manualParam2Controller = TextEditingController();
  final TextEditingController _manualParam3Controller = TextEditingController();

  // --- وحدات التحكم لأرقام الجلوس (Seating Numbers) ---
  final TextEditingController _seatingAcademicIdController = TextEditingController();
  final TextEditingController _seatingNumberController = TextEditingController();
  final TextEditingController _seatingHallController = TextEditingController(text: 'القاعة الكبرى');
  final TextEditingController _seatingTermController = TextEditingController(text: 'الفصل الدراسي الأول 2024/2025');
  final TextEditingController _seatingSearchController = TextEditingController();
  List<Map<String, dynamic>> _seatingList = [];
  bool _isLoadingSeating = false;
  bool _isSavingSeating = false;
  String? _editingSeatingAcademicId;
  String? _detectedStudentInfo;

  // --- وحدات التحكم للمالية (Finance) ---
  final TextEditingController _finAcademicIdController = TextEditingController();
  final TextEditingController _finTitleController = TextEditingController();
  final TextEditingController _finDetailsController = TextEditingController();
  final TextEditingController _finAmountController = TextEditingController();
  List<Map<String, dynamic>> _finList = [];
  bool _isLoadingFin = false;

  // --- وحدات التحكم للنتائج وكشوف درجات الطلاب (Results Management) ---
  List<Map<String, dynamic>> _resultsList = [];
  final TextEditingController _resultsSearchController = TextEditingController();
  bool _isLoadingResultsControl = false;
  bool _isPublishingResults = false;
  int _totalResultsCount = 0;
  String _latestResultUploadTime = '';
  String _latestResultTermName = '';

  final List<Map<String, dynamic>> servicesData = [
    {
      'title': 'القبول والتسجيل',
      'icon': Icons.how_to_reg_outlined,
      'items': [
        'متطلبات القبول والتسجيل',
        'التسجيل في مقر الكلية',
        'التسجيل أونلاين',
        'التسجيل عبر البوابة الإلكترونية لوزارة التربية',
      ],
    },
    {
      'title': 'الأكاديمية',
      'icon': Icons.co_present_outlined,
      'items': [
        'التخصصات الأكاديمية',
        'الكادر الأكاديمي والتدريس',
        'التدريب الميداني',
      ],
    },
    {
      'title': 'شؤون الطلاب',
      'icon': Icons.groups_outlined,
      'items': [
        'الجداول الدراسية',
        'الأنشطة والفعاليات',
        'تقديم طلب تحويل من تخصص إلى تخصص آخر',
        'تقديم طلب وقف قيد',
        'تقديم طلب فتح قيد',
        'تقديم طلب مقاصصة',
        'تقديم طلب تجميد ملف',
        'تقديم طلب سحب ملف',
      ],
    },
    {
      'title': 'شؤون الخريجين',
      'icon': Icons.school_outlined,
      'items': [
        'تقديم طلب استخراج إفادة تخرج',
        'تقديم طلب استخراج شهادة (دبلوم/بكالوريوس)',
        'تقديم طلب استخراج الوثائق اللازمة للتقديم على مزاولة المهنة',
      ],
    },
    {
      'title': 'الكنترول',
      'icon': Icons.fact_check_outlined,
      'items': [
        'جداول الامتحانات النصفية',
        'جداول الامتحانات النهائية',
        'أرقام الجلوس',
        'أوائل الطلاب',
        'النتائج',
        'تقديم طلب تظلم',
      ],
    },
    {
      'title': 'المالية',
      'icon': Icons.attach_money,
      'items': [
        'الإشعارات المالية وكشوفات الحساب',
      ],
    },
    {
      'title': 'معلومات الكلية والدعم',
      'icon': Icons.info_outline,
      'items': [
        'معلومات عنا',
        'المساعدة والدعم',
      ],
    },
    {
      'title': 'الإعلانات والإنجازات',
      'icon': Icons.workspace_premium_outlined,
      'items': [
        'البنرات الإعلانية',
        'سجل الإنجازات',
        'التقويم الأكاديمي',
      ],
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadAcademicTreeOptions();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onServiceTap(currentPath);
    });
  }

  void _showNotification(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, textDirection: TextDirection.rtl),
        backgroundColor: isError ? Colors.red.shade700 : Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  // --- 1. التعامل مع التعليمات النصية ---
  Future<void> _loadInstructionData(String key) async {
    _instructionTitleController.text = key;
    _instructionSubtitleController.clear();
    _instructionStepsController.clear();
    _instructionNoteController.clear();
    _instructionUrlController.clear();

    try {
      final res = await AdminSupabase.client
          .from('system_instructions')
          .select()
          .eq('service_key', key)
          .maybeSingle();

      if (res != null && mounted) {
        setState(() {
          _instructionTitleController.text = res['title'] ?? key;
          _instructionSubtitleController.text = res['subtitle'] ?? '';
          final rawSteps = res['steps'];
          if (rawSteps is List) {
            _instructionStepsController.text = rawSteps.join('\n');
          } else {
            _instructionStepsController.text = rawSteps?.toString() ?? '';
          }
          _instructionNoteController.text = res['note'] ?? '';
          _instructionUrlController.text = res['external_url'] ?? '';
        });
      }
    } catch (e) {
      debugPrint('Error loading instruction: $e');
    }
  }

  Future<void> _saveInstructionData() async {
    if (selectedSubService == null) return;
    setState(() => _isSavingInstruction = true);

    try {
      final stepsText = _instructionStepsController.text.trim();
      final stepsList = stepsText.split('\n').where((s) => s.trim().isNotEmpty).toList();

      await AdminSupabase.client.from('system_instructions').upsert({
        'service_key': selectedSubService,
        'title': _instructionTitleController.text.trim(),
        'subtitle': _instructionSubtitleController.text.trim(),
        'steps': stepsList,
        'note': _instructionNoteController.text.trim(),
        'external_url': _instructionUrlController.text.trim().isEmpty ? null : _instructionUrlController.text.trim(),
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'service_key');

      _showNotification('تم حفظ ونشر خدمة ($selectedSubService) بنجاح في التطبيق!');
    } catch (e) {
      _showNotification('فشل الحفظ: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isSavingInstruction = false);
    }
  }

  // --- 2. التعامل مع الجداول الدراسية والامتحانات ---
  String _mapSubServiceToScheduleType(String subService) {
    if (subService.contains('النصفية')) return 'midterm';
    if (subService.contains('النهائية')) return 'final';
    return 'study';
  }

  // تحميل خيارات التخصص والدفعة والفصل حصرياً من الشجرة الأكاديمية (academic_tree)
  Future<void> _loadAcademicTreeOptions() async {
    setState(() => _isLoadingTree = true);
    try {
      final res = await AdminSupabase.client
          .from('academic_tree')
          .select()
          .order('created_at', ascending: true);

      if (mounted) {
        final List<Map<String, dynamic>> nodes = List<Map<String, dynamic>>.from(res as List);
        _treeNodes = nodes;

        // التخصصات الأكاديمية المعتمدة من الشجرة (العقد من نوع semester التي تمثل التخصصات)
        final specTitles = nodes
            .where((n) => n['node_type'] == 'semester')
            .map((n) => (n['title'] ?? '').toString().trim())
            .where((t) => t.isNotEmpty)
            .toSet()
            .toList();

        // في حال كانت الشجرة فارغة أو لم يعثر على semester، نأخذ العقد المناسبة من الشجرة
        if (specTitles.isEmpty) {
          specTitles.addAll(
            nodes
                .where((n) => n['node_type'] != 'year' && n['node_type'] != 'specialty' && !((n['title'] ?? '').toString().contains('الدفعة')) && !((n['title'] ?? '').toString().contains('الفصل')))
                .map((n) => (n['title'] ?? '').toString().trim())
                .where((t) => t.isNotEmpty)
                .toSet(),
          );
        }

        setState(() {
          _specialtiesOptions = specTitles;
          if (_specialtiesOptions.isNotEmpty) {
            if (!_specialtiesOptions.contains(_scheduleSpecialtyController.text)) {
              _scheduleSpecialtyController.text = _specialtiesOptions.first;
            }
          }
          _updateBatchesAndTermsForSelectedSpecialty();
          _isLoadingTree = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading academic tree: $e');
      if (mounted) setState(() => _isLoadingTree = false);
    }
  }

  void _updateBatchesAndTermsForSelectedSpecialty() {
    final spec = _scheduleSpecialtyController.text.trim();
    final specNode = _treeNodes.firstWhere(
      (n) => n['node_type'] == 'semester' && (n['title'] ?? '').toString().trim() == spec,
      orElse: () => _treeNodes.firstWhere(
        (n) => (n['title'] ?? '').toString().trim() == spec,
        orElse: () => <String, dynamic>{},
      ),
    );

    List<String> batches = [];
    if (specNode.isNotEmpty && specNode['id'] != null) {
      final specId = specNode['id'];
      // الدفع التابعة لهذا التخصص في الشجرة
      batches = _treeNodes
          .where((n) => n['parent_id'] == specId)
          .map((n) => (n['title'] ?? '').toString().trim())
          .where((t) => t.isNotEmpty)
          .toSet()
          .toList();
    }

    // إذا لم توجد دفع مباشرة تحت هذا التخصص، نأخذ كل الدفع الموجودة في الشجرة
    if (batches.isEmpty) {
      batches = _treeNodes
          .where((n) => (n['title'] ?? '').toString().contains('الدفعة'))
          .map((n) => (n['title'] ?? '').toString().trim())
          .where((t) => t.isNotEmpty)
          .toSet()
          .toList();
    }

    _batchesOptions = batches;
    if (_batchesOptions.isNotEmpty) {
      if (!_batchesOptions.contains(_scheduleBatchController.text)) {
        _scheduleBatchController.text = _batchesOptions.first;
      }
    } else {
      _scheduleBatchController.text = 'الدفعة 1';
      _batchesOptions = ['الدفعة 1'];
    }

    _updateTermsForSelectedBatch();
  }

  void _updateTermsForSelectedBatch() {
    final batch = _scheduleBatchController.text.trim();
    final batchNode = _treeNodes.firstWhere(
      (n) => (n['title'] ?? '').toString().trim() == batch,
      orElse: () => <String, dynamic>{},
    );

    List<String> terms = [];
    if (batchNode.isNotEmpty && batchNode['id'] != null) {
      final batchId = batchNode['id'];
      // الفصول التابعة لهذه الدفعة في الشجرة
      terms = _treeNodes
          .where((n) => n['parent_id'] == batchId)
          .map((n) => (n['title'] ?? '').toString().trim())
          .where((t) => t.isNotEmpty)
          .toSet()
          .toList();
    }

    // إذا لم توجد فصول مباشرة تحت هذه الدفعة، نأخذ كل الفصول الموجودة في الشجرة
    if (terms.isEmpty) {
      terms = _treeNodes
          .where((n) => (n['title'] ?? '').toString().contains('الفصل'))
          .map((n) => (n['title'] ?? '').toString().trim())
          .where((t) => t.isNotEmpty)
          .toSet()
          .toList();
    }

    _termsOptions = terms;
    if (_termsOptions.isNotEmpty) {
      if (!_termsOptions.contains(_scheduleTermController.text)) {
        _scheduleTermController.text = _termsOptions.first;
      }
    } else {
      _scheduleTermController.text = 'الفصل الأول';
      _termsOptions = ['الفصل الأول'];
    }
  }

  Future<void> _loadSchedulesData() async {
    if (selectedSubService == null) return;
    final type = _mapSubServiceToScheduleType(selectedSubService!);
    setState(() => _isLoadingSchedules = true);

    try {
      final res = await AdminSupabase.client
          .from('schedules')
          .select()
          .eq('type', type)
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _schedulesList = List<Map<String, dynamic>>.from(res as List);
          _isLoadingSchedules = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingSchedules = false);
    }
  }

  Future<void> _pickScheduleFile() async {
    try {
      final res = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg'],
        withData: true,
      );

      if (res != null && res.files.isNotEmpty) {
        final file = res.files.first;
        final bytes = file.bytes;
        if (bytes != null) {
          final ext = (file.extension ?? 'pdf').toLowerCase();
          final isPdf = ext == 'pdf';
          final mime = isPdf ? 'application/pdf' : 'image/$ext';
          final base64String = 'data:$mime;base64,${base64Encode(bytes)}';

          setState(() {
            _selectedScheduleFileBytes = bytes;
            _selectedScheduleFileName = file.name;
            _selectedScheduleFileUrl = base64String;
            _isPdfSchedule = isPdf;
            _scheduleUrlController.text = file.name;
          });
          _showNotification('تم اختيار الملف: ${file.name}');
        }
      }
    } catch (e) {
      _showNotification('فشل اختيار الملف: $e', isError: true);
    }
  }

  void _editSchedule(Map<String, dynamic> item) {
    setState(() {
      _editingScheduleId = item['id'];
      _scheduleTitleController.text = item['title'] ?? '';

      final rawMeta = (item['academic_year'] ?? '').toString();
      final parts = rawMeta.split('|');
      if (parts.length >= 3) {
        _scheduleSpecialtyController.text = parts[0].trim();
        _scheduleBatchController.text = parts[1].trim();
        _scheduleTermController.text = parts[2].trim();
      } else if (parts.length == 2) {
        _scheduleSpecialtyController.text = parts[0].trim();
        _scheduleBatchController.text = parts[1].trim();
        _scheduleTermController.text = _termsOptions.isNotEmpty ? _termsOptions.first : '';
      } else if (parts.length == 1 && parts[0].trim().isNotEmpty) {
        _scheduleSpecialtyController.text = parts[0].trim();
        _scheduleBatchController.text = _batchesOptions.isNotEmpty ? _batchesOptions.first : '';
        _scheduleTermController.text = _termsOptions.isNotEmpty ? _termsOptions.first : '';
      } else {
        _scheduleSpecialtyController.text = _specialtiesOptions.isNotEmpty ? _specialtiesOptions.first : '';
        _scheduleBatchController.text = _batchesOptions.isNotEmpty ? _batchesOptions.first : '';
        _scheduleTermController.text = _termsOptions.isNotEmpty ? _termsOptions.first : '';
      }

      _selectedScheduleFileUrl = item['file_url'] ?? '';
      final rawUrl = (item['file_url'] ?? '').toString();
      _selectedScheduleFileName = rawUrl.startsWith('data:')
          ? 'ملف مرفوع مسبقاً (${item['is_pdf'] == true ? "PDF" : "صورة"})'
          : rawUrl.split('/').last;
      _scheduleUrlController.text = _selectedScheduleFileName ?? '';
      _isPdfSchedule = item['is_pdf'] ?? true;
      _selectedScheduleFileBytes = null;
    });
  }

  void _resetScheduleForm() {
    setState(() {
      _editingScheduleId = null;
      _scheduleTitleController.clear();
      _scheduleUrlController.clear();
      _scheduleSpecialtyController.text = _specialtiesOptions.isNotEmpty ? _specialtiesOptions.first : '';
      _updateBatchesAndTermsForSelectedSpecialty();
      _selectedScheduleFileBytes = null;
      _selectedScheduleFileName = null;
      _selectedScheduleFileUrl = null;
      _isPdfSchedule = true;
    });
  }

  Future<void> _saveScheduleData() async {
    final title = _scheduleTitleController.text.trim();
    final fileUrl = _selectedScheduleFileUrl ?? _scheduleUrlController.text.trim();

    if (title.isEmpty) {
      _showNotification('يرجى إدخال اسم أو عنوان الجدول', isError: true);
      return;
    }
    if (fileUrl.isEmpty) {
      _showNotification('يرجى رفع ملف الجدول من الجهاز (PDF أو صورة)', isError: true);
      return;
    }

    setState(() => _isSavingSchedule = true);
    final type = _mapSubServiceToScheduleType(selectedSubService ?? 'الجداول الدراسية');
    final specialty = _scheduleSpecialtyController.text.trim().isEmpty 
        ? (_specialtiesOptions.isNotEmpty ? _specialtiesOptions.first : '') 
        : _scheduleSpecialtyController.text.trim();
    final batch = _scheduleBatchController.text.trim().isEmpty 
        ? (_batchesOptions.isNotEmpty ? _batchesOptions.first : '') 
        : _scheduleBatchController.text.trim();
    final term = _scheduleTermController.text.trim().isEmpty 
        ? (_termsOptions.isNotEmpty ? _termsOptions.first : '') 
        : _scheduleTermController.text.trim();
    final scheduleMeta = '$specialty | $batch | $term';

    try {
      if (_editingScheduleId != null) {
        await AdminSupabase.client.from('schedules').update({
          'title': title,
          'type': type,
          'file_url': fileUrl,
          'is_pdf': _isPdfSchedule,
          'academic_year': scheduleMeta,
        }).eq('id', _editingScheduleId);

        _showNotification('تم تحديث بيانات الجدول بنجاح!');
      } else {
        await AdminSupabase.client.from('schedules').insert({
          'title': title,
          'type': type,
          'file_url': fileUrl,
          'is_pdf': _isPdfSchedule,
          'academic_year': scheduleMeta,
        });

        try {
          final notifTitle = type == 'study'
              ? 'جدول دراسي جديد: $title'
              : (type == 'midterm' ? 'جدول امتحانات نصفية: $title' : 'جدول امتحانات نهائية: $title');
          await AdminSupabase.client.from('notifications').insert({
            'academic_id': null,
            'title': notifTitle,
            'body': 'تم اعتماد ونشر جدول ($title) - $specialty ($batch - $term).',
            'notification_type': 'schedule',
            'route_name': 'schedules',
            'is_read': false,
          });
          FcmSenderService.sendToTopic(
            topic: 'all_students',
            title: notifTitle,
            body: 'تم اعتماد ونشر جدول ($title) - $specialty ($batch - $term).',
            routeName: 'schedules',
          );
        } catch (_) {}

        _showNotification('تم رفع واعتماد الجدول ونشره للطلاب بنجاح!');
      }

      _resetScheduleForm();
      _loadSchedulesData();
    } catch (e) {
      _showNotification('فشل حفظ الجدول: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isSavingSchedule = false);
    }
  }

  Future<void> _deleteSchedule(dynamic id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف الجدول', textDirection: TextDirection.rtl, style: TextStyle(color: primaryNavy, fontWeight: FontWeight.bold)),
        content: const Text('هل أنت متأكد من رغبتك في حذف هذا الجدول من التطبيق نهائياً؟', textDirection: TextDirection.rtl),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('حذف نهائي', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await AdminSupabase.client.from('schedules').delete().eq('id', id);
      _showNotification('تم حذف الجدول بنجاح');
      if (_editingScheduleId == id) {
        _resetScheduleForm();
      }
      _loadSchedulesData();
    } catch (e) {
      _showNotification('فشل الحذف: $e', isError: true);
    }
  }

  // --- 3. التعامل مع الكادر الأكاديمي ---
  Future<void> _loadStaffData() async {
    setState(() => _isLoadingStaff = true);
    try {
      final res = await AdminSupabase.client
          .from('academic_staff')
          .select()
          .order('display_order', ascending: true);

      if (mounted) {
        setState(() {
          _staffList = List<Map<String, dynamic>>.from(res as List);
          _isLoadingStaff = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingStaff = false);
    }
  }

  Future<void> _saveStaffData() async {
    final name = _staffNameController.text.trim();
    final spec = _staffSpecialtyController.text.trim();
    if (name.isEmpty || spec.isEmpty) {
      _showNotification('يرجى كتابة اسم الدكتور والتخصص على الأقل', isError: true);
      return;
    }

    try {
      await AdminSupabase.client.from('academic_staff').insert({
        'name': name,
        'specialty': spec,
        'experience_years': _staffExpController.text.trim().isEmpty ? '5 سنوات خبرة' : _staffExpController.text.trim(),
        'bio': _staffBioController.text.trim(),
        'photo_url': _staffPhotoController.text.trim().isEmpty ? 'assets/images/doctor_1.png' : _staffPhotoController.text.trim(),
        'display_order': _staffList.length + 1,
      });

      _staffNameController.clear();
      _staffSpecialtyController.clear();
      _staffExpController.clear();
      _staffBioController.clear();
      _staffPhotoController.clear();
      _showNotification('تمت إضافة عضو الكادر التدريسي بنجاح');
      _loadStaffData();
    } catch (e) {
      _showNotification('فشل الحفظ: $e', isError: true);
    }
  }

  Future<void> _deleteStaff(dynamic id) async {
    try {
      await AdminSupabase.client.from('academic_staff').delete().eq('id', id);
      _showNotification('تم حذف عضو الكادر بنجاح');
      _loadStaffData();
    } catch (e) {
      _showNotification('فشل الحذف: $e', isError: true);
    }
  }

  // --- 4. التعامل مع التخصصات الأكاديمية ---
  Future<void> _loadSpecialtiesData() async {
    setState(() => _isLoadingSpecs = true);
    try {
      final res = await AdminSupabase.client
          .from('specialties')
          .select()
          .order('display_order', ascending: true);

      if (mounted) {
        setState(() {
          _specList = List<Map<String, dynamic>>.from(res as List);
          _isLoadingSpecs = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingSpecs = false);
    }
  }

  Future<void> _saveSpecialtyData() async {
    final title = _specTitleController.text.trim();
    if (title.isEmpty) {
      _showNotification('يرجى كتابة اسم التخصص', isError: true);
      return;
    }

    try {
      await AdminSupabase.client.from('specialties').insert({
        'title': title,
        'degree_type': _specDegreeController.text.trim(),
        'location': _specLocationController.text.trim(),
        'image_url': _specImageController.text.trim().isEmpty ? 'assets/images/specialty_1.png' : _specImageController.text.trim(),
        'visits_count': 100,
        'display_order': _specList.length + 1,
      });

      _specTitleController.clear();
      _showNotification('تمت إضافة التخصص الأكاديمي بنجاح');
      _loadSpecialtiesData();
    } catch (e) {
      _showNotification('فشل الحفظ: $e', isError: true);
    }
  }

  Future<void> _deleteSpecialty(dynamic id) async {
    try {
      await AdminSupabase.client.from('specialties').delete().eq('id', id);
      _showNotification('تم حذف التخصص بنجاح');
      _loadSpecialtiesData();
    } catch (e) {
      _showNotification('فشل الحذف: $e', isError: true);
    }
  }

  // --- 5. التعامل مع المالية ---
  Future<void> _loadFinanceData() async {
    setState(() => _isLoadingFin = true);
    try {
      final res = await AdminSupabase.client
          .from('finance_notifications')
          .select()
          .order('created_at', ascending: false)
          .limit(20);

      if (mounted) {
        setState(() {
          _finList = List<Map<String, dynamic>>.from(res as List);
          _isLoadingFin = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingFin = false);
    }
  }

  Future<void> _saveFinanceData() async {
    final title = _finTitleController.text.trim();
    final details = _finDetailsController.text.trim();
    if (title.isEmpty || details.isEmpty) {
      _showNotification('يرجى كتابة عنوان الإشعار وتفاصيل المطالبة', isError: true);
      return;
    }

    final acadId = _finAcademicIdController.text.trim();
    final amount = double.tryParse(_finAmountController.text.trim()) ?? 0.0;

    try {
      await AdminSupabase.client.from('finance_notifications').insert({
        'academic_id': acadId.isEmpty ? null : acadId,
        'title': title,
        'details': details,
        'amount': amount,
        'date_str': DateTime.now().toString().substring(0, 10),
      });

      _finTitleController.clear();
      _finDetailsController.clear();
      _finAmountController.clear();

      try {
        await AdminSupabase.client.from('notifications').insert({
          'academic_id': acadId.isEmpty ? null : acadId,
          'title': 'إشعار مالي: $title',
          'body': '$details${amount > 0 ? " (المبلغ المطلوب: $amount ر.ي)" : ""}',
          'notification_type': 'finance',
          'route_name': 'finance',
          'is_read': false,
        });

        FcmSenderService.sendToTopic(
          topic: acadId.isEmpty ? 'all_students' : 'student_$acadId',
          title: 'إشعار مالي: $title',
          body: '$details${amount > 0 ? " (المبلغ المطلوب: $amount ر.ي)" : ""}',
          routeName: 'finance',
        );
      } catch (notifErr) {
        debugPrint('Finance notification insert failed: $notifErr');
      }

      _showNotification('تم إرسال الإشعار المالي بنجاح وحفظه في حساب الطالب!');
      _loadFinanceData();
    } catch (e) {
      _showNotification('فشل الإرسال: $e', isError: true);
    }
  }

  // --- 5.5 إدارة أرقام الجلوس والقاعات الامتحانية ---
  Future<void> _loadSeatingData() async {
    setState(() => _isLoadingSeating = true);
    try {
      final res = await AdminSupabase.client
          .from('seating_numbers')
          .select('*, students(full_name, specialty, level)')
          .order('updated_at', ascending: false);

      if (mounted) {
        setState(() {
          _seatingList = List<Map<String, dynamic>>.from(res as List);
          _isLoadingSeating = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading seating numbers: $e');
      if (mounted) setState(() => _isLoadingSeating = false);
    }
  }

  Future<void> _lookupStudentName(String id) async {
    final cleanId = id.trim();
    if (cleanId.length < 4) {
      if (_detectedStudentInfo != null) setState(() => _detectedStudentInfo = null);
      return;
    }
    try {
      final res = await AdminSupabase.client
          .from('students')
          .select('full_name, specialty, level')
          .eq('academic_id', cleanId)
          .maybeSingle();

      if (mounted) {
        setState(() {
          if (res != null) {
            _detectedStudentInfo = '${res['full_name']} | ${res['specialty']} (${res['level'] ?? ''})';
          } else {
            _detectedStudentInfo = 'تنبيه: لا يوجد طالب مسجل بهذا الرقم في النظام';
          }
        });
      }
    } catch (_) {}
  }

  Future<void> _saveSeatingNumber() async {
    final acadId = _seatingAcademicIdController.text.trim();
    final seatNo = _seatingNumberController.text.trim();
    final hall = _seatingHallController.text.trim().isEmpty ? 'القاعة الكبرى' : _seatingHallController.text.trim();
    final term = _seatingTermController.text.trim().isEmpty ? 'الفصل الدراسي الأول 2024/2025' : _seatingTermController.text.trim();

    if (acadId.isEmpty || seatNo.isEmpty) {
      _showNotification('يرجى إدخال الرقم الأكاديمي ورقم الجلوس', isError: true);
      return;
    }

    setState(() => _isSavingSeating = true);
    try {
      final studentCheck = await AdminSupabase.client
          .from('students')
          .select('full_name, specialty')
          .eq('academic_id', acadId)
          .maybeSingle();

      if (studentCheck == null) {
        _showNotification('تنبيه: الطالب برقم ($acadId) غير موجود في سجل الطلاب، يرجى التأكد من الرقم', isError: true);
        setState(() => _isSavingSeating = false);
        return;
      }

      await AdminSupabase.client.from('seating_numbers').upsert({
        'academic_id': acadId,
        'seating_number': seatNo,
        'hall': hall,
        'term': term,
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'academic_id');

      try {
        await AdminSupabase.client.from('notifications').insert({
          'academic_id': acadId,
          'title': 'اعتماد رقم الجلوس الامتحاني',
          'body': 'تم تحديد رقم جلوسك ($seatNo) في ($hall) للفصل ($term).',
          'notification_type': 'general',
          'route_name': 'control',
          'is_read': false,
        });

        FcmSenderService.sendToTopic(
          topic: 'student_$acadId',
          title: 'اعتماد رقم الجلوس الامتحاني',
          body: 'تم تحديد رقم جلوسك ($seatNo) في ($hall) للفصل ($term).',
          routeName: 'control',
        );
      } catch (_) {}

      _showNotification('تم اعتماد وحفظ رقم الجلوس للطالب ($acadId) بنجاح!');
      _resetSeatingForm();
      _loadSeatingData();
    } catch (e) {
      _showNotification('فشل الحفظ: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isSavingSeating = false);
    }
  }

  void _editSeating(Map<String, dynamic> item) {
    setState(() {
      _editingSeatingAcademicId = item['academic_id'];
      _seatingAcademicIdController.text = item['academic_id'] ?? '';
      _seatingNumberController.text = item['seating_number']?.toString() ?? '';
      _seatingHallController.text = item['hall'] ?? '';
      _seatingTermController.text = item['term'] ?? '';
      final studentObj = item['students'] is Map ? item['students'] : null;
      if (studentObj != null) {
        _detectedStudentInfo = '${studentObj['full_name']} | ${studentObj['specialty']}';
      }
    });
  }

  void _resetSeatingForm() {
    setState(() {
      _editingSeatingAcademicId = null;
      _seatingAcademicIdController.clear();
      _seatingNumberController.clear();
      _seatingHallController.text = 'القاعة الكبرى';
      _seatingTermController.text = 'الفصل الدراسي الأول 2024/2025';
      _detectedStudentInfo = null;
    });
  }

  Future<void> _deleteSeatingNumber(String academicId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف رقم الجلوس', textDirection: TextDirection.rtl, style: TextStyle(color: primaryNavy, fontWeight: FontWeight.bold)),
        content: Text('هل أنت متأكد من حذف رقم الجلوس للطالب ($academicId)؟', textDirection: TextDirection.rtl),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('حذف', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await AdminSupabase.client.from('seating_numbers').delete().eq('academic_id', academicId);
      _showNotification('تم حذف رقم الجلوس للطالب ($academicId) بنجاح');
      if (_editingSeatingAcademicId == academicId) {
        _resetSeatingForm();
      }
      _loadSeatingData();
    } catch (e) {
      _showNotification('فشل الحذف: $e', isError: true);
    }
  }

  String _cellToString(dynamic val) {
    if (val == null) return '';
    if (val is xl.TextCellValue) return val.value.text?.trim() ?? val.value.toString().trim();
    if (val is xl.IntCellValue) return val.value.toString().trim();
    if (val is xl.DoubleCellValue) return val.value.toString().trim();
    if (val is xl.DateCellValue) return val.year.toString();
    final str = val.toString().trim();
    final match = RegExp(r'CellValue\((.*)\)').firstMatch(str);
    if (match != null) return match.group(1)?.trim() ?? str;
    return str;
  }

  // --- 6. استيراد الإكسل للكنترول والنتائج ---
  Future<void> _importControlExcel() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
        withData: true,
      );

      if (result == null || result.files.isEmpty || result.files.first.bytes == null) return;

      final bytes = result.files.first.bytes!;
      final excel = xl.Excel.decodeBytes(bytes);
      final sheetName = excel.tables.keys.first;
      final table = excel.tables[sheetName];

      if (table == null || table.rows.length <= 1) {
        _showNotification('الملف فارغ أو لا يحتوي على صفوف بيانات', isError: true);
        return;
      }

      int count = 0;
      if (selectedSubService == 'أرقام الجلوس') {
        for (int i = 1; i < table.rows.length; i++) {
          final row = table.rows[i];
          final acadId = _cellToString(row[0]?.value);
          final seatNo = row.length > 1 ? _cellToString(row[1]?.value) : '';
          final hall = row.length > 2 ? _cellToString(row[2]?.value) : 'القاعة الكبرى';
          final term = row.length > 3 ? _cellToString(row[3]?.value) : 'الفصل الأول';

          if (acadId.isNotEmpty && seatNo.isNotEmpty) {
            await AdminSupabase.client.from('seating_numbers').upsert({
              'academic_id': acadId,
              'seating_number': seatNo,
              'hall': hall,
              'term': term,
              'updated_at': DateTime.now().toIso8601String(),
            }, onConflict: 'academic_id');
            count++;
          }
        }
        if (count > 0) {
          try {
            await AdminSupabase.client.from('notifications').insert({
              'academic_id': null,
              'title': 'صدور أرقام الجلوس والقاعات الامتحانية',
              'body': 'تم نشر واعتماد أرقام الجلوس وتوزيع اللجان الامتحانية لجميع الطلاب.',
              'notification_type': 'general',
              'route_name': 'control',
              'is_read': false,
            });
            FcmSenderService.sendToTopic(
              topic: 'all_students',
              title: 'صدور أرقام الجلوس والقاعات الامتحانية',
              body: 'تم نشر واعتماد أرقام الجلوس وتوزيع اللجان الامتحانية لجميع الطلاب.',
              routeName: 'control',
            );
          } catch (_) {}
        }
        _showNotification('تم استيراد ($count) رقم جلوس بنجاح وتحديث بيانات الطلاب!');
        _loadSeatingData();
      } else if (selectedSubService == 'النتائج') {
        int headerRowIndex = -1;
        for (int r = 0; r < table.rows.length && r < 10; r++) {
          final rowTexts = table.rows[r].map((c) => _cellToString(c?.value)).toList();
          if (rowTexts.any((txt) => txt.contains('الرقم الأكاديمي') || txt.contains('رقم القيد') || txt.contains('الأكاديمي'))) {
            headerRowIndex = r;
            break;
          }
        }

        if (headerRowIndex == -1) {
          headerRowIndex = table.rows.length > 1 ? 0 : -1;
        }

        if (headerRowIndex != -1) {
          final headerRow = table.rows[headerRowIndex];
          int idCol = -1;
          int nameCol = -1;
          int totalCol = -1;
          int gpaCol = -1;
          int gradeCol = -1;
          final Map<int, String> subjectCols = {};

          for (int c = 0; c < headerRow.length; c++) {
            final colName = _cellToString(headerRow[c]?.value);
            if (colName.isEmpty) continue;

            if (colName.contains('الرقم الأكاديمي') || colName.contains('رقم القيد')) {
              idCol = c;
            } else if (colName.contains('اسم') || colName.contains('اسـم')) {
              nameCol = c;
            } else if (colName.contains('المجم') || colName.contains('المجموع')) {
              totalCol = c;
            } else if (colName.contains('المعدل') || colName.contains('المعـ')) {
              gpaCol = c;
            } else if (colName.contains('التقدير') || colName.contains('التقـ')) {
              gradeCol = c;
            } else if (colName.contains('مسلسل') || colName.contains('مسلسـ') || colName == 'م') {
              // مسلسل نتجاهله
            } else {
              subjectCols[c] = colName;
            }
          }

          String detectedTermName = 'نتيجة الفصل الدراسي الحالي';
          if (headerRowIndex > 0) {
            for (var cell in table.rows[0]) {
              final val = _cellToString(cell?.value);
              if (val.contains('الفصل') || val.contains('نصف') || val.contains('المستوى') || val.contains('الدور')) {
                detectedTermName = val;
                break;
              }
            }
          }

          for (int r = headerRowIndex + 1; r < table.rows.length; r++) {
            final row = table.rows[r];
            final String acadId = idCol != -1 && idCol < row.length ? _cellToString(row[idCol]?.value) : (row.isNotEmpty ? _cellToString(row[0]?.value) : '');
            if (acadId.isEmpty || acadId.length < 5) continue;

            final String studentName = nameCol != -1 && nameCol < row.length ? _cellToString(row[nameCol]?.value) : '';
            final double total = totalCol != -1 && totalCol < row.length ? (double.tryParse(_cellToString(row[totalCol]?.value)) ?? 0.0) : 0.0;
            final double gpa = gpaCol != -1 && gpaCol < row.length ? (double.tryParse(_cellToString(row[gpaCol]?.value)) ?? 0.0) : 0.0;
            final String grade = gradeCol != -1 && gradeCol < row.length ? _cellToString(row[gradeCol]?.value) : 'ناجح';

            final Map<String, double> studentSubjects = {};
            subjectCols.forEach((colIdx, subName) {
              if (colIdx < row.length) {
                final mark = double.tryParse(_cellToString(row[colIdx]?.value)) ?? 0.0;
                studentSubjects[subName] = mark;
              }
            });

            // الحفاظ التام على بيانات الطالب وتخصصه ورفعته كما هي في الشجرة الأكاديمية دون تغيير
            try {
              final existingStudent = await AdminSupabase.client
                  .from('students')
                  .select('academic_id')
                  .eq('academic_id', acadId)
                  .maybeSingle();
              if (existingStudent == null) {
                await AdminSupabase.client.from('students').insert({
                  'academic_id': acadId,
                  'full_name': studentName.isNotEmpty ? studentName : 'طالب أكاديمي',
                  'password': 'password123',
                  'email': 'student_$acadId@alghad.edu.ye',
                });
              }
            } catch (_) {}

            List<Map<String, dynamic>> existingTerms = [];
            try {
              final prev = await AdminSupabase.client
                  .from('student_results')
                  .select('subjects')
                  .eq('academic_id', acadId)
                  .maybeSingle();
              if (prev != null && prev['subjects'] is Map) {
                final prevSubs = prev['subjects'] as Map<String, dynamic>;
                if (prevSubs['terms'] is List) {
                  existingTerms = List<Map<String, dynamic>>.from(prevSubs['terms']);
                }
              }
            } catch (_) {}

            existingTerms.removeWhere((t) => t['term_name'] == detectedTermName);
            existingTerms.insert(0, {
              'term_name': detectedTermName,
              'academic_year': DateTime.now().year.toString(),
              'subjects': studentSubjects,
              'total_marks': total,
              'gpa': gpa,
              'grade': grade.isNotEmpty ? grade : 'ناجح',
            });

            try {
              await AdminSupabase.client.from('student_results').upsert({
                'academic_id': acadId,
                'subjects': {
                  'terms': existingTerms,
                  ...studentSubjects,
                },
                'total_marks': total,
                'gpa': gpa,
                'grade': grade.isNotEmpty ? grade : 'ناجح',
                'updated_at': DateTime.now().toIso8601String(),
              }, onConflict: 'academic_id');
              count++;
            } catch (err) {
              debugPrint('Error inserting student_results for $acadId: $err');
            }

            try {
              await AdminSupabase.client.from('notifications').insert({
                'academic_id': acadId,
                'title': 'إعلان نتيجتك الأكاديمية: $grade 🎓',
                'body': 'عزيزي الطالب${studentName.isNotEmpty ? " $studentName" : ""}، تم اعتماد نتيجتك بمعدل $gpa% ومجموع $total. يمكنك مراجعة كشف درجات المواد الآن.',
                'notification_type': 'result',
                'route_name': 'results',
                'is_read': false,
              });

              FcmSenderService.sendToTopic(
                topic: 'student_$acadId',
                title: 'إعلان نتيجتك الأكاديمية: $grade 🎓',
                body: 'عزيزي الطالب${studentName.isNotEmpty ? " $studentName" : ""}، تم اعتماد نتيجتك بمعدل $gpa% ومجموع $total. يمكنك مراجعة كشف درجات المواد الآن.',
                routeName: 'results',
              );
            } catch (_) {}
          }
        }
        _showNotification('تم استيراد نتائج ($count) طالب بنجاح وحفظها في قاعدة البيانات!');
        _loadResultsControlData();
      } else if (selectedSubService == 'أوائل الطلاب') {
        for (int i = 1; i < table.rows.length; i++) {
          final row = table.rows[i];
          final rank = row.isNotEmpty ? int.tryParse(row[0]?.value?.toString() ?? '1') ?? 1 : 1;
          final sName = row.length > 1 ? row[1]?.value?.toString().trim() ?? '' : '';
          final spec = row.length > 2 ? row[2]?.value?.toString().trim() ?? '' : '';
          final gpa = row.length > 3 ? double.tryParse(row[3]?.value?.toString() ?? '0') ?? 0 : 0;
          final batch = row.length > 4 ? row[4]?.value?.toString().trim() ?? '' : 'دفعة 2024';

          if (sName.isNotEmpty) {
            await AdminSupabase.client.from('top_students').insert({
              'rank': rank,
              'student_name': sName,
              'specialty': spec,
              'gpa': gpa,
              'batch': batch,
            });
            count++;
          }
        }
        _showNotification('تم استيراد قائمة ($count) من أوائل الطلاب بنجاح!');
      }
    } catch (e) {
      _showNotification('فشل استيراد الإكسل: $e', isError: true);
    }
  }

  void _onSubServiceClicked(String mainTitle, String subTitle) {
    setState(() {
      selectedSubService = subTitle;
      currentPath = 'الخدمات > $mainTitle > $subTitle';
    });
    widget.onServiceTap(currentPath);

    // تحميل البيانات المربوطة فوراً
    if (subTitle.contains('الجداول') || subTitle.contains('جداول الامتحانات')) {
      _loadAcademicTreeOptions();
      _loadSchedulesData();
    } else if (subTitle == 'الكادر الأكاديمي والتدريس') {
      _loadStaffData();
    } else if (subTitle == 'التخصصات الأكاديمية') {
      _loadSpecialtiesData();
    } else if (subTitle == 'الإشعارات المالية وكشوفات الحساب') {
      _loadFinanceData();
    } else if (subTitle == 'أرقام الجلوس') {
      _loadSeatingData();
    } else if (subTitle == 'النتائج') {
      _loadResultsControlData();
    } else {
      _loadInstructionData(subTitle);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Column(
        children: [
          // شريط الأقسام الأفقية العلوية
          Container(
            color: const Color(0xFFC7B198),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: servicesData.map((service) {
                  final bool isOpen = openServiceTitle == service['title'];
                  return Padding(
                    padding: const EdgeInsets.only(left: 12),
                    child: ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          openServiceTitle = isOpen ? null : service['title'];
                        });
                      },
                      icon: Icon(service['icon'], size: 18, color: Colors.white),
                      label: Row(
                        children: [
                          Text(service['title'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                          const SizedBox(width: 4),
                          Icon(isOpen ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, size: 18, color: Colors.white),
                        ],
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isOpen ? primaryNavy : const Color(0xFF8C7A6B),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // القائمة المنسدلة للخدمات الفرعية
          if (openServiceTitle != null)
            Container(
              width: double.infinity,
              color: dropDownBg,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                children: (servicesData.firstWhere((s) => s['title'] == openServiceTitle)['items'] as List<String>).map((item) {
                  final isSelected = selectedSubService == item;
                  return InkWell(
                    onTap: () => _onSubServiceClicked(openServiceTitle!, item),
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? accentGold : Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: isSelected ? accentGold : Colors.grey.shade400),
                      ),
                      child: Text(
                        item,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                          color: isSelected ? Colors.white : primaryNavy,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

          // مساحة المحرر الديناميكي
          Expanded(
            child: Container(
              width: double.infinity,
              color: const Color(0xFFF4F6F8),
              child: _buildEditorPanel(),
            ),
          ),

          // شريط المسار السفلي
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
            color: const Color(0xFFDCDCDC),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.location_on_outlined, size: 18, color: primaryNavy),
                const SizedBox(width: 8),
                Text(
                  'المسار: $currentPath',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: primaryNavy),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditorPanel() {
    if (selectedSubService == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.dashboard_customize_outlined, size: 80, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'الرجاء اختيار خدمة فرعية من الأعلى لإدارتها وحفظ بياناتها',
              style: TextStyle(fontSize: 18, color: Colors.grey, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
    }

    if (selectedSubService == 'التسجيل أونلاين') {
      return _buildMessageOnly('هذه الخدمة مرتبطة بنموذج استمارة الطالب وترسل بياناتها مباشرة إلى رقم الواتساب المخصص للكلية (967776166321).');
    }

    if (selectedSubService!.contains('الجداول الدراسية') || selectedSubService!.contains('جداول الامتحانات')) {
      return _buildPdfUploadEditor();
    }

    if (selectedSubService == 'أرقام الجلوس') {
      return _buildSeatingNumbersEditor();
    }

    if (selectedSubService == 'النتائج') {
      return _buildResultsControlEditor();
    }

    if (selectedSubService == 'أوائل الطلاب') {
      return _buildExcelUploadEditor(title: 'إدارة واستيراد: $selectedSubService');
    }

    if (selectedSubService == 'الكادر الأكاديمي والتدريس') {
      return _buildStaffEditor();
    }

    if (selectedSubService == 'التخصصات الأكاديمية') {
      return _buildSpecialtyEditor();
    }

    if (selectedSubService == 'الإشعارات المالية وكشوفات الحساب') {
      return _buildFinanceEditor();
    }

    bool hasUrl = selectedSubService == 'التسجيل عبر البوابة الإلكترونية لوزارة التربية';
    return _buildTextInstructionEditor(hasUrl: hasUrl);
  }

  // --- محرر التعليمات النصية ---
  Widget _buildTextInstructionEditor({bool hasUrl = false}) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('إدارة ونشر محتوى: $selectedSubService', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: primaryNavy)),
                ElevatedButton.icon(
                  onPressed: _isSavingInstruction ? null : _saveInstructionData,
                  icon: const Icon(Icons.cloud_upload_outlined, color: Colors.white, size: 20),
                  label: Text(_isSavingInstruction ? 'جاري الحفظ...' : 'حفظ ونشر في التطبيق', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14)),
                ),
              ],
            ),
            const Divider(height: 32),
            TextField(
              controller: _instructionTitleController,
              textDirection: TextDirection.rtl,
              decoration: const InputDecoration(labelText: 'العنوان الرئيسي للخدمة', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _instructionSubtitleController,
              textDirection: TextDirection.rtl,
              decoration: const InputDecoration(labelText: 'المقدمة أو العنوان الفرعي', border: OutlineInputBorder()),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            const Text('الخطوات والإرشادات (اكتب كل خطوة في سطر مستقل):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 8),
            TextField(
              controller: _instructionStepsController,
              textDirection: TextDirection.rtl,
              decoration: const InputDecoration(hintText: 'الخطوة الأولى...\nالخطوة الثانية...\nالخطوة الثالثة...', border: OutlineInputBorder()),
              maxLines: 6,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _instructionNoteController,
              textDirection: TextDirection.rtl,
              decoration: const InputDecoration(labelText: 'ملاحظة تحذيرية أو إرشادية (تظهر أسفل الخطوات)', border: OutlineInputBorder()),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _instructionUrlController,
              textDirection: TextDirection.ltr,
              decoration: const InputDecoration(
                labelText: 'رابط خارجي أو توجيهي للخدمة (اختياري)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.link),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- محرر الجداول الدراسية والامتحانات ---
  Widget _buildPdfUploadEditor() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.calendar_month_outlined, size: 28, color: primaryNavy),
                  const SizedBox(width: 10),
                  Text(
                    'إدارة ورفع: $selectedSubService',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: primaryNavy),
                  ),
                ],
              ),
              OutlinedButton.icon(
                onPressed: _loadSchedulesData,
                icon: const Icon(Icons.refresh, size: 18, color: primaryNavy),
                label: const Text('تحديث الجداول', style: TextStyle(color: primaryNavy, fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
              ),
            ],
          ),
          const Divider(height: 28),

          // بطاقة رفع وتعديل الجدول
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _editingScheduleId != null ? accentGold : Colors.grey.shade300,
                width: _editingScheduleId != null ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _editingScheduleId != null ? Icons.edit_note : Icons.cloud_upload_outlined,
                          color: _editingScheduleId != null ? accentGold : primaryNavy,
                          size: 22,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _editingScheduleId != null
                              ? 'تعديل بيانات الجدول المنشور:'
                              : 'رفع جدول جديد ونشره في التطبيق:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: _editingScheduleId != null ? accentGold : primaryNavy,
                          ),
                        ),
                      ],
                    ),
                    if (_editingScheduleId != null)
                      TextButton.icon(
                        onPressed: _resetScheduleForm,
                        icon: const Icon(Icons.close, size: 18, color: Colors.red),
                        label: const Text('إلغاء التعديل', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _scheduleTitleController,
                  textDirection: TextDirection.rtl,
                  decoration: InputDecoration(
                    labelText: 'اسم / عنوان الجدول *',
                    hintText: 'مثال: جدول الفصل الأول - قسم الصيدلة',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.title),
                    filled: _editingScheduleId != null,
                    fillColor: _editingScheduleId != null ? Colors.amber.shade50.withOpacity(0.3) : null,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    // 1. التخصص
                    Expanded(
                      flex: 3,
                      child: DropdownButtonFormField<String>(
                        value: _specialtiesOptions.contains(_scheduleSpecialtyController.text)
                            ? _scheduleSpecialtyController.text
                            : (_specialtiesOptions.isNotEmpty ? _specialtiesOptions.first : null),
                        decoration: InputDecoration(
                          labelText: 'التخصص الأكاديمي (من الشجرة) *',
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.account_tree_outlined),
                          suffixIcon: _isLoadingTree
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: Padding(
                                    padding: EdgeInsets.all(12),
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                                )
                              : null,
                        ),
                        items: (() {
                          final currentSpec = _scheduleSpecialtyController.text.trim();
                          final list = List<String>.from(_specialtiesOptions);
                          if (currentSpec.isNotEmpty && !list.contains(currentSpec)) {
                            list.insert(0, currentSpec);
                          }
                          return list
                              .map((spec) => DropdownMenuItem(
                                    value: spec,
                                    child: Text(spec, textDirection: TextDirection.rtl),
                                  ))
                              .toList();
                        })(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _scheduleSpecialtyController.text = val;
                              _updateBatchesAndTermsForSelectedSpecialty();
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    // 2. الدفعة
                    Expanded(
                      flex: 2,
                      child: DropdownButtonFormField<String>(
                        value: _batchesOptions.contains(_scheduleBatchController.text)
                            ? _scheduleBatchController.text
                            : (_batchesOptions.isNotEmpty ? _batchesOptions.first : null),
                        decoration: const InputDecoration(
                          labelText: 'الدفعة (من الشجرة) *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.groups_outlined),
                        ),
                        items: (() {
                          final currentBatch = _scheduleBatchController.text.trim();
                          final list = List<String>.from(_batchesOptions);
                          if (currentBatch.isNotEmpty && !list.contains(currentBatch)) {
                            list.insert(0, currentBatch);
                          }
                          return list
                              .map((b) => DropdownMenuItem(
                                    value: b,
                                    child: Text(b, textDirection: TextDirection.rtl),
                                  ))
                              .toList();
                        })(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _scheduleBatchController.text = val;
                              _updateTermsForSelectedBatch();
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    // 3. الفصل الدراسي
                    Expanded(
                      flex: 3,
                      child: DropdownButtonFormField<String>(
                        value: _termsOptions.contains(_scheduleTermController.text)
                            ? _scheduleTermController.text
                            : (_termsOptions.isNotEmpty ? _termsOptions.first : null),
                        decoration: const InputDecoration(
                          labelText: 'الفصل الدراسي (من الشجرة) *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.calendar_today_outlined),
                        ),
                        items: (() {
                          final currentTerm = _scheduleTermController.text.trim();
                          final list = List<String>.from(_termsOptions);
                          if (currentTerm.isNotEmpty && !list.contains(currentTerm)) {
                            list.insert(0, currentTerm);
                          }
                          return list
                              .map((t) => DropdownMenuItem(
                                    value: t,
                                    child: Text(t, textDirection: TextDirection.rtl),
                                  ))
                              .toList();
                        })(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _scheduleTermController.text = val);
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // قسم رفع الملف من الجهاز
                const Text(
                  'ملف الجدول (PDF أو صورة JPG/PNG):',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: primaryNavy),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FBFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _selectedScheduleFileName != null ? Colors.green.shade400 : Colors.blue.shade200,
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _isPdfSchedule ? Colors.red.shade50 : Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          _isPdfSchedule ? Icons.picture_as_pdf : Icons.image,
                          color: _isPdfSchedule ? Colors.red.shade700 : Colors.blue.shade700,
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _selectedScheduleFileName != null
                                  ? _selectedScheduleFileName!
                                  : 'لم يتم اختيار ملف بعد من جهاز الكمبيوتر',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: _selectedScheduleFileName != null ? primaryNavy : Colors.black54,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _selectedScheduleFileName != null
                                  ? (_selectedScheduleFileBytes != null
                                      ? 'الحجم: ${(_selectedScheduleFileBytes!.lengthInBytes / 1024).toStringAsFixed(1)} كيلوبايت - جاهز للرفع'
                                      : 'الملف الحالي محفوظ في التطبيق')
                                  : 'يمكنك رفع ملف PDF أو صورة معتمدة للجدول لتظهر في التطبيق فوراً.',
                              style: TextStyle(
                                fontSize: 12,
                                color: _selectedScheduleFileName != null ? Colors.green.shade700 : Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: _pickScheduleFile,
                        icon: const Icon(Icons.upload_file, color: Colors.white, size: 18),
                        label: Text(
                          _selectedScheduleFileName != null ? 'استبدال الملف من الجهاز' : 'اختيار ملف من الجهاز',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryNavy,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // زر الحفظ والنشر
                Align(
                  alignment: Alignment.centerLeft,
                  child: ElevatedButton.icon(
                    onPressed: _isSavingSchedule ? null : _saveScheduleData,
                    icon: Icon(
                      _editingScheduleId != null ? Icons.save : Icons.cloud_upload,
                      color: Colors.white,
                      size: 20,
                    ),
                    label: Text(
                      _isSavingSchedule
                          ? 'جاري المعالجة والحفظ...'
                          : (_editingScheduleId != null ? 'حفظ التعديلات على الجدول' : 'حفظ ونشر الجدول للطلاب'),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _editingScheduleId != null ? accentGold : Colors.green.shade700,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // سجل الجداول السابقة
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text(
                    'سجل الجداول المنشورة حالياً في التطبيق:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryNavy),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(color: primaryNavy, borderRadius: BorderRadius.circular(20)),
                    child: Text(
                      '${_schedulesList.length} جدول',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),

          if (_isLoadingSchedules)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_schedulesList.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: const Center(
                child: Column(
                  children: [
                    Icon(Icons.calendar_today_outlined, size: 50, color: Colors.grey),
                    SizedBox(height: 12),
                    Text(
                      'لا توجد جداول مرفوعة حالياً في هذا القسم.',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'قم برفع أول جدول من الحقول في الأعلى وسيظهر للطلاب فوراً.',
                      style: TextStyle(fontSize: 13, color: Colors.black54),
                    ),
                  ],
                ),
              ),
            )
          else
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2)),
                ],
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _schedulesList.length,
                separatorBuilder: (c, i) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final item = _schedulesList[index];
                  final isEditingThis = _editingScheduleId == item['id'];
                  final isPdf = item['is_pdf'] ?? true;

                  return Container(
                    color: isEditingThis ? accentGold.withOpacity(0.12) : null,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isPdf ? Colors.red.shade50 : Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            isPdf ? Icons.picture_as_pdf : Icons.image,
                            color: isPdf ? Colors.red.shade700 : Colors.blue.shade700,
                            size: 26,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item['title'] ?? '',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: primaryNavy),
                              ),
                              const SizedBox(height: 4),
                              Wrap(
                                spacing: 6,
                                runSpacing: 4,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  ...() {
                                    final rawMeta = (item['academic_year'] ?? '').toString();
                                    final metaParts = rawMeta.split('|').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
                                    if (metaParts.length >= 3) {
                                      return [
                                        _buildMetaBadge(Icons.school_outlined, metaParts[0], Colors.indigo),
                                        _buildMetaBadge(Icons.groups_outlined, metaParts[1], Colors.teal.shade800),
                                        _buildMetaBadge(Icons.calendar_today_outlined, metaParts[2], Colors.orange.shade900),
                                      ];
                                    } else if (metaParts.length == 2) {
                                      return [
                                        _buildMetaBadge(Icons.school_outlined, metaParts[0], Colors.indigo),
                                        _buildMetaBadge(Icons.groups_outlined, metaParts[1], Colors.teal.shade800),
                                      ];
                                    } else {
                                      return [
                                        _buildMetaBadge(Icons.calendar_today_outlined, rawMeta.isNotEmpty ? rawMeta : 'عام', Colors.blueGrey),
                                      ];
                                    }
                                  }(),
                                  if (item['created_at'] != null)
                                    Text(
                                      'نُشر: ${item['created_at'].toString().substring(0, 10)}',
                                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ElevatedButton.icon(
                              onPressed: () => _editSchedule(item),
                              icon: const Icon(Icons.edit, size: 15, color: Colors.white),
                              label: const Text('تعديل', style: TextStyle(color: Colors.white, fontSize: 12)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryNavy,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                minimumSize: Size.zero,
                              ),
                            ),
                            const SizedBox(width: 8),
                            OutlinedButton.icon(
                              onPressed: () => _deleteSchedule(item['id']),
                              icon: const Icon(Icons.delete_outline, size: 15, color: Colors.red),
                              label: const Text('حذف', style: TextStyle(color: Colors.red, fontSize: 12)),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Colors.red),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                minimumSize: Size.zero,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  // --- محرر الكادر التدريسي ---
  Widget _buildStaffEditor() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('إدارة الكادر الأكاديمي والتدريس', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: primaryNavy)),
              ElevatedButton.icon(
                onPressed: _saveStaffData,
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text('إضافة عضو جديد ونشره', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12)),
              ),
            ],
          ),
          const Divider(height: 32),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade300)),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(child: TextField(controller: _staffNameController, textDirection: TextDirection.rtl, decoration: const InputDecoration(labelText: 'اسم الدكتور / الأستاذ', border: OutlineInputBorder()))),
                    const SizedBox(width: 16),
                    Expanded(child: TextField(controller: _staffSpecialtyController, textDirection: TextDirection.rtl, decoration: const InputDecoration(labelText: 'التخصص العلمي', border: OutlineInputBorder()))),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: TextField(controller: _staffExpController, textDirection: TextDirection.rtl, decoration: const InputDecoration(labelText: 'سنوات الخبرة (مثال: 10 سنوات خبرة)', border: OutlineInputBorder()))),
                    const SizedBox(width: 16),
                    Expanded(child: TextField(controller: _staffPhotoController, textDirection: TextDirection.ltr, decoration: const InputDecoration(labelText: 'رابط الصورة (اختياري)', border: OutlineInputBorder()))),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(controller: _staffBioController, textDirection: TextDirection.rtl, decoration: const InputDecoration(labelText: 'نبذة عن الخبرة والتدريس', border: OutlineInputBorder()), maxLines: 2),
              ],
            ),
          ),
          const SizedBox(height: 32),
          const Text('الكادر المسجل حالياً في التطبيق:', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: primaryNavy)),
          const SizedBox(height: 12),
          if (_isLoadingStaff)
            const Center(child: CircularProgressIndicator())
          else if (_staffList.isEmpty)
            const Text('لا يوجد أعضاء كادر مسجلين حالياً.')
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _staffList.length,
              itemBuilder: (context, index) {
                final item = _staffList[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: const CircleAvatar(backgroundColor: accentGold, child: Icon(Icons.person, color: Colors.white)),
                    title: Text(item['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('${item['specialty'] ?? ''} - ${item['experience_years'] ?? ''}'),
                    trailing: IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _deleteStaff(item['id'])),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  // --- محرر التخصصات ---
  Widget _buildSpecialtyEditor() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('إدارة التخصصات الأكاديمية', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: primaryNavy)),
              ElevatedButton.icon(
                onPressed: _saveSpecialtyData,
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text('إضافة تخصص ونشره', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12)),
              ),
            ],
          ),
          const Divider(height: 32),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade300)),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(child: TextField(controller: _specTitleController, textDirection: TextDirection.rtl, decoration: const InputDecoration(labelText: 'اسم التخصص (مثال: صيدلة سريرية)', border: OutlineInputBorder()))),
                    const SizedBox(width: 16),
                    Expanded(child: TextField(controller: _specDegreeController, textDirection: TextDirection.rtl, decoration: const InputDecoration(labelText: 'الدرجة (بكالوريوس / دبلوم)', border: OutlineInputBorder()))),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: TextField(controller: _specLocationController, textDirection: TextDirection.rtl, decoration: const InputDecoration(labelText: 'المقر / المبنى', border: OutlineInputBorder()))),
                    const SizedBox(width: 16),
                    Expanded(child: TextField(controller: _specImageController, textDirection: TextDirection.ltr, decoration: const InputDecoration(labelText: 'رابط صورة التخصص', border: OutlineInputBorder()))),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          const Text('التخصصات المنشورة في التطبيق:', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: primaryNavy)),
          const SizedBox(height: 12),
          if (_isLoadingSpecs)
            const Center(child: CircularProgressIndicator())
          else if (_specList.isEmpty)
            const Text('لا توجد تخصصات مسجلة حالياً.')
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _specList.length,
              itemBuilder: (context, index) {
                final item = _specList[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: const Icon(Icons.school, color: primaryNavy),
                    title: Text(item['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('${item['degree_type'] ?? ''} - ${item['location'] ?? ''}'),
                    trailing: IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _deleteSpecialty(item['id'])),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  // --- 7. إدارة وكنترول حجب النتيجة ---
  Future<void> _loadResultsControlData() async {
    setState(() => _isLoadingResultsControl = true);
    try {
      final res = await AdminSupabase.client
          .from('student_results')
          .select('*, students(full_name, specialty, batch, semester)')
          .order('academic_id', ascending: true);

      _resultsList = List<Map<String, dynamic>>.from(res as List);
      _totalResultsCount = _resultsList.length;

      final latestRows = await AdminSupabase.client
          .from('student_results')
          .select('updated_at, subjects')
          .order('updated_at', ascending: false)
          .limit(1);

      if (latestRows.isNotEmpty) {
        final row = latestRows.first;
        final rawDate = row['updated_at']?.toString() ?? '';
        if (rawDate.isNotEmpty) {
          try {
            final dt = DateTime.parse(rawDate).toLocal();
            _latestResultUploadTime = '${dt.year}/${dt.month}/${dt.day} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
          } catch (_) {
            _latestResultUploadTime = rawDate;
          }
        }
        final subs = row['subjects'];
        if (subs is Map && subs['terms'] is List && (subs['terms'] as List).isNotEmpty) {
          _latestResultTermName = (subs['terms'] as List).first['term_name']?.toString() ?? 'الفصل الدراسي الأول';
        }
      }
    } catch (e) {
      debugPrint('Error loading results: $e');
    } finally {
      if (mounted) setState(() => _isLoadingResultsControl = false);
    }
  }

  // تصدير كشف النتائج إلى ملف Excel
  Future<void> _exportResultsToExcel() async {
    if (_resultsList.isEmpty) {
      _showNotification('لا توجد نتائج مسجلة لتصديرها حالياً', isError: true);
      return;
    }

    try {
      final excel = xl.Excel.createExcel();
      final sheetName = 'كشف النتائج الأكاديمية';
      excel.rename('Sheet1', sheetName);
      final sheet = excel[sheetName];
      sheet.isRTL = true;

      final headers = [
        'الرقم الأكاديمي',
        'اسم الطالب',
        'التخصص',
        'الدفعة',
        'الفصل الدراسي',
        'المجموع',
        'المعدل %',
        'التقدير',
        'تاريخ الرصد',
      ];

      final headerStyle = xl.CellStyle(
        bold: true,
        fontColorHex: xl.ExcelColor.white,
        backgroundColorHex: xl.ExcelColor.fromHexString('#0E1B4D'),
        horizontalAlign: xl.HorizontalAlign.Center,
        verticalAlign: xl.VerticalAlign.Center,
      );

      for (int c = 0; c < headers.length; c++) {
        final cell = sheet.cell(xl.CellIndex.indexByColumnRow(columnIndex: c, rowIndex: 0));
        cell.value = xl.TextCellValue(headers[c]);
        cell.cellStyle = headerStyle;
      }

      for (int i = 0; i < _resultsList.length; i++) {
        final item = _resultsList[i];
        final studentObj = item['students'] is Map ? item['students'] : null;
        final acadId = item['academic_id']?.toString() ?? '';
        final sName = studentObj?['full_name']?.toString() ?? item['student_name']?.toString() ?? 'طالب أكاديمي';
        final spec = studentObj?['specialty']?.toString() ?? item['specialty']?.toString() ?? '-';
        final batch = studentObj?['batch']?.toString() ?? item['batch']?.toString() ?? '-';
        final semester = studentObj?['semester']?.toString() ?? _latestResultTermName;
        final total = item['total_marks']?.toString() ?? '0';
        final gpa = item['gpa']?.toString() ?? '0';
        final grade = item['grade']?.toString() ?? 'ناجح';
        final updatedAt = item['updated_at']?.toString().split('T').first ?? '';

        final rowValues = [
          acadId,
          sName,
          spec,
          batch,
          semester,
          total,
          gpa,
          grade,
          updatedAt,
        ];

        for (int c = 0; c < rowValues.length; c++) {
          final cell = sheet.cell(xl.CellIndex.indexByColumnRow(columnIndex: c, rowIndex: i + 1));
          cell.value = xl.TextCellValue(rowValues[c]);
          cell.cellStyle = xl.CellStyle(
            horizontalAlign: xl.HorizontalAlign.Center,
            verticalAlign: xl.VerticalAlign.Center,
          );
        }
      }

      final fileBytes = excel.save();
      if (fileBytes != null) {
        final fileName = 'كشف_النتائج_الأكاديمية_${DateTime.now().year}.xlsx';
        await saveAndDownloadFile(fileBytes, fileName);
        _showNotification('تم تصدير كشف النتائج بنجاح: $fileName');
      }
    } catch (e) {
      _showNotification('فشل تصدير كشف النتائج: $e', isError: true);
    }
  }

  // نشر النتائج وبث إشعارات فورية سحابية للطلاب
  Future<void> _publishResultsWithNotifications() async {
    if (_resultsList.isEmpty) {
      _showNotification('لا توجد نتائج مسجلة لنشرها حالياً. يرجى رفع ملف النتائج أولاً.', isError: true);
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.campaign_rounded, color: primaryNavy, size: 26),
            SizedBox(width: 8),
            Text('نشر النتائج وبث الإشعارات للطلاب', style: TextStyle(fontWeight: FontWeight.bold, color: primaryNavy)),
          ],
        ),
        content: Text(
          'سيتم اعتماد ونشر النتائج وبث إشعارات فورية سحابية (FCM) إلى جميع الطلاب (${_resultsList.length} طالب) لتصلهم فوراً حتى لو كان التطبيق مغلقاً.\n\nهل ترغب بالمتابعة؟',
          style: const TextStyle(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.send, color: Colors.white, size: 18),
            label: const Text('نشر وبث الإشعارات الآن', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isPublishingResults = true);

    try {
      // 1. إدراج إشعار عام في قاعدة البيانات
      await AdminSupabase.client.from('notifications').insert({
        'title': 'إعلان النتائج الأكاديمية 🎓',
        'body': 'تم نشر واعتماد كشوف الدرجات والنتائج الأكاديمية لجميع الطلاب. تفضل بالاطلاع على نتيجتك ومعدلك التراكمي الآن.',
        'notification_type': 'result',
        'route_name': 'results',
        'is_read': false,
      });

      // 2. بث الإشعار السحابي العام لكافة الطلاب
      FcmSenderService.sendToTopic(
        topic: 'all_students',
        title: 'إعلان النتائج الأكاديمية 🎓',
        body: 'تم نشر واعتماد كشوف الدرجات والنتائج الأكاديمية لجميع الطلاب. تفضل بالاطلاع على نتيجتك ومعدلك التراكمي الآن.',
        routeName: 'results',
      );

      // 3. إرسال تنبيه شخصي لكل طالب في القائمة برقم قيده الأكاديمي
      for (final item in _resultsList) {
        final acadId = item['academic_id']?.toString() ?? '';
        final studentObj = item['students'] is Map ? item['students'] : null;
        final studentName = studentObj?['full_name']?.toString() ?? item['student_name']?.toString() ?? '';
        final grade = item['grade']?.toString() ?? 'ناجح';
        final gpa = item['gpa']?.toString() ?? '';

        if (acadId.isNotEmpty) {
          FcmSenderService.sendToTopic(
            topic: 'student_$acadId',
            title: 'إعلان نتيجتك الأكاديمية: $grade 🎓',
            body: 'عزيزي الطالب${studentName.isNotEmpty ? " $studentName" : ""}، تم اعتماد نتيجتك بمعدل $gpa% ($grade). تفضل بالاطلاع على كشف درجاتك الآن.',
            routeName: 'results',
          );
        }
      }

      _showNotification('تم نشر النتائج وبث الإشعارات السحابية بنجاح إلى جميع الطلاب (${_resultsList.length} طالب)!');
    } catch (e) {
      _showNotification('فشل نشر النتائج وبث الإشعارات: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isPublishingResults = false);
    }
  }

  // تعديل نتيجة طالب
  Future<void> _editStudentResultDialog(Map<String, dynamic> item) async {
    final acadId = item['academic_id']?.toString() ?? '';
    final studentObj = item['students'] is Map ? item['students'] : null;
    final studentName = studentObj?['full_name']?.toString() ?? item['student_name']?.toString() ?? 'طالب أكاديمي';

    final totalCtrl = TextEditingController(text: item['total_marks']?.toString() ?? '');
    final gpaCtrl = TextEditingController(text: item['gpa']?.toString() ?? '');
    String selectedGrade = item['grade']?.toString() ?? 'ممتاز';
    final List<String> gradeOptions = ['ممتاز', 'جيد جداً', 'جيد', 'مقبول', 'راسب'];
    if (!gradeOptions.contains(selectedGrade)) {
      gradeOptions.add(selectedGrade);
    }

    final rawSubs = item['subjects'];
    final Map<String, TextEditingController> subjectControllers = {};
    if (rawSubs is Map) {
      rawSubs.forEach((key, val) {
        if (key != 'terms' && key != 'is_result_hidden') {
          subjectControllers[key.toString()] = TextEditingController(text: val?.toString() ?? '');
        }
      });
    }

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.edit_note, color: accentGold, size: 28),
              const SizedBox(width: 8),
              Expanded(
                child: Text('تعديل نتيجة الطالب: $studentName ($acadId)',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: primaryNavy)),
              ),
            ],
          ),
          content: SizedBox(
            width: 520,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: totalCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'المجموع الكلي', border: OutlineInputBorder(), prefixIcon: Icon(Icons.calculate_outlined)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: gpaCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'المعدل التراكمي %', border: OutlineInputBorder(), prefixIcon: Icon(Icons.percent)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    value: selectedGrade,
                    decoration: const InputDecoration(labelText: 'التقدير العام', border: OutlineInputBorder(), prefixIcon: Icon(Icons.grade)),
                    items: gradeOptions.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                    onChanged: (v) {
                      if (v != null) setDlgState(() => selectedGrade = v);
                    },
                  ),
                  if (subjectControllers.isNotEmpty) ...[
                    const SizedBox(height: 18),
                    const Text('درجات المواد المرصودة:', style: TextStyle(fontWeight: FontWeight.bold, color: primaryNavy, fontSize: 14)),
                    const SizedBox(height: 10),
                    ...subjectControllers.entries.map((entry) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          children: [
                            Expanded(flex: 3, child: Text(entry.key, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
                            const SizedBox(width: 8),
                            Expanded(
                              flex: 2,
                              child: TextField(
                                controller: entry.value,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(isDense: true, border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10)),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('إلغاء', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(ctx, true),
              icon: const Icon(Icons.save, color: Colors.white, size: 18),
              label: const Text('حفظ التعديل وإرسال إشعار', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(backgroundColor: primaryNavy),
            ),
          ],
        ),
      ),
    );

    if (saved != true) return;

    try {
      final double newTotal = double.tryParse(totalCtrl.text.trim()) ?? 0.0;
      final double newGpa = double.tryParse(gpaCtrl.text.trim()) ?? 0.0;
      final Map<String, dynamic> updatedSubjects = Map<String, dynamic>.from(rawSubs is Map ? rawSubs : {});
      subjectControllers.forEach((subName, ctrl) {
        final val = double.tryParse(ctrl.text.trim()) ?? 0.0;
        updatedSubjects[subName] = val;
      });

      await AdminSupabase.client.from('student_results').update({
        'total_marks': newTotal,
        'gpa': newGpa,
        'grade': selectedGrade,
        'subjects': updatedSubjects,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('academic_id', acadId);

      // إرسال إشعار فوري للطالب بالنتيجة المحدثة
      FcmSenderService.sendToTopic(
        topic: 'student_$acadId',
        title: 'تحديث في نتيجتك الأكاديمية: $selectedGrade 🎓',
        body: 'تم تعديل كشف درجاتك ومعدلك ليصبح $newGpa% بمجموع $newTotal. يمكنك مراجعة النتيجة الآن.',
        routeName: 'results',
      );

      _showNotification('تم تعديل نتيجة الطالب ($studentName) وإرسال إشعار فوري بنجاح!');
      await _loadResultsControlData();
    } catch (e) {
      _showNotification('فشل تعديل النتيجة: $e', isError: true);
    }
  }

  // حذف نتيجة طالب
  Future<void> _deleteStudentResult(String academicId, String studentName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.delete_forever, color: Colors.red, size: 28),
            SizedBox(width: 8),
            Text('حذف نتيجة الطالب', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
          ],
        ),
        content: Text('هل أنت متأكد من حذف نتيجة الطالب:\n$studentName ($academicId) نهائياً من قاعدة البيانات؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('نعم، حذف النتيجة', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await AdminSupabase.client.from('student_results').delete().eq('academic_id', academicId);
      _showNotification('تم حذف نتيجة الطالب ($studentName) بنجاح');
      await _loadResultsControlData();
    } catch (e) {
      _showNotification('فشل حذف النتيجة: $e', isError: true);
    }
  }

  // الواجهة الرئيسية لخدمة النتائج وجدول الطلاب
  Widget _buildResultsControlEditor() {
    if (_isLoadingResultsControl) {
      return const Center(child: CircularProgressIndicator());
    }

    final query = _resultsSearchController.text.trim().toLowerCase();
    final displayList = _resultsList.where((item) {
      if (query.isEmpty) return true;
      final acadId = (item['academic_id'] ?? '').toString().toLowerCase();
      final grade = (item['grade'] ?? '').toString().toLowerCase();
      final studentObj = item['students'] is Map ? item['students'] : null;
      final name = (studentObj?['full_name'] ?? item['student_name'] ?? '').toString().toLowerCase();
      final specialty = (studentObj?['specialty'] ?? item['specialty'] ?? '').toString().toLowerCase();
      return acadId.contains(query) || name.contains(query) || specialty.contains(query) || grade.contains(query);
    }).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // شريط العنوان العلوي وأزرار العمليات الرئيسية
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: primaryNavy.withOpacity(0.08), borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.assessment_rounded, color: primaryNavy, size: 30),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('إدارة وكنترول كشوف نتائج الطلاب', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: primaryNavy)),
                        const SizedBox(height: 4),
                        Text('إجمالي الطلاب المرصودة نتائجهم: $_totalResultsCount طالب', style: const TextStyle(fontSize: 13, color: Colors.black54)),
                      ],
                    ),
                  ],
                ),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    // زر رفع ملف الإكسل
                    ElevatedButton.icon(
                      onPressed: () async {
                        await _importControlExcel();
                        _loadResultsControlData();
                      },
                      icon: const Icon(Icons.upload_file, color: Colors.white, size: 18),
                      label: const Text('رفع كشف النتائج (Excel)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade800, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14)),
                    ),
                    // زر تصدير الإكسل
                    ElevatedButton.icon(
                      onPressed: _exportResultsToExcel,
                      icon: const Icon(Icons.file_download_outlined, color: Colors.white, size: 18),
                      label: const Text('تصدير كشف النتائج', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey.shade800, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14)),
                    ),
                    // زر نشر النتائج وبث الإشعارات
                    ElevatedButton.icon(
                      onPressed: _isPublishingResults ? null : _publishResultsWithNotifications,
                      icon: _isPublishingResults
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.campaign_rounded, color: Colors.white, size: 20),
                      label: Text(_isPublishingResults ? 'جاري البث...' : 'نشر النتائج وبث الإشعارات',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(backgroundColor: accentGold, padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14)),
                    ),
                    // زر التحديث
                    OutlinedButton.icon(
                      onPressed: _loadResultsControlData,
                      icon: const Icon(Icons.refresh, size: 18, color: primaryNavy),
                      label: const Text('تحديث', style: TextStyle(color: primaryNavy, fontWeight: FontWeight.bold)),
                      style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // بطاقات إحصائية سريعة
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
                        child: Icon(Icons.people_alt_outlined, color: Colors.blue.shade800, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('إجمالي النتائج المرصودة', style: TextStyle(fontSize: 12, color: Colors.black54)),
                          const SizedBox(height: 4),
                          Text('$_totalResultsCount طالب', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryNavy)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: Colors.teal.shade50, borderRadius: BorderRadius.circular(8)),
                        child: Icon(Icons.calendar_today_outlined, color: Colors.teal.shade800, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('الفصل الدراسي المرصود', style: TextStyle(fontSize: 12, color: Colors.black54)),
                          const SizedBox(height: 4),
                          Text(_latestResultTermName.isEmpty ? 'الفصل الدراسي الأول' : _latestResultTermName,
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.teal)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: Colors.amber.shade50, borderRadius: BorderRadius.circular(8)),
                        child: Icon(Icons.access_time_outlined, color: Colors.amber.shade900, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('تاريخ آخر رصد أو رفع', style: TextStyle(fontSize: 12, color: Colors.black54)),
                          const SizedBox(height: 4),
                          Text(_latestResultUploadTime.isEmpty ? 'لم يتم الرصد بعد' : _latestResultUploadTime,
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // حقل البحث السريع
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              children: [
                const Icon(Icons.search, color: Colors.grey),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _resultsSearchController,
                    onChanged: (v) => setState(() {}),
                    decoration: const InputDecoration(
                      hintText: 'البحث برقم القيد الأكاديمي، أو اسم الطالب، أو التخصص...',
                      border: InputBorder.none,
                    ),
                  ),
                ),
                if (_resultsSearchController.text.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.clear, size: 18),
                    onPressed: () {
                      _resultsSearchController.clear();
                      setState(() {});
                    },
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // جدول الطلاب والنتائج في الجهة اليسرى / الرئيسية
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)],
            ),
            child: displayList.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(48),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.folder_off_outlined, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        const Text('لا توجد نتائج مطابقة أو لم يتم رفع أي نتائج بعد',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey)),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: () async {
                            await _importControlExcel();
                            _loadResultsControlData();
                          },
                          icon: const Icon(Icons.upload_file, color: Colors.white),
                          label: const Text('رفع ملف إكسل للنتائج الآن', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(backgroundColor: primaryNavy),
                        ),
                      ],
                    ),
                  )
                : ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        headingRowColor: MaterialStateProperty.all(primaryNavy),
                        headingTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                        dataRowHeight: 60,
                        columns: const [
                          DataColumn(label: Text('#')),
                          DataColumn(label: Text('الرقم الأكاديمي')),
                          DataColumn(label: Text('اسم الطالب')),
                          DataColumn(label: Text('التخصص')),
                          DataColumn(label: Text('الدفعة')),
                          DataColumn(label: Text('المجموع')),
                          DataColumn(label: Text('المعدل')),
                          DataColumn(label: Text('التقدير')),
                          DataColumn(label: Text('تاريخ الرصد')),
                          DataColumn(label: Text('الإجراءات')),
                        ],
                        rows: displayList.asMap().entries.map((entry) {
                          final idx = entry.key + 1;
                          final item = entry.value;
                          final acadId = item['academic_id']?.toString() ?? '';
                          final studentObj = item['students'] is Map ? item['students'] : null;
                          final sName = studentObj?['full_name']?.toString() ?? item['student_name']?.toString() ?? 'طالب أكاديمي';
                          final spec = studentObj?['specialty']?.toString() ?? item['specialty']?.toString() ?? '-';
                          final batch = studentObj?['batch']?.toString() ?? item['batch']?.toString() ?? '-';
                          final total = item['total_marks']?.toString() ?? '0';
                          final gpa = item['gpa']?.toString() ?? '0';
                          final grade = item['grade']?.toString() ?? 'ناجح';
                          final updatedAt = item['updated_at']?.toString().split('T').first ?? '';

                          Color gradeColor = Colors.teal;
                          if (grade.contains('ممتاز')) {
                            gradeColor = Colors.green.shade800;
                          } else if (grade.contains('جيد جدا')) {
                            gradeColor = Colors.blue.shade800;
                          } else if (grade.contains('جيد')) {
                            gradeColor = Colors.indigo;
                          } else if (grade.contains('راسب')) {
                            gradeColor = Colors.red.shade800;
                          }

                          return DataRow(
                            cells: [
                              DataCell(Text('$idx', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))),
                              DataCell(Text(acadId, style: const TextStyle(fontWeight: FontWeight.bold, color: primaryNavy))),
                              DataCell(Text(sName, style: const TextStyle(fontWeight: FontWeight.w600))),
                              DataCell(Text(spec)),
                              DataCell(Text(batch)),
                              DataCell(Text(total, style: const TextStyle(fontWeight: FontWeight.bold))),
                              DataCell(Text('$gpa%', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueAccent))),
                              DataCell(
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: gradeColor.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: gradeColor.withOpacity(0.4)),
                                  ),
                                  child: Text(grade, style: TextStyle(color: gradeColor, fontWeight: FontWeight.bold, fontSize: 12)),
                                ),
                              ),
                              DataCell(Text(updatedAt, style: const TextStyle(color: Colors.black54, fontSize: 12))),
                              DataCell(
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit_note, color: Colors.blueAccent, size: 22),
                                      tooltip: 'تعديل الدرجات والنتيجة',
                                      onPressed: () => _editStudentResultDialog(item),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                                      tooltip: 'حذف النتيجة',
                                      onPressed: () => _deleteStudentResult(acadId, sName),
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
          ),
        ],
      ),
    );
  }

  // --- محرر الكنترول والإكسل ---
  Widget _buildExcelUploadEditor({String? title}) {
    return Center(
      child: Container(
        width: 650,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12)]),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title ?? 'استيراد بيانات: $selectedSubService', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: primaryNavy)),
            const SizedBox(height: 12),
            Text(
              selectedSubService == 'أرقام الجلوس'
                  ? 'ملف Excel يحتوي على أعمدة: [الرقم الأكاديمي، رقم الجلوس، القاعة، الفصل]'
                  : (selectedSubService == 'النتائج'
                      ? 'ملف Excel يحتوي على أعمدة: [الرقم الأكاديمي، المجموع، المعدل، التقدير]'
                      : 'ملف Excel يحتوي على أعمدة: [الترتيب، اسم الطالب، التخصص، المعدل، الدفعة]'),
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.black54, fontSize: 13),
            ),
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              height: 160,
              decoration: BoxDecoration(color: Colors.green.shade50, border: Border.all(color: Colors.green.shade400), borderRadius: BorderRadius.circular(10)),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.table_view_outlined, size: 50, color: Colors.green.shade700),
                  const SizedBox(height: 8),
                  const Text('اختر ملف Excel لرفعه وحفظه فوراً في قاعدة البيانات', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _importControlExcel,
                    icon: const Icon(Icons.upload_file, color: Colors.white),
                    label: const Text('اختيار ملف إكسل ورفعه', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade800, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- محرر المالية ---
  Widget _buildFinanceEditor() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('إدارة المطالبات والإشعارات المالية', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: primaryNavy)),
              ElevatedButton.icon(
                onPressed: _saveFinanceData,
                icon: const Icon(Icons.send, color: Colors.white),
                label: const Text('إرسال الإشعار المالي فوراً', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12)),
              ),
            ],
          ),
          const Divider(height: 32),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.red.shade200)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: _finAcademicIdController,
                        textDirection: TextDirection.ltr,
                        decoration: const InputDecoration(labelText: 'الرقم الأكاديمي للطالب (اتركه فارغاً لإرساله للجميع)', border: OutlineInputBorder(), prefixIcon: Icon(Icons.person_search)),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: _finAmountController,
                        textDirection: TextDirection.ltr,
                        decoration: const InputDecoration(labelText: 'المبلغ المطلوب (ريال)', border: OutlineInputBorder()),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _finTitleController,
                  textDirection: TextDirection.rtl,
                  decoration: const InputDecoration(labelText: 'عنوان الإشعار (مثال: إشعار سداد القسط الثاني)', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _finDetailsController,
                  textDirection: TextDirection.rtl,
                  decoration: const InputDecoration(labelText: 'تفاصيل المطالبة والموعد النهائي', border: OutlineInputBorder()),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          const Text('سجل الإشعارات المالية المرسلة مؤخراً:', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: primaryNavy)),
          const SizedBox(height: 12),
          if (_isLoadingFin)
            const Center(child: CircularProgressIndicator())
          else if (_finList.isEmpty)
            const Text('لا توجد إشعارات مالية مسجلة حالياً.')
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _finList.length,
              itemBuilder: (context, index) {
                final item = _finList[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: const Icon(Icons.attach_money, color: Colors.green, size: 28),
                    title: Text(item['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('المبلغ: ${item['amount'] ?? 0} ر.ي | الطالب: ${item['academic_id'] ?? 'كافة الطلاب'} | ${item['details'] ?? ''}'),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  // --- محرر ومعاينة أرقام الجلوس ---
  Widget _buildSeatingNumbersEditor() {
    final query = _seatingSearchController.text.trim().toLowerCase();
    final displayList = _seatingList.where((item) {
      if (query.isEmpty) return true;
      final acadId = (item['academic_id'] ?? '').toString().toLowerCase();
      final seatNo = (item['seating_number'] ?? '').toString().toLowerCase();
      final hall = (item['hall'] ?? '').toString().toLowerCase();
      final term = (item['term'] ?? '').toString().toLowerCase();
      final studentObj = item['students'] is Map ? item['students'] : null;
      final name = (studentObj?['full_name'] ?? item['student_name'] ?? '').toString().toLowerCase();
      final specialty = (studentObj?['specialty'] ?? item['specialty'] ?? '').toString().toLowerCase();
      return acadId.contains(query) ||
          seatNo.contains(query) ||
          name.contains(query) ||
          specialty.contains(query) ||
          hall.contains(query) ||
          term.contains(query);
    }).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // شريط العنوان العلوي
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.badge_outlined, size: 28, color: primaryNavy),
                  SizedBox(width: 10),
                  Text(
                    'إدارة وتوزيع أرقام الجلوس والقاعات الامتحانية',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: primaryNavy),
                  ),
                ],
              ),
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: _importControlExcel,
                    icon: const Icon(Icons.upload_file, size: 18, color: Colors.white),
                    label: const Text('استيراد ملف إكسل دفعة واحدة', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
                  ),
                  const SizedBox(width: 10),
                  OutlinedButton.icon(
                    onPressed: _loadSeatingData,
                    icon: const Icon(Icons.refresh, size: 18, color: primaryNavy),
                    label: const Text('تحديث السجل', style: TextStyle(color: primaryNavy, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
                  ),
                ],
              ),
            ],
          ),
          const Divider(height: 28),

          // بطاقة إضافة أو تعديل رقم جلوس لطالب يدوياً
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _editingSeatingAcademicId != null ? accentGold : Colors.grey.shade300,
                width: _editingSeatingAcademicId != null ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _editingSeatingAcademicId != null ? Icons.edit_note : Icons.add_circle_outline,
                          color: _editingSeatingAcademicId != null ? accentGold : primaryNavy,
                          size: 22,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _editingSeatingAcademicId != null
                              ? 'تعديل رقم الجلوس والقاعة للطالب: ($_editingSeatingAcademicId)'
                              : 'إضافة أو اعتماد رقم جلوس لطالب يدوياً:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: _editingSeatingAcademicId != null ? accentGold : primaryNavy,
                          ),
                        ),
                      ],
                    ),
                    if (_editingSeatingAcademicId != null)
                      TextButton.icon(
                        onPressed: _resetSeatingForm,
                        icon: const Icon(Icons.close, size: 18, color: Colors.red),
                        label: const Text('إلغاء التعديل', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextField(
                            controller: _seatingAcademicIdController,
                            enabled: _editingSeatingAcademicId == null,
                            textDirection: TextDirection.ltr,
                            onChanged: _lookupStudentName,
                            decoration: InputDecoration(
                              labelText: 'الرقم الأكاديمي للطالب *',
                              hintText: 'مثال: 2025010101',
                              border: const OutlineInputBorder(),
                              prefixIcon: const Icon(Icons.person_pin),
                              filled: _editingSeatingAcademicId != null,
                              fillColor: _editingSeatingAcademicId != null ? Colors.grey.shade100 : null,
                            ),
                          ),
                          if (_detectedStudentInfo != null) ...[
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: _detectedStudentInfo!.contains('تنبيه') ? Colors.red.shade50 : const Color(0xFFEBF3FF),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: _detectedStudentInfo!.contains('تنبيه') ? Colors.red.shade300 : Colors.blue.shade300,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    _detectedStudentInfo!.contains('تنبيه') ? Icons.warning_amber_rounded : Icons.check_circle_outline,
                                    size: 16,
                                    color: _detectedStudentInfo!.contains('تنبيه') ? Colors.red.shade700 : primaryNavy,
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      _detectedStudentInfo!,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: _detectedStudentInfo!.contains('تنبيه') ? Colors.red.shade700 : primaryNavy,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: _seatingNumberController,
                        textDirection: TextDirection.ltr,
                        decoration: const InputDecoration(
                          labelText: 'رقم الجلوس *',
                          hintText: 'مثال: 10482',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.confirmation_number_outlined),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: _seatingHallController,
                        textDirection: TextDirection.rtl,
                        decoration: const InputDecoration(
                          labelText: 'القاعة الامتحانية / اللجنة',
                          hintText: 'مثال: قاعة 4 - الدور الثاني',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.meeting_room_outlined),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: _seatingTermController,
                        textDirection: TextDirection.rtl,
                        decoration: const InputDecoration(
                          labelText: 'الفصل الدراسي',
                          hintText: 'مثال: الفصل الأول 2024/2025',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.date_range_outlined),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerLeft,
                  child: ElevatedButton.icon(
                    onPressed: _isSavingSeating ? null : _saveSeatingNumber,
                    icon: Icon(
                      _editingSeatingAcademicId != null ? Icons.save : Icons.check_circle,
                      color: Colors.white,
                      size: 20,
                    ),
                    label: Text(
                      _isSavingSeating
                          ? 'جاري الحفظ...'
                          : (_editingSeatingAcademicId != null ? 'حفظ التعديلات على رقم الجلوس' : 'اعتماد وحفظ رقم الجلوس للطالب'),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _editingSeatingAcademicId != null ? accentGold : Colors.green.shade700,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // قسم معاينة الطلاب وقائمة السجل
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text(
                    'سجل الطلاب الذين تم اعتماد أرقام الجلوس لهم:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryNavy),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(color: primaryNavy, borderRadius: BorderRadius.circular(20)),
                    child: Text(
                      '${_seatingList.length} طالب',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                ],
              ),
              SizedBox(
                width: 320,
                child: TextField(
                  controller: _seatingSearchController,
                  textDirection: TextDirection.rtl,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'بحث بالاسم أو الرقم أو رقم الجلوس...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: _seatingSearchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _seatingSearchController.clear();
                              setState(() {});
                            },
                          )
                        : null,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // جدول البيانات
          if (_isLoadingSeating)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_seatingList.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: const Column(
                children: [
                  Icon(Icons.badge_outlined, size: 56, color: Colors.grey),
                  SizedBox(height: 12),
                  Text(
                    'لا توجد أرقام جلوس مسجلة حتى الآن.',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'يمكنك إضافة رقم جلوس لطالب من الحقول في الأعلى، أو استيراد ملف إكسل لجميع الطلاب دفعة واحدة.',
                    style: TextStyle(fontSize: 13, color: Colors.black54),
                  ),
                ],
              ),
            )
          else if (displayList.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: const Center(
                child: Text(
                  'لا توجد أرقام جلوس مطابقة لعبارة البحث المدخلة.',
                  style: TextStyle(fontSize: 15, color: Colors.grey, fontWeight: FontWeight.bold),
                ),
              ),
            )
          else
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2)),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    headingRowColor: MaterialStateProperty.all(const Color(0xFFF0F4F8)),
                    headingTextStyle: const TextStyle(fontWeight: FontWeight.bold, color: primaryNavy, fontSize: 13),
                    dataRowMinHeight: 48,
                    dataRowMaxHeight: 56,
                    columns: const [
                      DataColumn(label: Text('م')),
                      DataColumn(label: Text('الرقم الأكاديمي')),
                      DataColumn(label: Text('اسم الطالب')),
                      DataColumn(label: Text('التخصص')),
                      DataColumn(label: Text('رقم الجلوس')),
                      DataColumn(label: Text('القاعة الامتحانية')),
                      DataColumn(label: Text('الفصل الدراسي')),
                      DataColumn(label: Text('الإجراءات والتحكم')),
                    ],
                    rows: displayList.asMap().entries.map((entry) {
                      final index = entry.key + 1;
                      final item = entry.value;
                      final studentObj = item['students'] is Map ? item['students'] : null;
                      final studentName = studentObj?['full_name'] ?? item['student_name'] ?? '-';
                      final specialty = studentObj?['specialty'] ?? item['specialty'] ?? '-';
                      final isEditingThis = _editingSeatingAcademicId == item['academic_id'];

                      return DataRow(
                        color: isEditingThis
                            ? MaterialStateProperty.all(accentGold.withOpacity(0.12))
                            : null,
                        cells: [
                          DataCell(Text('$index', style: const TextStyle(fontWeight: FontWeight.bold))),
                          DataCell(
                            Text(
                              item['academic_id'] ?? '',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: primaryNavy),
                            ),
                          ),
                          DataCell(
                            Text(
                              studentName,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          DataCell(Text(specialty)),
                          DataCell(
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: accentGold.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: accentGold),
                              ),
                              child: Text(
                                '${item['seating_number'] ?? ''}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: primaryNavy,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                          DataCell(Text(item['hall'] ?? '')),
                          DataCell(Text(item['term'] ?? '')),
                          DataCell(
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ElevatedButton.icon(
                                  onPressed: () => _editSeating(item),
                                  icon: const Icon(Icons.edit, size: 15, color: Colors.white),
                                  label: const Text('تعديل', style: TextStyle(color: Colors.white, fontSize: 12)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primaryNavy,
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    minimumSize: Size.zero,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                OutlinedButton.icon(
                                  onPressed: () => _deleteSeatingNumber(item['academic_id'] ?? ''),
                                  icon: const Icon(Icons.delete_outline, size: 15, color: Colors.red),
                                  label: const Text('حذف', style: TextStyle(color: Colors.red, fontSize: 12)),
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(color: Colors.red),
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    minimumSize: Size.zero,
                                  ),
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
            ),
        ],
      ),
    );
  }

  Widget _buildMessageOnly(String msg) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.blue.shade200)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.info_outline, size: 50, color: Colors.blue.shade700),
              const SizedBox(height: 16),
              Text(msg, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, color: primaryNavy, fontWeight: FontWeight.bold, height: 1.5)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetaBadge(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(text, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}