import '../models/app_models.dart';

class DataService {
  // 1. التسجيل في مقر الكلية
  static Future<InstructionStepModel> getCampusRegistrationInfo() async {
    return const InstructionStepModel(
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
  }

  // التسجيل عبر بوابة الوزارة
  static Future<InstructionStepModel> getMinistryPortalInfo() async {
    return const InstructionStepModel(
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
  }

  // 2. الكادر الأكاديمي والتدريس
  static Future<List<AcademicStaffModel>> getAcademicStaff() async {
    return const [
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
  }

  // التدريب الميداني
  static Future<InstructionStepModel> getFieldTrainingInfo() async {
    return const InstructionStepModel(
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
  }

  // 3. الجداول الدراسية وجداول الامتحانات
  static Future<List<ScheduleModel>> getSchedules(String type) async {
    return [
      ScheduleModel(
        id: '1',
        title: type == 'study'
            ? 'جدول المحاضرات الدراسية - الفصل الأول 2024-2025'
            : (type == 'midterm' ? 'جدول امتحانات النصف الأول' : 'جدول امتحانات النهائي'),
        type: type,
        fileUrl: 'assets/pdf/schedule_sample.pdf',
        academicYear: '2024 - 2025',
      ),
      ScheduleModel(
        id: '2',
        title: type == 'study'
            ? 'جدول المختبرات والمعامل التطبيقية'
            : (type == 'midterm' ? 'جدول الامتحانات العملي للنصف' : 'جدول الامتحانات العملي النهائي'),
        type: type,
        fileUrl: 'assets/pdf/schedule_labs.pdf',
        academicYear: '2024 - 2025',
      ),
    ];
  }

  // تعليمات خدمات شؤون الطلاب الديناميكية
  static Future<InstructionStepModel> getStudentAffairsServiceInfo(String title) async {
    switch (title) {
      case 'الأنشطة والفعاليات':
        return const InstructionStepModel(
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

      case 'تقديم طلب تحويل (من تخصص إلى تخصص آخر)':
        return const InstructionStepModel(
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

      case 'تقديم طلب وقف قيد':
        return const InstructionStepModel(
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

      case 'تقديم طلب فتح قيد':
        return const InstructionStepModel(
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

      case 'تقديم طلب مقاصصة':
        return const InstructionStepModel(
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

      case 'تقديم طلب تجميد ملف':
        return const InstructionStepModel(
          id: 'freeze_file',
          title: 'تقديم طلب تجميد ملف',
          subtitle: 'تجميد الملف الأكاديمي مؤقتاً',
          steps: [
            'تعبئة نموذج طلب التجميد مع بيان أسباب التجميد.',
            'استكمال إخلاء الطرف من المكتبة والمعامل والشؤون المالية.',
            'اعتماد طلب التجميد من إدارة التسجيل والقبول.',
          ],
        );

      case 'تقديم طلب سحب ملف':
        return const InstructionStepModel(
          id: 'withdraw_file',
          title: 'تقديم طلب سحب ملف',
          subtitle: 'السحب النهائي للوثائق من الكلية',
          steps: [
            'تقديم استمارة سحب الملف النهائية من الطالب أو ولي أمره بموجب توكيل رسمي.',
            'استكمال إخلاء الطرف التام من كافة أقسام وإدارات الكلية.',
            'تسليم البطاقة الجامعية واستلام أصول الوثائق الشخصية والدراسية.',
          ],
        );

      case 'تقديم طلب استخراج إفادة تخرج':
        return const InstructionStepModel(
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

      case 'تقديم طلب استخراج شهادة (دبلوم/بكالوريوس)':
        return const InstructionStepModel(
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

      case 'تقديم طلب استخراج الوثائق اللازمة للتقديم على مزاولة المهنة':
        return const InstructionStepModel(
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

      case 'تقديم طلب تظلم':
        return const InstructionStepModel(
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

      default:
        return InstructionStepModel(
          id: 'general',
          title: title,
          steps: const [
            'تعبئة الطلب المخصص للخدمة.',
            'مراجعة الإدارة المختصة بالكلية.',
            'استكمال الإجراءات والرسوم المحددة.',
          ],
        );
    }
  }

  // 4. الكنترول - أرقام الجلوس
  static Future<SeatingNumberModel?> searchSeatingNumber(String academicId) async {
    return SeatingNumberModel(
      academicId: academicId.isEmpty ? '2024000001' : academicId,
      studentName: 'عبد الله أحمد الطالب',
      specialty: 'علوم مختبرات طبية - المستوى الثاني',
      term: 'الفصل الدراسي الأول 2024/2025',
      hall: 'قاعة الأمل - الدور الثاني (قاعة رقم 4)',
      seatingNumber: '10482',
    );
  }

  // أوائل الطلاب
  static Future<List<TopStudentModel>> getTopStudents() async {
    return const [
      TopStudentModel(rank: 1, studentName: 'أحمد صالح عبد الرحمن', specialty: 'طب وجراحة', gpa: 98.5, batch: 'دفعة سفراء الغد'),
      TopStudentModel(rank: 2, studentName: 'مريم علي حسن القاضي', specialty: 'صيدلة سريرية', gpa: 97.8, batch: 'دفعة سفراء الغد'),
      TopStudentModel(rank: 3, studentName: 'خالد عمر باحاج', specialty: 'علوم مختبرات', gpa: 96.9, batch: 'دفعة سفراء الغد'),
      TopStudentModel(rank: 4, studentName: 'فاطمة محمد ناصر', specialty: 'تمريض عالي', gpa: 95.7, batch: 'دفعة عظماء الغد'),
      TopStudentModel(rank: 5, studentName: 'سعيد عبد الله العمري', specialty: 'صيدلة دبلوم', gpa: 94.8, batch: 'دفعة عظماء الغد'),
    ];
  }

  // النتائج
  static Future<StudentResultModel?> getStudentResults(String academicId) async {
    return StudentResultModel(
      academicId: academicId.isEmpty ? '2024000001' : academicId,
      studentName: 'عبد الله أحمد الطالب',
      specialty: 'علوم مختبرات طبية',
      batch: 'الدفعة الخامسة',
      subjects: const {
        'علم الأحياء الدقيقة (Microbiology)': 92.0,
        'الكيمياء الحيوية (Biochemistry)': 88.5,
        'علم الدم التشخيصي (Hematology)': 95.0,
        'علم النسيج المرضي (Histopathology)': 90.0,
        'علم الأنسجة والأجسام المضادة': 94.0,
      },
      totalMarks: 459.5,
      gpa: 91.9,
      grade: 'ممتاز مع مرتبة الشرف',
    );
  }

  // ═══════════════════════════════════════════════
  // البيانات الجديدة للبروفايل، الكالندر، التواصل، المالية والإنجازات
  // ═══════════════════════════════════════════════

  // دليل الطالب الجامعي
  static Future<String> getUniversityGuidePdfUrl() async {
    return 'assets/pdf/university_student_guide.pdf';
  }

  // روابط التواصل الاجتماعي
  static Future<List<SocialMediaLinkModel>> getSocialMediaLinks() async {
    return const [
      SocialMediaLinkModel(id: '1', platformName: 'صفحتنا على فيسبوك', url: 'https://facebook.com/alghadcollege', iconPath: 'assets/icons/facebook.png'),
      SocialMediaLinkModel(id: '2', platformName: 'قناتنا على تليجرام', url: 'https://t.me/alghadcollege', iconPath: 'assets/icons/telegram.png'),
      SocialMediaLinkModel(id: '3', platformName: 'قناتنا على يوتيوب', url: 'https://youtube.com/@alghadcollege', iconPath: 'assets/icons/youtube.png'),
      SocialMediaLinkModel(id: '4', platformName: 'تواصل معنا على الواتساب', url: 'https://wa.me/967776166321', iconPath: 'assets/icons/whatsapp.png'),
      SocialMediaLinkModel(id: '5', platformName: 'الموقع الإلكتروني الرسمي', url: 'https://alghad-college.edu.ye', iconPath: 'assets/icons/website.png'),
    ];
  }

  // معلومات عنا
  static Future<InstructionStepModel> getAboutUsInfo() async {
    return const InstructionStepModel(
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
  }

  // المساعدة والدعم
  static Future<InstructionStepModel> getHelpAndSupportInfo() async {
    return const InstructionStepModel(
      id: 'help_support',
      title: 'المساعدة والدعم الفني',
      subtitle: 'نحن هنا لمساعدتك والإجابة على جميع استفساراتك',
      steps: [
        'في حال وجود أي مشكلة تقنية في التطبيق يمكنك التواصل المباشر مع فريق الدعم الفني.',
        'للاستفسار عن الرسوم الدراسية أو كشوف الحساب يرجى التواصل مع الشؤون المالية.',
        'للمشكلات الأكاديمية أو استخراج الوثائق يرجى مراجعة إدارة التسجيل والقبول.',
      ],
      note: 'رقم الواتساب الخاص بالدعم المباشر: 967776166321',
      externalUrl: 'https://wa.me/967776166321',
    );
  }

  // الأحداث والتكليفات للكالندر (ميزت باللون الذهبي)
  static Future<List<CalendarEventModel>> getCalendarEvents() async {
    final now = DateTime.now();
    return [
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
  }

  // الإنجازات (مع التوسع ورابط يوتيوب)
  static Future<List<AchievementModel>> getAchievements() async {
    return const [
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
  }

  // خريجي الغد (دفعة سفراء وعظماء الغد)
  static Future<List<AlumniBatchModel>> getAlumniBatches() async {
    return const [
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
  }

  // إشعارات المالية
  static Future<List<FinanceNotificationModel>> getFinanceNotifications() async {
    return const [
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
  }
}
