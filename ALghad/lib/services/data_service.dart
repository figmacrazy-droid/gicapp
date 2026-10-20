import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/app_models.dart';
import 'auth_service.dart';

class DataService {
  static SupabaseClient? get _supabase {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  // --- جلب التعليمات والخطوات من Supabase مع بديل افتراضي ---
  static Future<InstructionStepModel> getInstructionFromSupabase(
    String serviceKey,
    InstructionStepModel fallback,
  ) async {
    try {
      final client = _supabase;
      if (client != null) {
        final res = await client
            .from('system_instructions')
            .select()
            .eq('service_key', serviceKey)
            .maybeSingle();

        if (res != null) {
          List<String> stepsList = [];
          final rawSteps = res['steps'];
          if (rawSteps is List) {
            stepsList = rawSteps.map((e) => e.toString()).toList();
          } else if (rawSteps is String) {
            stepsList = rawSteps
                .split('\n')
                .map((s) => s.trim())
                .where((s) => s.isNotEmpty)
                .toList();
          }
          return InstructionStepModel(
            id: res['id']?.toString() ?? fallback.id,
            title: res['title'] ?? fallback.title,
            subtitle: res['subtitle'] ?? fallback.subtitle,
            steps: stepsList.isNotEmpty ? stepsList : fallback.steps,
            note: res['note'] ?? fallback.note,
            externalUrl: res['external_url'] ?? fallback.externalUrl,
          );
        }
      }
    } catch (_) {}
    return fallback;
  }

  // 1. التسجيل في مقر الكلية
  static Future<InstructionStepModel> getCampusRegistrationInfo() async {
    const fallback = InstructionStepModel(
      id: 'campus_reg',
      title: 'التسجيل في مقر الكلية',
      subtitle: 'خطوات وإرشادات التسجيل المباشر بمقر الكلية',
      steps: [
        'زيارة قسم القبول والتسجيل بمقر الكلية في ساعات الدوام الرسمي.',
        'تعبئة نموذج طلب الالتحاق الورقي المخصص للكلية.',
        'تسليم أصل شهادة الثانوية العامة مع (4) صور طبق الأصل.',
        'إرفاق عدد (10) صور شخصية حديثة خلفية بيضاء مقاس 4x6.',
        'إرفاق صورة البطاقة الشخصية أو جواز السفر مع الأصل للمطابقة.',
        'سداد رسوم التسجيل المقررة لدى الخزينة واستلام سند القَبض.',
        'استلام الرقم الأكاديمي والبطاقة الجامعية الفورية.',
      ],
      note: 'ملاحظة: الدوام الرسمي من الأحد إلى الخميس - من الساعة 8:00 صباحاً وحتى 2:00 ظهراً.',
    );
    return getInstructionFromSupabase('التسجيل في مقر الكلية', fallback);
  }

  // التسجيل عبر بوابة الوزارة
  static Future<InstructionStepModel> getMinistryPortalInfo() async {
    const fallback = InstructionStepModel(
      id: 'ministry_reg',
      title: 'التسجيل عبر البوابة الإلكترونية لوزارة التربية والتعليم والبحث العلمي',
      subtitle: 'الربط المباشر مع البوابة الموحدة للتنسيق الإلكتروني',
      steps: [
        'الدخول على البوابة الإلكترونية الموحدة لوزارة التربية والتعليم والبحث العلمي.',
        'إنشاء حساب جديد أو تسجيل الدخول باسم المستخدم ورقم الجلوس.',
        'اختيار "الجامعات والكليات الأهلية" ثم اختيار "كلية الغد المشرق للعلوم الطبية والتطبيقية".',
        'تحديد التخصص الرغبة الأولى والثانية بحسب معدل الثانوية العامة.',
        'تسديد رسوم التنسيق عبر وسائل الدفع الإلكترونية المعتمدة.',
        'طباعة إشعار التنسيق ومراجعة الكلية لاستكمال إجراءات القبول النهائي.',
      ],
      externalUrl: 'https://oasyemen.net',
      note: 'يمكنك الانتقال المباشر لبوابة الوزارة عبر الضغط على الزر أدناه.',
    );
    return getInstructionFromSupabase('التسجيل عبر البوابة الإلكترونية لوزارة التربية', fallback);
  }

  // 2. الكادر الأكاديمي والتدريس
  static Future<List<AcademicStaffModel>> getAcademicStaff() async {
    const defaultStaff = [
      AcademicStaffModel(
        id: '1',
        name: 'د. عبد الله محمد علي',
        photoUrl: 'assets/images/doctor_1.png',
        experienceYears: '15 سنة خبرة',
        specialty: 'رئيس قسم الطب والجراحة / أستاذ دكتور',
        bio: 'خبرة عريقة في التدريس الأكاديمي والبحث العلمي وتطوير المناهج الطبية.',
      ),
      AcademicStaffModel(
        id: '2',
        name: 'د. فاطمة أحمد العبسي',
        photoUrl: 'assets/images/doctor_2.png',
        experienceYears: '10 سنوات خبرة',
        specialty: 'أستاذ الصيدلة السريرية والعقاقير',
        bio: 'استشارية في الصيدلة الطبية ومحاضرة في العديد من المؤتمرات الأكاديمية.',
      ),
      AcademicStaffModel(
        id: '3',
        name: 'أ.د. خالد سالم باوزير',
        photoUrl: 'assets/images/doctor_3.png',
        experienceYears: '12 سنة خبرة',
        specialty: 'أخصائي علوم المختبرات والتشخيص الطبي',
        bio: 'رئيس قسم المختبرات ومدرب معتمد لبرامج التدريب السريري.',
      ),
      AcademicStaffModel(
        id: '4',
        name: 'د. سارة حسين مطهر',
        photoUrl: 'assets/images/doctor_4.png',
        experienceYears: '8 سنوات خبرة',
        specialty: 'أستاذة علوم التمريض والرعاية المركزة',
        bio: 'ممتدة الخبرة في تطبيق برامج التدريب الميداني للتمريض العالي.',
      ),
    ];

    try {
      final client = _supabase;
      if (client != null) {
        final res = await client
            .from('academic_staff')
            .select()
            .order('display_order', ascending: true);
        final list = res as List;
        if (list.isNotEmpty) {
          return list.map((item) => AcademicStaffModel(
            id: item['id']?.toString() ?? '',
            name: item['name'] ?? '',
            photoUrl: item['photo_url'] ?? 'assets/images/doctor_1.png',
            experienceYears: item['experience_years'] ?? '',
            specialty: item['specialty'] ?? '',
            bio: item['bio'],
          )).toList();
        }
      }
    } catch (_) {}
    return defaultStaff;
  }

  // التدريب الميداني
  static Future<InstructionStepModel> getFieldTrainingInfo() async {
    const fallback = InstructionStepModel(
      id: 'field_training',
      title: 'التدريب الميداني',
      subtitle: 'تعليمات وضوابط برنامج التدريب السريري والميداني',
      steps: [
        'الالتزام بالزي الطبي المعتمد والبطاقة التدريبية طوال فترة التدريب.',
        'الحضور والغياب يتم تقييمه يومياً عبر مشرف المستشفى/الجهة التدريبية.',
        'تعبئة دفتر سجل التدريب الميداني (Logbook) وتوقيعه من الطبيب المشرف.',
        'تقديم تقرير التدريب الميداني النهائي لقسم التدريب بالكلية فور انتهاء الفترة.',
        'الالتزام بالسلوك المهني وأخلاقيات المهنة والحفاظ على سرية بيانات المرضى.',
      ],
      note: 'يبدأ التسجيل في التدريب الميداني بداية كل فصل دراسي للمستويات المتقدمة.',
    );
    return getInstructionFromSupabase('التدريب الميداني', fallback);
  }

  // 3. الجداول الدراسية وجداول الامتحانات
  static Future<List<ScheduleModel>> getSchedules(String type) async {
    try {
      final client = _supabase;
      if (client != null) {
        final res = await client
            .from('schedules')
            .select()
            .eq('type', type)
            .order('created_at', ascending: false);
        final list = res as List;
        if (list.isNotEmpty) {
          return list.map((item) => ScheduleModel(
            id: item['id']?.toString() ?? '',
            title: item['title'] ?? '',
            type: item['type'] ?? type,
            fileUrl: item['file_url'] ?? '',
            isPdf: item['is_pdf'] ?? true,
            academicYear: item['academic_year'] ?? '2024 - 2025',
          )).toList();
        }
      }
    } catch (_) {}
    return [];
  }

  // تعليمات خدمات شؤون الطلاب الديناميكية
  static Future<InstructionStepModel> getStudentAffairsServiceInfo(String title) async {
    InstructionStepModel fallback;
    switch (title) {
      case 'الأنشطة والفعاليات':
        fallback = const InstructionStepModel(
          id: 'activities',
          title: 'الأنشطة والفعاليات',
          subtitle: 'جدول وخطة الأنشطة الطلابية والرياضية والثقافية',
          steps: [
            'متابعة الإعلانات الدورية الصادرة من إدارة الأنشطة الطلابية.',
            'التسجيل في الأندية والفرق الرياضية المتاحة عبر الشؤون الطلابية.',
            'المشاركة في المعارض العلمية والملتقيات الثقافية بالكلية.',
            'تقديم مقترحات الفعاليات والأنشطة إلى مجلس الطلاب.',
          ],
        );
        break;

      case 'تقديم طلب تحويل (من تخصص إلى تخصص آخر)':
      case 'تقديم طلب تحويل من تخصص إلى تخصص آخر':
        fallback = const InstructionStepModel(
          id: 'transfer',
          title: 'تقديم طلب تحويل من تخصص إلى تخصص آخر',
          subtitle: 'شروط وإجراءات التحويل بين الأقسام الأكاديمية',
          steps: [
            'أن يكون التخصص المطلوب تحويل الملف إليه متوافقاً مع نسبة الثانوية العامة.',
            'تعبئة استمارة التحويل المتوفرة قسم شؤون الطلاب.',
            'سداد رسوم المقاصصة والتحويل المقررة.',
            'موافقة عميد الكلية ورؤساء الأقسام المعنية.',
          ],
        );
        break;

      case 'تقديم طلب وقف قيد':
        fallback = const InstructionStepModel(
          id: 'stop_reg',
          title: 'تقديم طلب وقف قيد',
          subtitle: 'إجراءات التأجيل وتجميد الفصل الدراسي',
          steps: [
            'تقديم الطلب خلال الأسابيع الأولى من بدء الفصل الدراسي.',
            'إرفاق عذر شرعي أو طبي معتمد يبرر طلب وقف القيد.',
            'تصفية كافة الالتزامات المالية السابقة لدى الشؤون المالية.',
            'موافقة الشؤون الأكاديمية وصرف إشعار وقف القيد رسمياً.',
          ],
        );
        break;

      case 'تقديم طلب فتح قيد':
        fallback = const InstructionStepModel(
          id: 'open_reg',
          title: 'تقديم طلب فتح قيد',
          subtitle: 'إعادة تفعيل واستئناف الدراسة بعد وقف القيد',
          steps: [
            'تقديم طلب إعادة فتح القيد قبل بداية الفصل الدراسي الجديد بربع شهر على الأقل.',
            'إرفاق إشعار وقف القيد السابق.',
            'تسديد الرسوم الدراسية المقررة للفصل الجديد.',
            'تحديث البيانات وتأكيد الجدول الدراسي من التسجيل.',
          ],
        );
        break;

      case 'تقديم طلب مقاصصة':
        fallback = const InstructionStepModel(
          id: 'equivalency',
          title: 'تقديم طلب مقاصصة',
          subtitle: 'معادلة المواد الدراسية للطلاب المحولين',
          steps: [
            'إحضار كشف درجات معتمد وموثق من الكلية/الجامعة السابقة.',
            'إحضار الموصوف الدراسي (المحتوى العلمي) للمواد المطلوب معادلتها.',
            'تعبئة استمارة المقاصصة وتحديد المواد المتكافئة.',
            'اعتماد اللجنة الأكاديمية المختصة واستلام نتيجة المقاصصة.',
          ],
        );
        break;

      case 'تقديم طلب تجميد ملف':
        fallback = const InstructionStepModel(
          id: 'freeze_file',
          title: 'تقديم طلب تجميد ملف',
          subtitle: 'تجميد الملف الأكاديمي مؤقتاً',
          steps: [
            'تعبئة نموذج طلب التجميد مع بيان أسباب التجميد.',
            'استكمال إخلاء الطرف من المكتبة والمعامل والشؤون المالية.',
            'اعتماد طلب التجميد من إدارة التسجيل والقبول.',
          ],
        );
        break;

      case 'تقديم طلب سحب ملف':
        fallback = const InstructionStepModel(
          id: 'withdraw_file',
          title: 'تقديم طلب سحب ملف',
          subtitle: 'السحب النهائي للوثائق من الكلية',
          steps: [
            'تقديم استمارة سحب الملف النهائية من الطالب أو ولي أمره بموجب توكيل رسمي.',
            'استكمال إخلاء الطرف التام من كافة أقسام وإدارات الكلية.',
            'تسليم البطاقة الجامعية واستلام أصول الوثائق الشخصية والدراسية.',
          ],
        );
        break;

      case 'تقديم طلب استخراج إفادة تخرج':
        fallback = const InstructionStepModel(
          id: 'grad_statement',
          title: 'تقديم طلب استخراج إفادة تخرج',
          subtitle: 'إجراءات إصدار إفادة استكمال متطلبات التخرج',
          steps: [
            'الإنهاء التام لجميع المواد والمستويات الدراسية وساعات التدريب.',
            'إكمال استمارة إخلاء طرف الخريج من الشؤون المالية والمكتبة.',
            'سداد رسوم استخراج إفادة التخرج.',
            'استلام الإفادة المعتمدة من قسم شؤون الخريجين خلال 3 أيام عمل.',
          ],
        );
        break;

      case 'تقديم طلب استخراج شهادة (دبلوم/بكالوريوس)':
        fallback = const InstructionStepModel(
          id: 'degree_cert',
          title: 'تقديم طلب استخراج شهادة (دبلوم/بكالوريوس)',
          subtitle: 'إصدار الوثيقة الكرتونية وكشف الدرجات النهائي',
          steps: [
            'تعبئة طلب استخراج الشهادة وإرفاق عدد (4) صور شخصية بالزي الرسمي.',
            'تحديد لغة الشهادة (عربي / إنكليزي).',
            'التأكد من صحة مطابقة الاسم باللغة الإنجليزية طبقاً لجواز السفر.',
            'مراجعة شؤون الخريجين لاستلام الشهادة والتوقيع في السجل العام.',
          ],
        );
        break;

      case 'تقديم طلب استخراج الوثائق اللازمة للتقديم على مزاولة المهنة':
        fallback = const InstructionStepModel(
          id: 'license_docs',
          title: 'تقديم طلب استخراج الوثائق اللازمة للتقديم على مزاولة المهنة',
          subtitle: 'تجهيز ملف التراخيص والمزاولة الطبية',
          steps: [
            'إرفاق صور طبق الأصل من الشهادة وكشف الدرجات وإفادة التخرج.',
            'إرفاق شهادة إتمام التدريب الميداني وساعات الساعات السريرية.',
            'تعبئة نموذج التوصية الموجه لنقابة المهن الطبية أو وزارة الصحة.',
            'استلام الملف الموثق الخاص بطلب تراخيص مزاولة المهنة.',
          ],
        );
        break;

      case 'تقديم طلب تظلم':
        fallback = const InstructionStepModel(
          id: 'grievance',
          title: 'تقديم طلب تظلم امتحاني',
          subtitle: 'شروط وضوابط مراجعة كراسات الإجابة',
          steps: [
            'تقديم الطلب خلال مدة لا تتجاوز أسابيع من تاريخ إعلان النتائج.',
            'تحديد المادة أو المواد المراد إعادة مراجعتها.',
            'سداد رسوم التظلم المقررة لكل مادة في الخزينة.',
            'مراجعة لجنة الكنترول وإعلان قرار نتيجة التظلم رسمياً.',
          ],
        );
        break;

      default:
        fallback = InstructionStepModel(
          id: 'general',
          title: title,
          steps: const [
            'تعبئة الطلب المخصص للخدمة.',
            'مراجعة الإدارة المختصة بالكلية.',
            'استكمال الإجراءات والرسوم المحددة.',
          ],
        );
    }
    return getInstructionFromSupabase(title, fallback);
  }

  // 4. الكنترول - أرقام الجلوس
  static Future<SeatingNumberModel?> searchSeatingNumber(String academicId) async {
    try {
      final client = _supabase;
      final cleanId = AuthService.normalizeDigits(academicId.trim());
      if (client != null && cleanId.isNotEmpty) {
        final session = await AuthService.getSavedSession();
        // حماية خصوصية الطالب: إذا كان مسجل الدخول لا يستعلم إلا عن رقمه الأكاديمي
        if (session != null &&
            session.academicId.isNotEmpty &&
            session.academicId.trim() != cleanId) {
          return null;
        }

        Map<String, dynamic>? res;
        if (session?.sessionToken != null && session!.sessionToken!.isNotEmpty) {
          try {
            final rpcRes = await client.rpc(
              'app_get_seating',
              params: {'p_token': session.sessionToken},
            );
            if (rpcRes is Map) {
              res = Map<String, dynamic>.from(rpcRes);
            }
          } catch (_) {}
        }

        res ??= await client
            .from('seating_numbers')
            .select('*, students(full_name, specialty, level)')
            .eq('academic_id', cleanId)
            .maybeSingle();

        if (res != null) {
          final studentObj = res['students'] is Map ? res['students'] : null;
          final studentName = studentObj?['full_name'] ?? res['student_name'] ?? '';
          final specialty = studentObj?['specialty'] ?? res['specialty'] ?? '';

          return SeatingNumberModel(
            academicId: res['academic_id'] ?? cleanId,
            studentName: studentName.isNotEmpty ? studentName : 'الطالب',
            specialty: specialty.isNotEmpty ? specialty : 'عام',
            term: res['term'] ?? 'الفصل الدراسي الحالي',
            hall: res['hall'] ?? 'القاعة الكبرى',
            seatingNumber: res['seating_number']?.toString() ?? '',
          );
        }
      }
    } catch (e) {
      // Ignored
    }
    return null;
  }

  // أوائل الطلاب
  static Future<List<TopStudentModel>> getTopStudents() async {
    const defaultList = [
      TopStudentModel(rank: 1, studentName: 'أحمد صالح عبد الرحمن', specialty: 'طب وجراحة', gpa: 98.5, batch: 'دفعة سفراء الغد'),
      TopStudentModel(rank: 2, studentName: 'مريم علي حسن القاضي', specialty: 'صيدلة سريرية', gpa: 97.8, batch: 'دفعة سفراء الغد'),
      TopStudentModel(rank: 3, studentName: 'خالد عمر باحاج', specialty: 'علوم مختبرات', gpa: 96.9, batch: 'دفعة سفراء الغد'),
      TopStudentModel(rank: 4, studentName: 'فاطمة محمد ناصر', specialty: 'تمريض عالي', gpa: 95.7, batch: 'دفعة عظماء الغد'),
      TopStudentModel(rank: 5, studentName: 'سعيد عبد الله العمري', specialty: 'صيدلة دبلوم', gpa: 94.8, batch: 'دفعة عظماء الغد'),
    ];

    try {
      final client = _supabase;
      if (client != null) {
        final res = await client
            .from('top_students')
            .select()
            .order('rank', ascending: true);
        final list = res as List;
        if (list.isNotEmpty) {
          return list.map((item) => TopStudentModel(
            rank: item['rank'] is int ? item['rank'] : int.tryParse(item['rank'].toString()) ?? 1,
            studentName: item['student_name'] ?? '',
            specialty: item['specialty'] ?? '',
            gpa: (item['gpa'] as num?)?.toDouble() ?? 0.0,
            batch: item['batch'] ?? '',
          )).toList();
        }
      }
    } catch (_) {}
    return defaultList;
  }

  // رقم التواصل والواتساب الموحد للكلية
  static String? _cachedCollegePhone;

  static Future<String> getCollegeContactPhone() async {
    if (_cachedCollegePhone != null && _cachedCollegePhone!.isNotEmpty) {
      return _cachedCollegePhone!;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString('college_contact_phone');
      if (saved != null && saved.trim().isNotEmpty) {
        _cachedCollegePhone = saved.trim();
      }
    } catch (_) {}

    try {
      final client = _supabase;
      if (client != null) {
        final res = await client
            .from('system_instructions')
            .select('note, steps, external_url')
            .eq('service_key', 'college_whatsapp_phone')
            .maybeSingle();
        if (res != null) {
          String val = (res['note'] ?? res['steps'] ?? '').toString().trim();
          if (val.isEmpty && res['external_url'] != null) {
            val = res['external_url'].toString().replaceAll(RegExp(r'[^0-9]'), '');
          }
          if (val.isNotEmpty) {
            _cachedCollegePhone = val;
            _savePhoneToPrefs(val);
            return val;
          }
        }

        final helpRes = await client
            .from('system_instructions')
            .select('note, external_url')
            .eq('service_key', 'المساعدة والدعم')
            .maybeSingle();
        if (helpRes != null) {
          String val = '';
          if (helpRes['external_url'] != null) {
            val = helpRes['external_url'].toString().replaceAll(RegExp(r'[^0-9]'), '');
          }
          if (val.isEmpty && helpRes['note'] != null) {
            final match = RegExp(r'\b(967\d{8,9}|\d{9})\b').firstMatch(helpRes['note'].toString());
            if (match != null) val = match.group(0)!;
          }
          if (val.isNotEmpty) {
            _cachedCollegePhone = val;
            _savePhoneToPrefs(val);
            return val;
          }
        }
      }
    } catch (_) {}

    return _cachedCollegePhone ?? '967776166321';
  }

  static void _savePhoneToPrefs(String phone) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('college_contact_phone', phone);
    } catch (_) {}
  }

  // النتائج
  static Future<StudentResultModel?> getStudentResults(String academicId) async {
    try {
      final client = _supabase;
      final trimmedId = AuthService.normalizeDigits(academicId.trim());
      if (client != null && trimmedId.isNotEmpty) {
        final session = await AuthService.getSavedSession();
        // حماية الخصوصية: لا يمكن للطالب استعراض نتائج رقم أكاديمي آخر غير رقمه
        if (session != null &&
            session.academicId.isNotEmpty &&
            session.academicId.trim() != trimmedId) {
          return null;
        }

        // 1. فحص جدول النتائج مع بيانات الطالب (عبر RPC الآمن أولاً ثم المباشر)
        Map<String, dynamic>? res;
        if (session?.sessionToken != null && session!.sessionToken!.isNotEmpty) {
          try {
            final rpcRes = await client.rpc(
              'app_get_result',
              params: {'p_token': session.sessionToken},
            );
            if (rpcRes is Map && rpcRes['result'] is Map) {
              res = Map<String, dynamic>.from(rpcRes['result'] as Map);
            }
          } catch (_) {}
        }

        res ??= await client
            .from('student_results')
            .select('*, students(full_name, specialty, batch, level, semester, is_result_hidden, is_blocked)')
            .eq('academic_id', trimmedId)
            .maybeSingle();

        // 2. فحص قفل الكنترول العام للنظام
        bool isSystemLocked = false;
        try {
          final lockRes = await client
              .from('system_instructions')
              .select('steps')
              .eq('service_key', 'results_lock_control')
              .maybeSingle();
          if (lockRes != null && lockRes['steps'] != null) {
            final decoded = jsonDecode(lockRes['steps'] as String);
            if (decoded is Map && decoded['is_locked'] == true) {
              isSystemLocked = true;
            }
          }
        } catch (_) {}

        if (res != null) {
          Map<String, double> subs = {};
          final rawSubs = res['subjects'];
          bool isRecordHidden = false;
          String customMessage = 'عذراً، النتيجة محجوبة حالياً من قبل إدارة الكنترول وشؤون الطلاب.\nيرجى مراجعة إدارة الكلية أو الشؤون المالية لتسوية وضعك الأكاديمي والمالي.';

          if (rawSubs is Map) {
            if (rawSubs['is_result_hidden'] == true || rawSubs['is_hidden'] == true) {
              isRecordHidden = true;
            }
            if (rawSubs['withheld_message'] != null && rawSubs['withheld_message'].toString().trim().isNotEmpty) {
              customMessage = rawSubs['withheld_message'].toString().trim();
            }
            rawSubs.forEach((k, v) {
              if (k != 'terms' && k != 'is_result_hidden' && k != 'is_hidden' && k != 'withheld_message') {
                if (v is num) {
                  subs[k.toString()] = v.toDouble();
                } else if (v is String) {
                  final parsed = double.tryParse(v);
                  if (parsed != null) subs[k.toString()] = parsed;
                }
              }
            });
          }

          List<TermResultModel> termsList = [];
          if (rawSubs is Map && rawSubs.containsKey('terms') && rawSubs['terms'] is List) {
            final rawTerms = rawSubs['terms'] as List;
            termsList = rawTerms.map((t) => TermResultModel.fromJson(Map<String, dynamic>.from(t as Map))).toList();
          }

          final studentsData = res['students'] as Map<String, dynamic>?;
          final sName = studentsData?['full_name'] ?? res['student_name'] ?? 'طالب';
          final sSpec = studentsData?['specialty'] ?? res['specialty'] ?? '';
          final sBatch = studentsData?['batch'] ?? res['batch'] ?? '';
          final sSemester = studentsData?['semester'] ?? 'الفصل الدراسي الحالي';

          final bool isStudentHidden = (studentsData?['is_result_hidden'] == true) || (studentsData?['is_blocked'] == true);
          final bool isWithheld = isSystemLocked || isRecordHidden || isStudentHidden;

          if (termsList.isEmpty && subs.isNotEmpty) {
            termsList.add(TermResultModel(
              termName: sSemester,
              academicYear: studentsData?['academic_year'] ?? '2024/2025',
              subjects: subs,
              totalMarks: (res['total_marks'] as num?)?.toDouble() ?? 0.0,
              gpa: (res['gpa'] as num?)?.toDouble() ?? 0.0,
              grade: res['grade'] ?? 'ناجح',
            ));
          }

          final activeTerm = termsList.isNotEmpty ? termsList.first : null;

          return StudentResultModel(
            academicId: res['academic_id'] ?? trimmedId,
            studentName: sName,
            specialty: sSpec,
            batch: sBatch,
            terms: termsList,
            subjects: activeTerm?.subjects ?? subs,
            totalMarks: activeTerm?.totalMarks ?? ((res['total_marks'] as num?)?.toDouble() ?? 0.0),
            gpa: activeTerm?.gpa ?? ((res['gpa'] as num?)?.toDouble() ?? 0.0),
            grade: activeTerm?.grade ?? (res['grade'] ?? 'ناجح'),
            isWithheld: isWithheld,
            withheldMessage: customMessage,
          );
        } else {
          try {
            final studentRow = await client
                .from('students')
                .select('full_name, specialty, batch, is_result_hidden, is_blocked')
                .eq('academic_id', trimmedId)
                .maybeSingle();
            if (studentRow != null) {
              final bool isHidden = (studentRow['is_result_hidden'] == true) || (studentRow['is_blocked'] == true) || isSystemLocked;
              if (isHidden) {
                return StudentResultModel(
                  academicId: trimmedId,
                  studentName: studentRow['full_name'] ?? 'طالب',
                  specialty: studentRow['specialty'] ?? '',
                  batch: studentRow['batch'] ?? '',
                  terms: const [],
                  subjects: const {},
                  totalMarks: 0.0,
                  gpa: 0.0,
                  grade: 'محجوب',
                  isWithheld: true,
                  withheldMessage: 'عذراً، النتيجة محجوبة حالياً من قبل إدارة الكنترول وشؤون الطلاب.\nيرجى مراجعة إدارة الكلية أو الشؤون المالية لتسوية وضعك الأكاديمي والمالي.',
                );
              }
            }
          } catch (_) {}
        }
      }
    } catch (e) {
      debugPrint('Error getting student results: $e');
    }
    return null;
  }

  // دليل الطالب الجامعي
  static Future<String> getUniversityGuidePdfUrl() async {
    try {
      final client = _supabase;
      if (client != null) {
        final res = await client.from('university_guides').select().limit(1);
        final list = res as List;
        if (list.isNotEmpty && list.first['file_url'] != null) {
          return list.first['file_url'];
        }
      }
    } catch (_) {}
    return 'assets/pdf/university_student_guide.pdf';
  }

  // روابط التواصل الاجتماعي
  static Future<List<SocialMediaLinkModel>> getSocialMediaLinks() async {
    final phone = await getCollegeContactPhone();
    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
    final defaultLinks = [
      const SocialMediaLinkModel(id: '1', platformName: 'صفحتنا على فيسبوك', url: 'https://facebook.com/alghadcollege', iconPath: 'assets/icons/facebook.png'),
      const SocialMediaLinkModel(id: '2', platformName: 'قناتنا على تليجرام', url: 'https://t.me/alghadcollege', iconPath: 'assets/icons/telegram.png'),
      const SocialMediaLinkModel(id: '3', platformName: 'قناتنا على يوتيوب', url: 'https://youtube.com/@alghadcollege', iconPath: 'assets/icons/youtube.png'),
      SocialMediaLinkModel(id: '4', platformName: 'تواصل معنا على الواتساب', url: 'https://wa.me/$cleanPhone', iconPath: 'assets/icons/whatsapp.png'),
      const SocialMediaLinkModel(id: '5', platformName: 'الموقع الإلكتروني الرسمي', url: 'https://alghad-college.edu.ye', iconPath: 'assets/icons/website.png'),
    ];

    try {
      final client = _supabase;
      if (client != null) {
        final res = await client
            .from('social_media_links')
            .select()
            .order('display_order', ascending: true);
        final list = res as List;
        if (list.isNotEmpty) {
          return list.map((item) {
            String icon = 'assets/icons/website.png';
            final iconName = item['icon_name']?.toString().toLowerCase() ?? '';
            if (iconName.contains('face')) icon = 'assets/icons/facebook.png';
            else if (iconName.contains('tele')) icon = 'assets/icons/telegram.png';
            else if (iconName.contains('you')) icon = 'assets/icons/youtube.png';
            else if (iconName.contains('whats')) icon = 'assets/icons/whatsapp.png';
            else if (iconName.contains('insta')) icon = 'assets/icons/instagram.png';

            String url = item['url'] ?? '';
            if (iconName.contains('whats') || url.contains('wa.me') || url.contains('whatsapp')) {
              url = 'https://wa.me/$cleanPhone';
            }

            return SocialMediaLinkModel(
              id: item['id']?.toString() ?? '',
              platformName: item['platform_name'] ?? '',
              url: url,
              iconPath: icon,
            );
          }).toList();
        }
      }
    } catch (_) {}
    return defaultLinks;
  }

  // معلومات عنا
  static Future<InstructionStepModel> getAboutUsInfo() async {
    const fallback = InstructionStepModel(
      id: 'about_us',
      title: 'معلومات عنا - كلية الغد المشرق',
      subtitle: 'صرح أكاديمي متميز في العلوم الطبية والتطبيقية',
      steps: [
        'تأسست كلية الغد المشرق للعلوم الطبية والتطبيقية بهدف تقديم تعليم جامعي متميز يواكب أعلى معايير الجودة الأكاديمية.',
        'تسعى الكلية لرفد المجتمع بالكوادر الطبية والتطبيقية المؤهلة والمدربة وفق أحدث المناهج والمعامل التخصصية.',
        'تضم الكلية نخبة من أفضل الكوادر الأكاديمية والأطباء الاستشاريين ذوي الخبرة الطويلة.',
        'توفر الكلية بيئة تعليمية محفزة ومختبرات مجهزة بأحدث التقنيات الطبية والسريرية.',
      ],
      note: 'عنوان الكلية: الجمهورية اليمنية - صنعاء - شارع 60.',
    );
    return getInstructionFromSupabase('معلومات عنا', fallback);
  }

  // المساعدة والدعم
  static Future<InstructionStepModel> getHelpAndSupportInfo() async {
    final phone = await getCollegeContactPhone();
    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
    final fallback = InstructionStepModel(
      id: 'help_support',
      title: 'المساعدة والدعم الفني',
      subtitle: 'نحن هنا لمساعدتك والإجابة على جميع استفساراتك',
      steps: [
        'في حال وجود أي مشكلة تقنية في التطبيق يمكنك التواصل المباشر مع فريق الدعم الفني.',
        'للاستفسار عن الرسوم الدراسية أو كشوف الحساب يرجى التواصل مع الشؤون المالية.',
        'للمشكلات الأكاديمية أو استخراج الوثائق يرجى مراجعة إدارة التسجيل والقبول.',
      ],
      note: 'رقم الواتساب الخاص بالدعم المباشر: $cleanPhone',
      externalUrl: 'https://wa.me/$cleanPhone',
    );
    return getInstructionFromSupabase('المساعدة والدعم', fallback);
  }

  // الأحداث والتكليفات للكالندر (ميزت باللون الذهبي)
  static Future<List<CalendarEventModel>> getCalendarEvents() async {
    final now = DateTime.now();
    final defaultEvents = [
      CalendarEventModel(
        id: '1',
        date: DateTime(now.year, now.month, 12),
        title: 'بدء الامتحانات النصفية للفصل الأول',
        description: 'تبدأ امتحانات النصف الأول لجميع الأقسام والأجواء الأكاديمية بالقاعات الرسمية.',
        isHighlightedGold: true,
      ),
      CalendarEventModel(
        id: '2',
        date: DateTime(now.year, now.month, 20),
        title: 'افتتاح المعرض العلمي والتطبيقي الأول',
        description: 'معرض ابتكارات طلاب العلوم الطبية والمختبرات بحضور نخبة من الأطباء.',
        isHighlightedGold: true,
      ),
      CalendarEventModel(
        id: '3',
        date: DateTime(now.year, now.month, 28),
        title: 'آخر موعد لتقديم طلبات التضلم',
        description: 'انتهاء الفترة المحددة لاستقبال طلبات إعادة مراجعة كراسات الإجابة.',
        isHighlightedGold: true,
      ),
    ];

    try {
      final client = _supabase;
      if (client != null) {
        final res = await client
            .from('calendar_events')
            .select()
            .order('event_date', ascending: true);
        final list = res as List;
        if (list.isNotEmpty) {
          return list.map((item) {
            final dt = DateTime.tryParse(item['event_date']?.toString() ?? '') ?? now;
            return CalendarEventModel(
              id: item['id']?.toString() ?? '',
              date: dt,
              title: item['title'] ?? '',
              description: item['description'] ?? '',
              isHighlightedGold: item['is_highlighted_gold'] ?? true,
            );
          }).toList();
        }
      }
    } catch (_) {}
    return defaultEvents;
  }

  // الإنجازات (مع التوسع ورابط يوتيوب)
  static Future<List<AchievementModel>> getAchievements() async {
    const defaultAchievements = [
      AchievementModel(
        id: '1',
        title: 'حصول الكلية على الاعتماد الأكاديمي الوطني',
        date: '15 أكتوبر 2024',
        description: 'حققت كلية الغد المشرق للعلوم الطبية والتطبيقية مركز الصدارة في تطبيق معايير الجودة الوطنية واعتماد برامج الصيدلة والمختبرات رسمياً.',
        imageUrl: 'assets/images/achievement_1.png',
        youtubeUrl: 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
      ),
      AchievementModel(
        id: '2',
        title: 'تجهيز أحدث المعامل والمختبرات السريرية',
        date: '01 سبتمبر 2024',
        description: 'تم افتتـاح المجمع الجديد للمختبرات الطبية التشخيصية المجهزة بأحدث الأجهزة الألمانية المتطورة لتدريب الطلاب.',
        imageUrl: 'assets/images/achievement_2.png',
        youtubeUrl: 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
      ),
    ];

    try {
      final client = _supabase;
      if (client != null) {
        // 1. القراءة من system_instructions
        final siRes = await client
            .from('system_instructions')
            .select()
            .eq('service_key', 'achievements')
            .maybeSingle();

        if (siRes != null && siRes['steps'] != null) {
          final decoded = jsonDecode(siRes['steps'] as String);
          if (decoded is List && decoded.isNotEmpty) {
            return decoded.map((e) => AchievementModel(
              id: (e['id'] ?? '').toString(),
              title: (e['title'] ?? '').toString(),
              date: (e['date_str'] ?? e['date'] ?? '').toString(),
              description: (e['description'] ?? '').toString(),
              imageUrl: (e['image_url'] ?? '').toString(),
              youtubeUrl: e['youtube_url']?.toString(),
            )).toList();
          }
        }

        // 2. بديل: القراءة من جدول achievements
        final res = await client
            .from('achievements')
            .select()
            .order('created_at', ascending: false);
        final list = res as List;
        if (list.isNotEmpty) {
          return list.map((item) => AchievementModel(
            id: item['id']?.toString() ?? '',
            title: item['title'] ?? '',
            date: item['date_str'] ?? '',
            description: item['description'] ?? '',
            imageUrl: item['image_url'] ?? '',
            youtubeUrl: item['youtube_url'],
          )).toList();
        }
      }
    } catch (_) {}
    return defaultAchievements;
  }

  // خريجي الغد (دفعة سفراء وعظماء الغد)
  static Future<List<AlumniBatchModel>> getAlumniBatches() async {
    const defaultBatches = [
      AlumniBatchModel(
        id: '0',
        title: 'دفعة سفراء الغد',
        batchName: 'الدفعة الخامسة',
        graduatesCount: '(250 خريج)',
        bannerImagePath: 'assets/images/alumni_banner_1.png',
        magazinePdfUrl: 'assets/pdf/alumni_magazine_5.pdf',
        ceremonyYoutubeUrl: 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
      ),
      AlumniBatchModel(
        id: '1',
        title: 'دفعة عظماء الغد',
        batchName: 'الدفعة الرابعة',
        graduatesCount: '(190 خريج)',
        bannerImagePath: 'assets/images/alumni_banner_2.png',
        magazinePdfUrl: 'assets/pdf/alumni_magazine_4.pdf',
        ceremonyYoutubeUrl: 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
      ),
    ];

    try {
      final client = _supabase;
      if (client != null) {
        // 1. القراءة من system_instructions
        final siRes = await client
            .from('system_instructions')
            .select()
            .eq('service_key', 'alumni_batches')
            .maybeSingle();

        if (siRes != null && siRes['steps'] != null) {
          final decoded = jsonDecode(siRes['steps'] as String);
          if (decoded is List && decoded.isNotEmpty) {
            return decoded.map((e) => AlumniBatchModel(
              id: (e['id'] ?? '').toString(),
              title: (e['title'] ?? '').toString(),
              batchName: (e['batch_name'] ?? '').toString(),
              graduatesCount: (e['graduates_count'] ?? '').toString(),
              bannerImagePath: (e['banner_image_url'] ?? e['banner_image_path'] ?? '').toString(),
              magazinePdfUrl: e['magazine_pdf_url']?.toString(),
              ceremonyYoutubeUrl: e['ceremony_youtube_url']?.toString(),
            )).toList();
          }
        }

        // 2. بديل: القراءة من جدول alumni_batches
        final res = await client
            .from('alumni_batches')
            .select()
            .order('created_at', ascending: false);
        final list = res as List;
        if (list.isNotEmpty) {
          return list.map((item) => AlumniBatchModel(
            id: item['id']?.toString() ?? '',
            title: item['title'] ?? '',
            batchName: item['batch_name'] ?? '',
            graduatesCount: item['graduates_count'] ?? '',
            bannerImagePath: item['banner_image_url'] ?? '',
            magazinePdfUrl: item['magazine_pdf_url'] ?? '',
            ceremonyYoutubeUrl: item['ceremony_youtube_url'],
          )).toList();
        }
      }
    } catch (_) {}
    return defaultBatches;
  }

  // إشعارات المالية
  static Future<List<FinanceNotificationModel>> getFinanceNotifications({String? academicId}) async {
    const defaultFinance = [
      FinanceNotificationModel(
        id: '1',
        title: 'إشعار سداد القسط الثاني من الرسوم الدراسية',
        date: '2024/10/05',
        details: 'يرجى مراجعة الخزينة أو السداد عبر الحساب البنكي المعتمد قبل تاريخ 2024/10/25 لتجنب الغرامات.',
        amount: 150000.0,
      ),
      FinanceNotificationModel(
        id: '2',
        title: 'تأكيد استلام سند رسم التسجيل والبطاقة الجامعية',
        date: '2024/09/15',
        details: 'تم قيد المبلغ وسداد رسوم البطاقة الأكاديمية بنجاح.',
        amount: 25000.0,
      ),
    ];

    try {
      final client = _supabase;
      if (client != null) {
        final session = await AuthService.getSavedSession();
        final effectiveId = (academicId != null && academicId.trim().isNotEmpty)
            ? AuthService.normalizeDigits(academicId.trim())
            : session?.academicId.trim();

        List? rawList;
        if (session?.sessionToken != null && session!.sessionToken!.isNotEmpty) {
          try {
            final rpcRes = await client.rpc(
              'app_get_finance',
              params: {'p_token': session.sessionToken},
            );
            if (rpcRes is List) rawList = rpcRes;
          } catch (_) {}
        }

        if (rawList == null) {
          var query = client.from('finance_notifications').select();
          if (effectiveId != null && effectiveId.isNotEmpty) {
            query = query.or('academic_id.eq.$effectiveId,academic_id.is.null');
          } else {
            query = query.filter('academic_id', 'is', null);
          }
          final res = await query.order('created_at', ascending: false);
          rawList = res as List;
        }

        final list = rawList;
        if (list.isNotEmpty) {
          return list.map((item) => FinanceNotificationModel(
            id: item['id']?.toString() ?? '',
            title: item['title'] ?? '',
            date: item['date_str'] ?? '',
            details: item['details'] ?? '',
            amount: (item['amount'] as num?)?.toDouble() ?? 0.0,
          )).toList();
        }
      }
    } catch (_) {}
    return defaultFinance;
  }
}
