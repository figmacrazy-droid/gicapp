import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/app_models.dart';
import '../services/auth_service.dart';

class GeneralRequestScreen extends StatefulWidget {
  const GeneralRequestScreen({super.key});

  @override
  State<GeneralRequestScreen> createState() => _GeneralRequestScreenState();
}

class _GeneralRequestScreenState extends State<GeneralRequestScreen> {
  static const Color navyDark = Color(0xFF0B1E3D);

  final _requestTextController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  File? _capturedImage;
  StudentProfileModel? _student;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _loadStudentInfo();
  }

  void _loadStudentInfo() async {
    final session = await AuthService.getSavedSession();
    setState(() {
      _student = session ??
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
    });
  }

  Future<void> _takeLiveCameraPhoto() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera, // التقاط كاميرا لحظي مباشر فقط
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: navyDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'تقديم طلب عام',
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
                // Student info header summary
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F9FA),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'مقدم الطلب: ${_student?.fullName ?? "طالب الغد المشرق"}',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: navyDark, fontSize: 13),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'الرقم الأكاديمي: ${_student?.academicId ?? "----------"} | التخصص: ${_student?.specialty ?? ""}',
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                const Text('تفاصيل ومضمون الطلب:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: navyDark)),
                const SizedBox(height: 8),
                TextField(
                  controller: _requestTextController,
                  maxLines: 5,
                  decoration: InputDecoration(
                    hintText: 'اكتب تفاصيل طلبك العام هنا بكل وضوح...',
                    filled: true,
                    fillColor: const Color(0xFFF8F9FA),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 20),

                // Live Camera Capture Section Only
                const Text('إرفاق صورة الطلب (تصوير كاميرا لحظي مباشر حصراً):', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: navyDark)),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _takeLiveCameraPhoto,
                  icon: const Icon(Icons.camera_alt, color: navyDark),
                  label: const Text('التقاط صورة بالكاميرا الآن', style: TextStyle(color: navyDark, fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                if (_capturedImage != null) ...[
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.file(_capturedImage!, height: 160, width: double.infinity, fit: BoxFit.cover),
                  ),
                ],
                const SizedBox(height: 30),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isSending ? null : _sendRequestToWhatsApp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: navyDark,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                    ),
                    child: _isSending
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('إرسال الطلب (عبر الواتساب)', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _sendRequestToWhatsApp() async {
    final text = _requestTextController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى كتابة تفاصيل ومضمون الطلب أولاً'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isSending = true);

    final String fullMsg = Uri.encodeComponent(
      'تقديم طلب عام جديد - كلية الغد المشرق:\n'
      '-----------------------------------------\n'
      'اسم الطالب: ${_student?.fullName}\n'
      'الرقم الأكاديمي: ${_student?.academicId}\n'
      'التخصص: ${_student?.specialty}\n'
      'مضمون الطلب:\n$text\n\n'
      '${_capturedImage != null ? "تم التقاط صورة مرافقة بالكاميرا المباشرة للتطبيق." : "لم يتم التقاط صورة مرافقة."}',
    );

    final String whatsappUrl = 'whatsapp://send?phone=967776166321&text=$fullMsg';
    final Uri uri = Uri.parse(whatsappUrl);

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        final Uri webUri = Uri.parse('https://api.whatsapp.com/send?phone=967776166321&text=$fullMsg');
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر فتح الواتساب: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }
}
