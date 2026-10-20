import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/app_models.dart';
import '../services/auth_service.dart';
import '../services/data_service.dart';
import '../theme/app_colors.dart';

class GeneralRequestScreen extends StatefulWidget {
  const GeneralRequestScreen({super.key});

  @override
  State<GeneralRequestScreen> createState() => _GeneralRequestScreenState();
}

class _GeneralRequestScreenState extends State<GeneralRequestScreen> {
  static const textColor = Color(0xFF03102E);
  String _collegePhone = '967776166321';

  final _subjectController = TextEditingController();
  final _detailsController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  String? _selectedCategory;
  XFile? _capturedImage;
  Uint8List? _capturedImageBytes;
  String? _capturedImageName;
  String _uploadStatusText = '';
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
          academicId: '',
          fullName: 'طالب أكاديمي',
          password: '',
          email: '',
          specialty: '',
          level: 'المستوى الأول',
          batch: '',
          semester: '',
          group: '',
          studyShift: '',
        );

    final prefs = await SharedPreferences.getInstance();
    final key = _getTodayKey(student.academicId);
    final count = prefs.getInt(key) ?? 0;
    final phone = await DataService.getCollegeContactPhone();

    if (mounted) {
      setState(() {
        _student = student;
        _dailyRequestsCount = count;
        if (phone.isNotEmpty) _collegePhone = phone;
      });
    }
  }

  Future<void> _takeLiveCameraPhoto() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.rear,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 85,
      );
      if (photo != null) {
        final bytes = await photo.readAsBytes();
        setState(() {
          _capturedImage = photo;
          _capturedImageBytes = bytes;
          _capturedImageName = photo.name;
        });
      }
    } catch (e) {
      debugPrint('Error capturing photo with camera: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذر فتح الكاميرا، يرجى التحقق من أذونات الكاميرا')),
        );
      }
    }
  }

  void _removeCapturedImage() {
    setState(() {
      _capturedImage = null;
      _capturedImageBytes = null;
      _capturedImageName = null;
    });
  }

  Future<String?> _uploadImage(Uint8List bytes, String fileName) async {
    try {
      final safeName = fileName.isNotEmpty ? fileName : 'request_photo.jpg';
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('https://catbox.moe/user/api.php'),
      );
      request.fields['reqtype'] = 'fileupload';
      request.files.add(
        http.MultipartFile.fromBytes(
          'fileToUpload',
          bytes,
          filename: safeName,
        ),
      );
      final streamedResponse = await request.send().timeout(const Duration(seconds: 14));
      final response = await http.Response.fromStream(streamedResponse);
      if (response.statusCode == 200 && response.body.startsWith('http')) {
        return response.body.trim();
      }
    } catch (e) {
      debugPrint('Catbox upload error: $e');
    }

    try {
      final safeName = fileName.isNotEmpty ? fileName : 'request_photo.jpg';
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('https://tmpfiles.org/api/v1/upload'),
      );
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: safeName,
        ),
      );
      final streamedResponse = await request.send().timeout(const Duration(seconds: 12));
      final response = await http.Response.fromStream(streamedResponse);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final rawUrl = data['data']?['url'];
        if (rawUrl is String && rawUrl.isNotEmpty) {
          return rawUrl.replaceFirst('tmpfiles.org/', 'tmpfiles.org/dl/');
        }
      }
    } catch (e) {
      debugPrint('TmpFiles upload error: $e');
    }

    return null;
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

    setState(() {
      _isSending = true;
      _uploadStatusText = _capturedImageBytes != null ? 'جاري تجهيز الصورة للواتساب...' : 'جاري فتح محادثة الواتساب...';
    });

    String? uploadedImageUrl;
    if (_capturedImageBytes != null) {
      setState(() => _uploadStatusText = 'جاري رفع صورة الطلب لتظهر مباشرة بالواتساب...');
      uploadedImageUrl = await _uploadImage(
        _capturedImageBytes!,
        _capturedImageName ?? 'request_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
    }

    final String imageSection = uploadedImageUrl != null
        ? '📷 صورة الطلب المباشرة (اضغط للمعاينة الفورية):\n$uploadedImageUrl\n========================================='
        : (_capturedImage != null
            ? '📷 مرفق: تم التقاط صورة مباشرة للطلب بالكاميرا'
            : 'بدون صورة مرفقة');

    final String messageText =
        'تقديم طلب عام جديد - كلية الغد المشرق:\n'
        '=========================================\n'
        '👤 اسم الطالب: ${_student?.fullName ?? "غير مسجل"}\n'
        '🔢 الرقم الأكاديمي: ${_student?.academicId ?? "----------"}\n'
        '🎓 التخصص: ${_student?.specialty ?? "غير محدد"}\n'
        '📚 المستوى الدراسي: ${_student?.level ?? ""}\n'
        '📌 فئة الطلب: $category\n'
        '📝 موضوع الطلب: $subject\n'
        '📄 تفاصيل ومضمون الطلب:\n$details\n'
        '=========================================\n'
        '$imageSection';

    try {
      final cleanPhone = _collegePhone.replaceAll(RegExp(r'[^0-9]'), '');
      final targetPhone = cleanPhone.isNotEmpty ? cleanPhone : '967776166321';
      final encoded = Uri.encodeComponent(messageText);

      final waMeUrl = Uri.parse('https://wa.me/$targetPhone?text=$encoded');
      final whatsappUrl = Uri.parse('whatsapp://send?phone=$targetPhone&text=$encoded');
      final apiWhatsAppUrl = Uri.parse('https://api.whatsapp.com/send?phone=$targetPhone&text=$encoded');

      bool launched = false;
      try {
        launched = await launchUrl(waMeUrl, mode: LaunchMode.externalApplication);
      } catch (_) {}

      if (!launched) {
        try {
          if (await canLaunchUrl(whatsappUrl)) {
            launched = await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
          }
        } catch (_) {}
      }

      if (!launched) {
        try {
          launched = await launchUrl(apiWhatsAppUrl, mode: LaunchMode.externalApplication);
        } catch (_) {}
      }

      // حفظ نسخة من الطلب العام في جدول requests للمتابعة الأكاديمية
      try {
        await Supabase.instance.client.from('requests').insert({
          'academic_id': _student?.academicId ?? 'غير مسجل',
          'request_type': category,
          'details': 'موضوع: $subject\nالتفاصيل: $details',
          'status': 'قيد المعالجة',
          'created_at': DateTime.now().toIso8601String(),
        });
      } catch (_) {}

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
      debugPrint('Error sending request: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذر إرسال الطلب، يرجى التحقق من الاتصال بالإنترنت والمحاولة مجدداً'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
          _uploadStatusText = '';
        });
      }
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
                    elevation: 0,
                  ),
                  child: _isSending
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                            ),
                            const SizedBox(width: 12),
                            Flexible(
                              child: Text(
                                _uploadStatusText.isNotEmpty ? _uploadStatusText : 'جاري التجهيز والإرسال...',
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              isLimitReached ? 'تم استنفاد الحد اليومي (3/3)' : 'إرسال الطلب عبر الواتساب',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
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

  // قسم التقاط وإرفاق صورة الطلب
  Widget _buildCameraCaptureSection({bool enabled = true}) {
    if (_capturedImageBytes != null) {
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
              child: Image.memory(
                _capturedImageBytes!,
                width: 60,
                height: 60,
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
                        'تم إرفاق صورة الطلب بنجاح',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textColor),
                      ),
                    ],
                  ),
                  SizedBox(height: 4),
                  Text(
                    'سيتم إرسالها ومعاينتها مباشرة في الواتساب',
                    style: TextStyle(color: Colors.grey, fontSize: 11),
                  ),
                ],
              ),
            ),
            if (enabled) ...[
              IconButton(
                icon: const Icon(Icons.camera_alt, color: textColor),
                tooltip: 'إعادة التقاط صورة بالكاميرا',
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
