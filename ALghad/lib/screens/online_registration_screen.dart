import 'dart:io';
import 'package:flutter/material.dart';
import '../models/app_models.dart';
import '../services/pdf_service.dart';

class OnlineRegistrationScreen extends StatefulWidget {
  const OnlineRegistrationScreen({super.key});

  @override
  State<OnlineRegistrationScreen> createState() => _OnlineRegistrationScreenState();
}

class _OnlineRegistrationScreenState extends State<OnlineRegistrationScreen> {
  static const Color navyDark = Color(0xFF0B1E3D);
  static const Color accentGold = Color(0xFFD39706);
  static const Color inputBg = Color(0xFFF8F9FA);

  int _currentStep = 1;
  bool _isSubmitting = false;

  final OnlineRegistrationForm _form = OnlineRegistrationForm();
  final _formKey1 = GlobalKey<FormState>();
  final _formKey2 = GlobalKey<FormState>();

  final List<String> _bachelorSpecialties = [
    'طب وجراحة',
    'صيدلة سريرية',
    'علوم مختبرات طبية',
    'تمريض عالي',
    'تكنولوجيا معلومات طبية',
  ];

  final List<String> _diplomaSpecialties = [
    'دبلوم صيدلة',
    'دبلوم مختبرات',
    'دبلوم تمريض',
    'دبلوم القبالة والتوليد',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: navyDark),
          onPressed: () {
            if (_currentStep > 1) {
              setState(() => _currentStep--);
            } else {
              Navigator.pop(context);
            }
          },
        ),
        title: Text(
          'التسجيل اونلاين - الخطوة ($_currentStep)',
          style: const TextStyle(
            color: navyDark,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Column(
            children: [
              _buildStepIndicator(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: _buildCurrentStepContent(),
                ),
              ),
              _buildBottomButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
      color: Colors.grey.shade50,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStepDot(1, 'البيانات الشخصية'),
          Container(width: 30, height: 2, color: _currentStep >= 2 ? navyDark : Colors.grey.shade300),
          _buildStepDot(2, 'الشهادة والوثائق'),
          Container(width: 30, height: 2, color: _currentStep >= 3 ? navyDark : Colors.grey.shade300),
          _buildStepDot(3, 'الرغبات والتعهد'),
        ],
      ),
    );
  }

  Widget _buildStepDot(int stepNumber, String title) {
    final bool isActive = _currentStep >= stepNumber;
    return Column(
      children: [
        CircleAvatar(
          radius: 14,
          backgroundColor: isActive ? navyDark : Colors.grey.shade300,
          child: Text(
            '$stepNumber',
            style: TextStyle(
              color: isActive ? Colors.white : Colors.grey.shade700,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: TextStyle(
            fontSize: 10,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            color: isActive ? navyDark : Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildCurrentStepContent() {
    switch (_currentStep) {
      case 1:
        return _buildStep1Form();
      case 2:
        return _buildStep2Form();
      case 3:
        return _buildStep3Form();
      default:
        return const SizedBox();
    }
  }

  // ═══════════════════════════════════════════════
  // الخطوة 1 - البيانات الشخصية
  // ═══════════════════════════════════════════════
  Widget _buildStep1Form() {
    return Form(
      key: _formKey1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('- الخطوة (1) :-', 'البيانات الشخصية للطالب'),
          const SizedBox(height: 16),
          const Text('اسم المتقدم (حسب البيانات الواردة في شهادة الثانوية العامة):',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildTextField('اسم الطالب', (v) => _form.firstName = v, initialValue: _form.firstName),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildTextField('اسم الأب', (v) => _form.fatherName = v, initialValue: _form.fatherName),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildTextField('اسم الجد', (v) => _form.grandfatherName = v, initialValue: _form.grandfatherName),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildTextField('اللقب', (v) => _form.lastName = v, initialValue: _form.lastName),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildTextField('بلد الجنسية', (v) => _form.nationality = v, initialValue: _form.nationality),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildTextField('تاريخ الميلاد (YYYY/MM/DD)', (v) => _form.birthDate = v, initialValue: _form.birthDate),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildTextField('مكان الميلاد (مثلاً: الروضة)', (v) => _form.birthPlace = v, initialValue: _form.birthPlace),
          const SizedBox(height: 16),
          const Text('الجنس:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: navyDark)),
          Row(
            children: [
              Radio<String>(
                value: 'ذكر',
                groupValue: _form.gender,
                onChanged: (val) => setState(() => _form.gender = val!),
                activeColor: navyDark,
              ),
              const Text('ذكر'),
              const SizedBox(width: 30),
              Radio<String>(
                value: 'أنثى',
                groupValue: _form.gender,
                onChanged: (val) => setState(() => _form.gender = val!),
                activeColor: navyDark,
              ),
              const Text('أنثى'),
            ],
          ),
          const SizedBox(height: 16),
          _buildTextField('البريد الإلكتروني', (v) => _form.email = v, keyboardType: TextInputType.emailAddress, initialValue: _form.email),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildTextField('موبايل ولي الأمر', (v) => _form.parentPhone = v, keyboardType: TextInputType.phone, initialValue: _form.parentPhone),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildTextField('موبايل الطالب', (v) => _form.studentPhone = v, keyboardType: TextInputType.phone, initialValue: _form.studentPhone),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════
  // الخطوة 2 - إدخال رقم الجلوس وعام التخرج والوثائق
  // ═══════════════════════════════════════════════
  Widget _buildStep2Form() {
    return Form(
      key: _formKey2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('- الخطوة (2) :-', 'إدخال رقم الجلوس وعام التخرج'),
          const SizedBox(height: 16),
          const Text('نوع الشهادة:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: navyDark)),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            value: _form.certificateType,
            decoration: _inputDecoration('اختر نوع الشهادة'),
            items: const [
              DropdownMenuItem(value: 'ثانوية عامة (علمي)', child: Text('ثانوية عامة (علمي)')),
              DropdownMenuItem(value: 'ثانوية عامة (أدبي)', child: Text('ثانوية عامة (أدبي)')),
              DropdownMenuItem(value: 'ثانوية مهنية/موافي', child: Text('ثانوية مهنية/موافي')),
            ],
            onChanged: (val) => setState(() => _form.certificateType = val!),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildTextField('رقم الجلوس', (v) => _form.seatingNumber = v, keyboardType: TextInputType.number, initialValue: _form.seatingNumber),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildTextField('المعدل العام (النسبة المئوية %)', (v) => _form.gpaPercentage = v, keyboardType: TextInputType.number, initialValue: _form.gpaPercentage),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text('عام التخرج:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: navyDark)),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            value: _form.graduationYear,
            decoration: _inputDecoration('اختر عام التخرج'),
            items: ['2024', '2023', '2022', '2021', '2020']
                .map((y) => DropdownMenuItem(value: y, child: Text(y)))
                .toList(),
            onChanged: (val) => setState(() => _form.graduationYear = val!),
          ),
          const SizedBox(height: 24),
          const Text('إرفاق الوثائق:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: navyDark)),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('تم فتح الكاميرا/المعرض لإرفاق صورة الوثائق بنجاح')),
              );
            },
            icon: const Icon(Icons.camera_alt_outlined, color: navyDark),
            label: const Text('قم بأخذ صورة للوثائق المتوفرة حالياً', style: TextStyle(color: navyDark)),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(height: 20),
          const Text('تأكيد الوثائق المرفقة:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: navyDark)),
          CheckboxListTile(
            title: const Text('أصل شهادة الثانوية العامة.'),
            value: _form.hasOriginalCert,
            onChanged: (v) => setState(() => _form.hasOriginalCert = v ?? false),
            activeColor: navyDark,
            contentPadding: EdgeInsets.zero,
          ),
          CheckboxListTile(
            title: const Text('صورة طبق الأصل - شهادة الثانوية العامة.'),
            value: _form.hasTrueCopyCert,
            onChanged: (v) => setState(() => _form.hasTrueCopyCert = v ?? false),
            activeColor: navyDark,
            contentPadding: EdgeInsets.zero,
          ),
          CheckboxListTile(
            title: const Text('(10) صور شخصية مقاس 4x6.'),
            value: _form.hasPersonalPhotos,
            onChanged: (v) => setState(() => _form.hasPersonalPhotos = v ?? false),
            activeColor: navyDark,
            contentPadding: EdgeInsets.zero,
          ),
          CheckboxListTile(
            title: const Text('صورة البطاقة الشخصية.'),
            value: _form.hasIdCopy,
            onChanged: (v) => setState(() => _form.hasIdCopy = v ?? false),
            activeColor: navyDark,
            contentPadding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════
  // الخطوة 3 - إختيار الرغبات والتعهد
  // ═══════════════════════════════════════════════
  Widget _buildStep3Form() {
    final double parsedGpa = double.tryParse(_form.gpaPercentage) ?? 0.0;
    final bool isGpaLowForBachelor = parsedGpa > 0 && parsedGpa < 75.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('- الخطوة (3) :-', 'إختيار الرغبات والتخصص'),
        const SizedBox(height: 20),
        const Text('نظام البكالوريوس التطبيقي أربع سنوات',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: navyDark)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _form.bachelorSpecialty.isEmpty ? null : _form.bachelorSpecialty,
          decoration: _inputDecoration('تخصصات البكالوريوس'),
          items: _bachelorSpecialties
              .map((s) => DropdownMenuItem(value: s, child: Text(s)))
              .toList(),
          onChanged: (val) {
            setState(() {
              _form.bachelorSpecialty = val ?? '';
              if (val != null) _form.diplomaSpecialty = '';
            });
          },
        ),
        if (isGpaLowForBachelor) ...[
          const SizedBox(height: 6),
          const Text(
            'للأسف معدلك لايسمح بالالتحاق بهذا النظام (يتطلب 75% فأعلى)',
            style: TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ],
        const SizedBox(height: 24),
        const Text('نظام الدبلوم العالي ثلاث سنوات',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: navyDark)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _form.diplomaSpecialty.isEmpty ? null : _form.diplomaSpecialty,
          decoration: _inputDecoration('تخصصات الدبلوم'),
          items: _diplomaSpecialties
              .map((s) => DropdownMenuItem(value: s, child: Text(s)))
              .toList(),
          onChanged: (val) {
            setState(() {
              _form.diplomaSpecialty = val ?? '';
              if (val != null) _form.bachelorSpecialty = '';
            });
          },
        ),
        const SizedBox(height: 30),
        const Text('تعهد وإقرار:', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.red)),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(
              value: _form.acceptedDeclaration,
              onChanged: (v) => setState(() => _form.acceptedDeclaration = v ?? false),
              activeColor: navyDark,
            ),
            const Expanded(
              child: Text(
                'أتعهد بأن كافة البيانات المدونة أعلاه صحيحة وأتحمل كافة التبعيات القانونية وأن أستكمل كافة الوثائق المطلوبة في حال قبولي بالكلية وأتعهد بأن التزم بكافة الشروط واللوائح والأنظمة الدراسية بالكلية.',
                style: TextStyle(fontSize: 12, height: 1.6, color: Color(0xFF333333)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBottomButton() {
    String buttonText = 'الخطوة الثانية';
    if (_currentStep == 2) buttonText = 'الخطوة الثالثة';
    if (_currentStep == 3) buttonText = 'الموافقة والتسجيل (إرسال عبر الواتساب)';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, -2))],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
          onPressed: _isSubmitting ? null : _handleNextStep,
          style: ElevatedButton.styleFrom(
            backgroundColor: navyDark,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
          ),
          child: _isSubmitting
              ? const CircularProgressIndicator(color: Colors.white)
              : Text(
                  buttonText,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                ),
        ),
      ),
    );
  }

  void _handleNextStep() async {
    if (_currentStep == 1) {
      if (_formKey1.currentState!.validate()) {
        _formKey1.currentState!.save();
        if (_form.isStep1Valid) {
          setState(() => _currentStep = 2);
        } else {
          _showErrorSnackBar('يرجى تعبئة جميع حقول البيانات الشخصية أولاً.');
        }
      }
    } else if (_currentStep == 2) {
      if (_formKey2.currentState!.validate()) {
        _formKey2.currentState!.save();
        if (_form.isStep2Valid) {
          setState(() => _currentStep = 3);
        } else {
          _showErrorSnackBar('يرجى تعبئة رقم الجلوس والمعدل لتنسيق الطلب.');
        }
      }
    } else if (_currentStep == 3) {
      if (!_form.acceptedDeclaration) {
        _showErrorSnackBar('يجب الموافقة على التعهد الإقرار لإتمام عملية التسجيل.');
        return;
      }
      if (_form.bachelorSpecialty.isEmpty && _form.diplomaSpecialty.isEmpty) {
        _showErrorSnackBar('يرجى اختيار التخصص المطلوب (بكالوريوس أو دبلوم).');
        return;
      }

      setState(() => _isSubmitting = true);
      try {
        final File pdfFile = await PdfService.generateRegistrationPdf(_form);
        await PdfService.sendPdfToWhatsApp(
          pdfFile: pdfFile,
          form: _form,
          targetPhone: '967776166321',
        );

        if (mounted) {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('تم تجهيز طلب التسجيل بنجاح!'),
              content: const Text(
                'تم إنشاء استمارة التسجيل المنسقة بصيغة PDF وتجهيز الإرسال إلى رقم الواتساب: 967776166321.',
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.pop(context);
                  },
                  child: const Text('موافق'),
                ),
              ],
            ),
          );
        }
      } catch (e) {
        _showErrorSnackBar('حدث خطأ أثناء إنشاء PDF: $e');
      } finally {
        if (mounted) setState(() => _isSubmitting = false);
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade700,
      ),
    );
  }

  Widget _buildSectionHeader(String badgeText, String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(badgeText, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: accentGold)),
        Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: navyDark)),
      ],
    );
  }

  Widget _buildTextField(String label, Function(String) onSaved,
      {TextInputType keyboardType = TextInputType.text, String? initialValue}) {
    return TextFormField(
      initialValue: initialValue,
      decoration: _inputDecoration(label),
      keyboardType: keyboardType,
      validator: (v) => (v == null || v.trim().isEmpty) ? 'مطلوب' : null,
      onChanged: onSaved,
      onSaved: (v) => onSaved(v ?? ''),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: inputBg,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: navyDark, width: 1.5)),
    );
  }
}
