class InstructionStepModel {
  final String id;
  final String title;
  final String? subtitle;
  final List<String> steps;
  final String? note;
  final String? externalUrl;

  const InstructionStepModel({
    required this.id,
    required this.title,
    this.subtitle,
    required this.steps,
    this.note,
    this.externalUrl,
  });

  factory InstructionStepModel.fromJson(Map<String, dynamic> json) {
    return InstructionStepModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      subtitle: json['subtitle'],
      steps: List<String>.from(json['steps'] ?? []),
      note: json['note'],
      externalUrl: json['external_url'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'subtitle': subtitle,
        'steps': steps,
        'note': note,
        'external_url': externalUrl,
      };
}

class AcademicStaffModel {
  final String id;
  final String name;
  final String photoUrl;
  final String experienceYears;
  final String specialty;
  final String? bio;

  const AcademicStaffModel({
    required this.id,
    required this.name,
    required this.photoUrl,
    required this.experienceYears,
    required this.specialty,
    this.bio,
  });

  factory AcademicStaffModel.fromJson(Map<String, dynamic> json) {
    return AcademicStaffModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      photoUrl: json['photo_url'] ?? '',
      experienceYears: json['experience_years'] ?? '',
      specialty: json['specialty'] ?? '',
      bio: json['bio'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'photo_url': photoUrl,
        'experience_years': experienceYears,
        'specialty': specialty,
        'bio': bio,
      };
}

class ScheduleModel {
  final String id;
  final String title;
  final String type; // 'study', 'midterm', 'final'
  final String fileUrl;
  final bool isPdf;
  final String? academicYear;

  const ScheduleModel({
    required this.id,
    required this.title,
    required this.type,
    required this.fileUrl,
    this.isPdf = true,
    this.academicYear,
  });

  factory ScheduleModel.fromJson(Map<String, dynamic> json) {
    return ScheduleModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      type: json['type'] ?? 'study',
      fileUrl: json['file_url'] ?? '',
      isPdf: json['is_pdf'] ?? true,
      academicYear: json['academic_year'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'type': type,
        'file_url': fileUrl,
        'is_pdf': isPdf,
        'academic_year': academicYear,
      };
}

class SeatingNumberModel {
  final String academicId;
  final String studentName;
  final String specialty;
  final String term;
  final String hall;
  final String seatingNumber;

  const SeatingNumberModel({
    required this.academicId,
    required this.studentName,
    required this.specialty,
    required this.term,
    required this.hall,
    required this.seatingNumber,
  });

  factory SeatingNumberModel.fromJson(Map<String, dynamic> json) {
    return SeatingNumberModel(
      academicId: json['academic_id'] ?? '',
      studentName: json['student_name'] ?? '',
      specialty: json['specialty'] ?? '',
      term: json['term'] ?? '',
      hall: json['hall'] ?? '',
      seatingNumber: json['seating_number'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'academic_id': academicId,
        'student_name': studentName,
        'specialty': specialty,
        'term': term,
        'hall': hall,
        'seating_number': seatingNumber,
      };
}

class TopStudentModel {
  final int rank;
  final String studentName;
  final String specialty;
  final double gpa;
  final String batch;

  const TopStudentModel({
    required this.rank,
    required this.studentName,
    required this.specialty,
    required this.gpa,
    required this.batch,
  });

  factory TopStudentModel.fromJson(Map<String, dynamic> json) {
    return TopStudentModel(
      rank: json['rank'] ?? 0,
      studentName: json['student_name'] ?? '',
      specialty: json['specialty'] ?? '',
      gpa: (json['gpa'] as num?)?.toDouble() ?? 0.0,
      batch: json['batch'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'rank': rank,
        'student_name': studentName,
        'specialty': specialty,
        'gpa': gpa,
        'batch': batch,
      };
}

class TermResultModel {
  final String termName;
  final String? academicYear;
  final Map<String, double> subjects;
  final double totalMarks;
  final double gpa;
  final String grade;

  const TermResultModel({
    required this.termName,
    this.academicYear,
    required this.subjects,
    required this.totalMarks,
    required this.gpa,
    required this.grade,
  });

  factory TermResultModel.fromJson(Map<String, dynamic> json) {
    final rawSubjects = json['subjects'] as Map<String, dynamic>? ?? {};
    final Map<String, double> parsedSubjects = {};
    rawSubjects.forEach((key, value) {
      parsedSubjects[key] = (value as num?)?.toDouble() ?? 0.0;
    });

    return TermResultModel(
      termName: json['term_name'] ?? 'نتيجة الفصل الدراسي',
      academicYear: json['academic_year'],
      subjects: parsedSubjects,
      totalMarks: (json['total_marks'] as num?)?.toDouble() ?? 0.0,
      gpa: (json['gpa'] as num?)?.toDouble() ?? 0.0,
      grade: json['grade'] ?? 'ناجح',
    );
  }

  Map<String, dynamic> toJson() => {
        'term_name': termName,
        'academic_year': academicYear,
        'subjects': subjects,
        'total_marks': totalMarks,
        'gpa': gpa,
        'grade': grade,
      };
}

class StudentResultModel {
  final String academicId;
  final String studentName;
  final String specialty;
  final String batch;
  final List<TermResultModel> terms;
  final Map<String, double> subjects;
  final double totalMarks;
  final double gpa;
  final String grade;
  final bool isWithheld;
  final String? withheldMessage;

  const StudentResultModel({
    required this.academicId,
    required this.studentName,
    required this.specialty,
    required this.batch,
    this.terms = const [],
    required this.subjects,
    required this.totalMarks,
    required this.gpa,
    required this.grade,
    this.isWithheld = false,
    this.withheldMessage,
  });

  factory StudentResultModel.fromJson(Map<String, dynamic> json) {
    final rawSubjects = json['subjects'] as Map<String, dynamic>? ?? {};
    final Map<String, double> parsedSubjects = {};
    rawSubjects.forEach((key, value) {
      parsedSubjects[key] = (value as num).toDouble();
    });

    List<TermResultModel> parsedTerms = [];
    if (json['terms'] is List) {
      parsedTerms = (json['terms'] as List)
          .map((t) => TermResultModel.fromJson(t as Map<String, dynamic>))
          .toList();
    }

    return StudentResultModel(
      academicId: json['academic_id'] ?? '',
      studentName: json['student_name'] ?? '',
      specialty: json['specialty'] ?? '',
      batch: json['batch'] ?? '',
      terms: parsedTerms,
      subjects: parsedSubjects,
      totalMarks: (json['total_marks'] as num?)?.toDouble() ?? 0.0,
      gpa: (json['gpa'] as num?)?.toDouble() ?? 0.0,
      grade: json['grade'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'academic_id': academicId,
        'student_name': studentName,
        'specialty': specialty,
        'batch': batch,
        'terms': terms.map((t) => t.toJson()).toList(),
        'subjects': subjects,
        'total_marks': totalMarks,
        'gpa': gpa,
        'grade': grade,
      };
}

class OnlineRegistrationForm {
  String firstName = '';
  String fatherName = '';
  String grandfatherName = '';
  String lastName = '';
  String nationality = 'يمني';
  String birthDate = '';
  String birthPlace = '';
  String gender = 'ذكر';
  String email = '';
  String studentPhone = '';
  String parentPhone = '';

  String certificateType = 'ثانوية عامة (علمي)';
  String seatingNumber = '';
  String gpaPercentage = '';
  String graduationYear = '2024';
  bool hasOriginalCert = false;
  bool hasTrueCopyCert = false;
  bool hasPersonalPhotos = false;
  bool hasIdCopy = false;

  String bachelorSpecialty = '';
  String diplomaSpecialty = '';
  bool acceptedDeclaration = false;

  bool get isStep1Valid {
    return firstName.trim().isNotEmpty &&
        fatherName.trim().isNotEmpty &&
        grandfatherName.trim().isNotEmpty &&
        lastName.trim().isNotEmpty &&
        birthDate.trim().isNotEmpty &&
        birthPlace.trim().isNotEmpty &&
        email.trim().isNotEmpty &&
        studentPhone.trim().isNotEmpty &&
        parentPhone.trim().isNotEmpty;
  }

  bool get isStep2Valid {
    return seatingNumber.trim().isNotEmpty && gpaPercentage.trim().isNotEmpty;
  }

  bool get isStep3Valid {
    return (bachelorSpecialty.isNotEmpty || diplomaSpecialty.isNotEmpty) &&
        acceptedDeclaration;
  }

  bool get isFormComplete => isStep1Valid && isStep2Valid && isStep3Valid;
}

// ═══════════════════════════════════════════════
// النماذج الجديدة المضافة بحسب متطلبات المستخدم
// ═══════════════════════════════════════════════

class StudentProfileModel {
  final String academicId;
  final String fullName;
  final String password;
  final String email;
  final String specialty;
  final String level;
  final String batch;
  final String semester;
  final String group;
  final String studyShift;
  final bool isPermanentlyBlocked;
  final String? sessionToken;

  const StudentProfileModel({
    required this.academicId,
    required this.fullName,
    required this.password,
    required this.email,
    required this.specialty,
    required this.level,
    required this.batch,
    required this.semester,
    required this.group,
    required this.studyShift,
    this.isPermanentlyBlocked = false,
    this.sessionToken,
  });

  /// حساب المستوى الدراسي تلقائياً بناءً على الفصل الحالي للطالب في قاعدة البيانات
  static String resolveAcademicLevel(String? semester, [String? fallbackLevel]) {
    final rawSem = (semester ?? '').trim();
    final rawLvl = (fallbackLevel ?? '').trim();

    // 1. فصل الخريجين -> خريج
    if (rawSem.contains('خريج') || rawLvl.contains('خريج')) {
      return 'خريج';
    }

    // 2. فحص الكلمات العربية الصريحة للفصل الدراسي أولاً (لتجنب التداخل مع سنوات مثل 2021/2020)
    if (rawSem.contains('سابع') || rawSem.contains('السابع') || rawSem.contains('ثامن') || rawSem.contains('الثامن')) {
      return 'المستوى الرابع';
    }
    if (rawSem.contains('خامس') || rawSem.contains('الخامس') || rawSem.contains('سادس') || rawSem.contains('السادس')) {
      return 'المستوى الثالث';
    }
    if (rawSem.contains('ثالث') || rawSem.contains('الثالث') || rawSem.contains('رابع') || rawSem.contains('الرابع')) {
      return 'المستوى الثاني';
    }
    if (rawSem.contains('أول') || rawSem.contains('اول') || rawSem.contains('الأول') || rawSem.contains('الاول') ||
        rawSem.contains('ثاني') || rawSem.contains('الثاني')) {
      return 'المستوى الأول';
    }

    // 3. في حال كان اسم الفصل مكتوباً بالأرقام (مثل: "فصل 3" أو "ف4")، نحذف السنوات الدراسية والأقواس أولاً
    final cleanedNumbers = rawSem
        .replaceAll(RegExp(r'\d{4}\s*[/\-]\s*\d{4}'), '')
        .replaceAll(RegExp(r'\b20\d{2}\b'), '')
        .replaceAll(RegExp(r'\(\s*\d+\s*\)'), '');

    if (RegExp(r'(?:^|\D)[78](?:\D|$)').hasMatch(cleanedNumbers)) {
      return 'المستوى الرابع';
    }
    if (RegExp(r'(?:^|\D)[56](?:\D|$)').hasMatch(cleanedNumbers)) {
      return 'المستوى الثالث';
    }
    if (RegExp(r'(?:^|\D)[34](?:\D|$)').hasMatch(cleanedNumbers)) {
      return 'المستوى الثاني';
    }
    if (RegExp(r'(?:^|\D)[12](?:\D|$)').hasMatch(cleanedNumbers)) {
      return 'المستوى الأول';
    }

    // 4. الرجوع إلى المستوى المحفوظ إن وُجد
    if (rawLvl.contains('رابع') || rawLvl.contains('الرابع')) return 'المستوى الرابع';
    if (rawLvl.contains('ثالث') || rawLvl.contains('الثالث')) return 'المستوى الثالث';
    if (rawLvl.contains('ثاني') || rawLvl.contains('الثاني')) return 'المستوى الثاني';
    if (rawLvl.contains('أول') || rawLvl.contains('اول') || rawLvl.contains('الأول') || rawLvl.contains('الاول')) {
      return 'المستوى الأول';
    }
    if (rawLvl.isNotEmpty) return rawLvl;

    return 'المستوى الأول';
  }

  factory StudentProfileModel.fromJson(Map<String, dynamic> json) {
    final sem = json['semester']?.toString() ?? 'الفصل الأول';
    final rawLvl = json['level']?.toString();
    return StudentProfileModel(
      academicId: json['academic_id']?.toString() ?? '',
      fullName: json['full_name'] ?? '',
      password: '',
      email: json['email'] ?? '',
      specialty: json['specialty'] ?? '',
      level: resolveAcademicLevel(sem, rawLvl),
      batch: json['batch'] ?? 'الدفعة الخامسة',
      semester: sem,
      group: json['group'] ?? json['group_name'] ?? 'المجموعة الأولى',
      studyShift: json['study_shift'] ?? 'الفترة الصباحية',
      isPermanentlyBlocked: json['is_permanently_blocked'] ?? json['is_blocked'] ?? false,
      sessionToken: json['session_token']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'academic_id': academicId,
        'full_name': fullName,
        'email': email,
        'specialty': specialty,
        'level': level,
        'batch': batch,
        'semester': semester,
        'group': group,
        'study_shift': studyShift,
        'is_permanently_blocked': isPermanentlyBlocked,
        if (sessionToken != null) 'session_token': sessionToken,
      };

  StudentProfileModel copyWith({
    String? academicId,
    String? fullName,
    String? password,
    String? email,
    String? specialty,
    String? level,
    String? batch,
    String? semester,
    String? group,
    String? studyShift,
    bool? isPermanentlyBlocked,
    String? sessionToken,
  }) {
    return StudentProfileModel(
      academicId: academicId ?? this.academicId,
      fullName: fullName ?? this.fullName,
      password: password ?? this.password,
      email: email ?? this.email,
      specialty: specialty ?? this.specialty,
      level: level ?? this.level,
      batch: batch ?? this.batch,
      semester: semester ?? this.semester,
      group: group ?? this.group,
      studyShift: studyShift ?? this.studyShift,
      isPermanentlyBlocked: isPermanentlyBlocked ?? this.isPermanentlyBlocked,
      sessionToken: sessionToken ?? this.sessionToken,
    );
  }
}

class CalendarEventModel {
  final String id;
  final DateTime date;
  final String title;
  final String description;
  final bool isHighlightedGold;

  const CalendarEventModel({
    required this.id,
    required this.date,
    required this.title,
    required this.description,
    this.isHighlightedGold = true,
  });

  factory CalendarEventModel.fromJson(Map<String, dynamic> json) {
    return CalendarEventModel(
      id: json['id'] ?? '',
      date: DateTime.parse(json['date']),
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      isHighlightedGold: json['is_highlighted_gold'] ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date.toIso8601String(),
        'title': title,
        'description': description,
        'is_highlighted_gold': isHighlightedGold,
      };
}

class SocialMediaLinkModel {
  final String id;
  final String platformName;
  final String url;
  final String iconPath;

  const SocialMediaLinkModel({
    required this.id,
    required this.platformName,
    required this.url,
    required this.iconPath,
  });

  factory SocialMediaLinkModel.fromJson(Map<String, dynamic> json) {
    return SocialMediaLinkModel(
      id: json['id'] ?? '',
      platformName: json['platform_name'] ?? '',
      url: json['url'] ?? '',
      iconPath: json['icon_path'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'platform_name': platformName,
        'url': url,
        'icon_path': iconPath,
      };
}

class AchievementModel {
  final String id;
  final String title;
  final String date;
  final String description;
  final String imageUrl;
  final String? youtubeUrl;

  const AchievementModel({
    required this.id,
    required this.title,
    required this.date,
    required this.description,
    required this.imageUrl,
    this.youtubeUrl,
  });

  factory AchievementModel.fromJson(Map<String, dynamic> json) {
    return AchievementModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      date: json['date'] ?? '',
      description: json['description'] ?? '',
      imageUrl: json['image_url'] ?? '',
      youtubeUrl: json['youtube_url'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'date': date,
        'description': description,
        'image_url': imageUrl,
        'youtube_url': youtubeUrl,
      };
}

class AlumniBatchModel {
  final String id;
  final String title;
  final String batchName;
  final String graduatesCount;
  final String bannerImagePath;
  final String? magazinePdfUrl;
  final String? ceremonyYoutubeUrl;

  const AlumniBatchModel({
    required this.id,
    required this.title,
    required this.batchName,
    required this.graduatesCount,
    required this.bannerImagePath,
    this.magazinePdfUrl,
    this.ceremonyYoutubeUrl,
  });

  factory AlumniBatchModel.fromJson(Map<String, dynamic> json) {
    return AlumniBatchModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      batchName: json['batch_name'] ?? '',
      graduatesCount: json['graduates_count'] ?? '',
      bannerImagePath: json['banner_image_path'] ?? '',
      magazinePdfUrl: json['magazine_pdf_url'],
      ceremonyYoutubeUrl: json['ceremony_youtube_url'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'batch_name': batchName,
        'graduates_count': graduatesCount,
        'banner_image_path': bannerImagePath,
        'magazine_pdf_url': magazinePdfUrl,
        'ceremony_youtube_url': ceremonyYoutubeUrl,
      };
}

class FinanceNotificationModel {
  final String id;
  final String title;
  final String date;
  final String details;
  final double? amount;

  const FinanceNotificationModel({
    required this.id,
    required this.title,
    required this.date,
    required this.details,
    this.amount,
  });

  factory FinanceNotificationModel.fromJson(Map<String, dynamic> json) {
    return FinanceNotificationModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      date: json['date'] ?? '',
      details: json['details'] ?? '',
      amount: (json['amount'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'date': date,
        'details': details,
        'amount': amount,
      };
}
