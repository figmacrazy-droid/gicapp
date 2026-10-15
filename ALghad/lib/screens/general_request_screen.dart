import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/app_models.dart';
import '../services/auth_service.dart';
import '../theme/app_colors.dart';

class GeneralRequestScreen extends StatefulWidget {
  const GeneralRequestScreen({super.key});

  @override
  State<GeneralRequestScreen> createState() => _GeneralRequestScreenState();
}

class _GeneralRequestScreenState extends State<GeneralRequestScreen> {
  static const textColor = Color(0xFF03102E);
  static const String collegePhone = '967776166321';

  final _subjectController = TextEditingController();
  final _detailsController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  String? _selectedCategory;
  File? _capturedImage;
  StudentProfileModel? _student;
  bool _isSending = false;
  int _dailyRequestsCount = 0;
  static const int _maxDailyRequests = 3;

  @override
  void initState() {
    super.initState();
    _loadStudentAndQuota();
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _detailsController.dispose();
    super.dispose();
  }

  String _getTodayKey(String academicId) {
    final now = DateTime.now();
    return 'daily_general_requests_${academicId}_${now.year}_${now.month}_${now.day}';
  }

  Future<void> _loadStudentAndQuota() async {
    final session = await AuthService.getSavedSession();
    final student = session ??
        const StudentProfileModel(
          academicId: '2024000001',
          fullName: 'عبد الله أحمد الطالب',
          password: 'studentpassword',
          email: 'abdallah@alghad.edu.ye',
          specialty: 'علوم مختبرات طبية',
          level: 'المستوى الثاني',
          batch: 'الدفعة الخامسة',
          semester: 'الفصل الأول',
          group: 'المجموعة الأولى',
          studyShift: 'الفترة الصباحية',
        );

    final prefs = await SharedPreferences.getInstance();
    final key = _getTodayKey(student.academicId);
    final count = prefs.getInt(key) ?? 0;

    if (mounted) {
      setState(() {
        _student = student;
        _dailyRequestsCount = count;
      });
    }
  }

  Future<void> _takeLiveCameraPhoto() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.rear,
      );
      if (photo != null) {
        setState(() {
          _capturedImage = File(photo.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ أثناء فتح الكاميرا: $e')),
      );
    }
  }

  void _removeCapturedImage() {
    setState(() {
      _capturedImage = null;
    });
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24.0),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 90,
                  height: 90,
                  decoration: const BoxDecoration(
                    color: Color(0xFF00E676),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 60,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'تم إرسال الطلب!',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'سيتم مراجعة طلبك في اسرع وقت ممكن وسوف تتلقى منا إشعار عند الإنتهاء من المراجعة',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context); // إغلاق الدايلوج
                      Navigator.pop(context); // الرجوع للرئيسية
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: textColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('حسناً', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _submitRequest() async {
    if (_dailyRequestsCount >= _maxDailyRequests) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('عذراً، لقد استنفدت الحد الأقصى للطلبات المسموح بها اليوم (3 طلبات).'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final category = _selectedCategory?.trim() ?? '';
    final subject = _subjectController.text.trim();
    final details = _detailsController.text.trim();

    if (category.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى اختيار فئة الطلب أولاً'), backgroundColor: Colors.red),
      );
      return;
    }

    if (subject.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى كتابة موضوع الطلب أولاً'), backgroundColor: Colors.red),
      );
      return;
    }

    if (details.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى كتابة تفاصيل ومضمون الطلب'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isSending = true);

    final String messageText =
        'تقديم طلب عام جديد - كلية الغد المشرق:\n'
        '-----------------------------------------\n'
        'اسم الطالب: ${_student?.fullName ?? "غير مسجل"}\n'
        'الرقم الأكاديمي: ${_student?.academicId ?? "----------"}\n'
        'التخصص: ${_student?.specialty ?? "غير محدد"}\n'
        'المستوى: ${_student?.level ?? ""}\n'
        'فئة الطلب: $category\n'
        'الموضوع: $subject\n'
        'تفاصيل ومضمون الطلب:\n$details\n'
        '-----------------------------------------\n'
        '${_capturedImage != null ? "مرفق: صورة ملتقطة مباشرة عبر كاميرا التطبيق 📷" : "بدون صورة مرفقة"}';

    try {
      if (_capturedImage != null) {
        // إرسال الصورة الملتقطة مع النص مباشرة للواتساب عبر share_plus
        await Share.shareXFiles(
          [XFile(_capturedImage!.path)],
          text: messageText,
        );
      } else {
        // فتح محادثة الواتساب بالنص مباشرة
        final encoded = Uri.encodeComponent(messageText);
        final whatsappUrl = Uri.parse('whatsapp://send?phone=$collegePhone&text=$encoded');
        final webUrl = Uri.parse('https://api.whatsapp.com/send?phone=$collegePhone&text=$encoded');

        if (await canLaunchUrl(whatsappUrl)) {
          await launchUrl(whatsappUrl);
        } else {
          await launchUrl(webUrl, mode: LaunchMode.externalApplication);
        }
      }

      // زيادة عداد الطلبات اليومية وحفظه
      final prefs = await SharedPreferences.getInstance();
      if (_student != null) {
        final key = _getTodayKey(_student!.academicId);
        final newCount = _dailyRequestsCount + 1;
        await prefs.setInt(key, newCount);
        if (mounted) {
          setState(() {
            _dailyRequestsCount = newCount;
          });
        }
      }

      if (mounted) {
        _showSuccessDialog();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ أثناء الإرسال: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isLimitReached = _dailyRequestsCount >= _maxDailyRequests;
    final int remaining = _maxDailyRequests - _dailyRequestsCount;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'تقديم طلب عام',
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header Icon (تصميم الأيقونة الأصلية المعتمدة)
                Center(
                  child: SizedBox(
                    width: 130,
                    height: 110,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 110,
                          height: 110,
                          decoration: BoxDecoration(
                            color: textColor,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildWhiteLine(60),
                              const SizedBox(height: 12),
                              _buildWhiteLine(60),
                              const SizedBox(height: 12),
                              _buildWhiteLine(60),
                            ],
                          ),
                        ),
                        Positioned(
                          bottom: 5,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.gold,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.edit,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // شريط إحصائية الحد اليومي المتبقي للطلبات
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isLimitReached ? Colors.red.shade50 : const Color(0xFFF0F4FF),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isLimitReached ? Colors.red.shade200 : const Color(0xFFD0DCFF),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isLimitReached ? Icons.block : Icons.info_outline,
                        color: isLimitReached ? Colors.red.shade700 : textColor,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          isLimitReached
                              ? 'تم استنفاد الحد اليومي للطلبات (3 من 3). يمكنك تقديم طلبات جديدة غداً.'
                              : 'الطلبات المتاحة لليوم: $remaining من أصل $_maxDailyRequests طلبات',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                            color: isLimitReached ? Colors.red.shade800 : textColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Category Dropdown
                _buildDropdownField(
                  hint: 'فئة الطلب',
                  value: _selectedCategory,
                  items: const [
                    'استفسار أكاديمي',
                    'طلب وثيقة أو إفادة قيد',
                    'شؤون مالية ورسوم',
                    'شكوى أو مقترح',
                    'طلب عام آخر',
                  ],
                  onChanged: isLimitReached ? null : (val) => setState(() => _selectedCategory = val),
                ),
                const SizedBox(height: 16),

                // Subject Field
                _buildTextField(
                  controller: _subjectController,
                  hint: 'الموضوع',
                  enabled: !isLimitReached,
                ),
                const SizedBox(height: 16),

                // Details Field
                _buildTextField(
                  controller: _detailsController,
                  hint: 'تفاصيل الطلب',
                  maxLines: 6,
                  enabled: !isLimitReached,
                ),
                const SizedBox(height: 16),

                // التقاط صورة مباشرة بالكاميرا (استبدال حقل الإرفاق السابق)
                _buildCameraCaptureSection(enabled: !isLimitReached),
                const SizedBox(height: 36),

                // Submit Button
                ElevatedButton(
                  onPressed: (isLimitReached || _isSending) ? null : _submitRequest,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isLimitReached ? Colors.grey.shade400 : textColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSending
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                        )
                      : Text(
                          isLimitReached ? 'تم استنفاد الحد اليومي (3/3)' : 'إرسال الطلب',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
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

  Widget _buildWhiteLine(double width) {
    return Container(
      width: width,
      height: 6,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
    bool enabled = true,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      enabled: enabled,
      textAlign: TextAlign.right,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(10)),
          borderSide: BorderSide(color: textColor, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildDropdownField({
    required String hint,
    String? value,
    required List<String> items,
    required void Function(String?)? onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text(
            hint,
            style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
          ),
          isExpanded: true,
          icon: Icon(Icons.keyboard_arrow_down, color: Colors.grey.shade400),
          items: items.map((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(item),
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  // قسم التقاط الصورة المباشرة بالكاميرا
  Widget _buildCameraCaptureSection({bool enabled = true}) {
    if (_capturedImage != null) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.gold, width: 1.5),
          color: const Color(0xFFFFFDF5),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(
                _capturedImage!,
                width: 55,
                height: 55,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.check_circle, color: Color(0xFF00C853), size: 18),
                      SizedBox(width: 6),
                      Text(
                        'تم التقاط الصورة بنجاح',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textColor),
                      ),
                    ],
                  ),
                  SizedBox(height: 4),
                  Text(
                    'سيتم إرفاقها ومشاركتها مع تفاصيل الطلب',
                    style: TextStyle(color: Colors.grey, fontSize: 11),
                  ),
                ],
              ),
            ),
            if (enabled) ...[
              IconButton(
                icon: const Icon(Icons.camera_alt, color: textColor),
                tooltip: 'إعادة التقاط',
                onPressed: _takeLiveCameraPhoto,
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.red),
                tooltip: 'حذف الصورة',
                onPressed: _removeCapturedImage,
              ),
            ],
          ],
        ),
      );
    }

    return InkWell(
      onTap: enabled ? _takeLiveCameraPhoto : null,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade300),
          color: enabled ? Colors.white : Colors.grey.shade100,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  Icons.camera_alt_outlined,
                  color: enabled ? textColor : Colors.grey,
                  size: 22,
                ),
                const SizedBox(width: 12),
                Text(
                  'التقاط صورة مباشرة بالكاميرا (اختياري)',
                  style: TextStyle(
                    color: enabled ? Colors.grey.shade700 : Colors.grey.shade400,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            Icon(
              Icons.chevron_left,
              color: Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }
}
