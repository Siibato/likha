import 'package:likha/domain/student_records/entities/sf10_response.dart';

class Sf10ResponseModel extends Sf10Response {
  const Sf10ResponseModel({
    required super.studentId,
    required super.studentName,
    super.lrn,
    super.birthdate,
    super.birthplace,
    super.homeAddress,
    super.sex,
    super.age,
    super.fatherName,
    super.motherName,
    super.guardianName,
    super.guardianContact,
    super.trackStrand,
    super.curriculum,
    super.currentSchoolYear,
    super.currentGradeLevel,
    super.currentSection,
    super.schoolHistory = const [],
    super.scholasticRecords = const [],
  });

  factory Sf10ResponseModel.fromJson(Map<String, dynamic> json) {
    return Sf10ResponseModel(
      studentId: json['student_id'] as String,
      studentName: json['student_name'] as String,
      lrn: json['lrn'] as String?,
      birthdate: json['birthdate'] as String?,
      birthplace: json['birthplace'] as String?,
      homeAddress: json['home_address'] as String?,
      sex: json['sex'] as String?,
      age: json['age'] as int?,
      fatherName: json['father_name'] as String?,
      motherName: json['mother_name'] as String?,
      guardianName: json['guardian_name'] as String?,
      guardianContact: json['guardian_contact'] as String?,
      trackStrand: json['track_strand'] as String?,
      curriculum: json['curriculum'] as String?,
      currentSchoolYear: json['current_school_year'] as String?,
      currentGradeLevel: json['current_grade_level'] as String?,
      currentSection: json['current_section'] as String?,
      schoolHistory: (json['school_history'] as List<dynamic>?)
          ?.map((e) => Sf10SchoolHistoryModel.fromJson(e as Map<String, dynamic>))
          .toList() ??
          const [],
      scholasticRecords: (json['scholastic_records'] as List<dynamic>?)
          ?.map((e) => Sf10YearRecordModel.fromJson(e as Map<String, dynamic>))
          .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() => {
    'student_id': studentId,
    'student_name': studentName,
    'lrn': lrn,
    'birthdate': birthdate,
    'birthplace': birthplace,
    'home_address': homeAddress,
    'sex': sex,
    'age': age,
    'father_name': fatherName,
    'mother_name': motherName,
    'guardian_name': guardianName,
    'guardian_contact': guardianContact,
    'track_strand': trackStrand,
    'curriculum': curriculum,
    'current_school_year': currentSchoolYear,
    'current_grade_level': currentGradeLevel,
    'current_section': currentSection,
    'school_history': schoolHistory.map((e) => (e as Sf10SchoolHistoryModel).toJson()).toList(),
    'scholastic_records': scholasticRecords.map((e) => (e as Sf10YearRecordModel).toJson()).toList(),
  };
}

class Sf10SchoolHistoryModel extends Sf10SchoolHistory {
  const Sf10SchoolHistoryModel({
    required super.id,
    required super.schoolName,
    super.schoolId,
    required super.gradeLevel,
    required super.schoolYear,
    super.section,
    super.dateFrom,
    super.dateTo,
    required super.recordType,
    super.subjects = const [],
    super.attendance = const [],
  });

  factory Sf10SchoolHistoryModel.fromJson(Map<String, dynamic> json) {
    return Sf10SchoolHistoryModel(
      id: json['id'] as String,
      schoolName: json['school_name'] as String,
      schoolId: json['school_id'] as String?,
      gradeLevel: json['grade_level'] as String,
      schoolYear: json['school_year'] as String,
      section: json['section'] as String?,
      dateFrom: json['date_from'] as String?,
      dateTo: json['date_to'] as String?,
      recordType: json['record_type'] as String,
      subjects: (json['subjects'] as List<dynamic>?)
          ?.map((e) => Sf10PreviousSubjectModel.fromJson(e as Map<String, dynamic>))
          .toList() ??
          const [],
      attendance: (json['attendance'] as List<dynamic>?)
          ?.map((e) => Sf10AttendanceMonthModel.fromJson(e as Map<String, dynamic>))
          .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'school_name': schoolName,
    'school_id': schoolId,
    'grade_level': gradeLevel,
    'school_year': schoolYear,
    'section': section,
    'date_from': dateFrom,
    'date_to': dateTo,
    'record_type': recordType,
    'subjects': subjects.map((e) => (e as Sf10PreviousSubjectModel).toJson()).toList(),
    'attendance': attendance.map((e) => (e as Sf10AttendanceMonthModel).toJson()).toList(),
  };
}

class Sf10YearRecordModel extends Sf10YearRecord {
  const Sf10YearRecordModel({
    required super.schoolYear,
    required super.gradeLevel,
    super.section,
    required super.schoolName,
    super.subjects = const [],
    super.finalAverage,
    super.descriptor,
    super.attendance = const [],
  });

  factory Sf10YearRecordModel.fromJson(Map<String, dynamic> json) {
    return Sf10YearRecordModel(
      schoolYear: json['school_year'] as String,
      gradeLevel: json['grade_level'] as String,
      section: json['section'] as String?,
      schoolName: json['school_name'] as String? ?? '',
      subjects: (json['subjects'] as List<dynamic>?)
          ?.map((e) => Sf10SubjectRowModel.fromJson(e as Map<String, dynamic>))
          .toList() ??
          const [],
      finalAverage: json['final_average'] as int?,
      descriptor: json['descriptor'] as String?,
      attendance: (json['attendance'] as List<dynamic>?)
          ?.map((e) => Sf10AttendanceMonthModel.fromJson(e as Map<String, dynamic>))
          .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() => {
    'school_year': schoolYear,
    'grade_level': gradeLevel,
    'section': section,
    'school_name': schoolName,
    'subjects': subjects.map((e) => (e as Sf10SubjectRowModel).toJson()).toList(),
    'final_average': finalAverage,
    'descriptor': descriptor,
    'attendance': attendance.map((e) => (e as Sf10AttendanceMonthModel).toJson()).toList(),
  };
}

class Sf10SubjectRowModel extends Sf10SubjectRow {
  const Sf10SubjectRowModel({
    required super.classTitle,
    super.subjectGroup,
    super.periodGrades = const [],
    super.finalGrade,
    super.descriptor,
  });

  factory Sf10SubjectRowModel.fromJson(Map<String, dynamic> json) {
    return Sf10SubjectRowModel(
      classTitle: json['class_title'] as String,
      subjectGroup: json['subject_group'] as String?,
      periodGrades: (json['period_grades'] as List<dynamic>?)
          ?.map((e) => e as int?)
          .toList() ??
          const [],
      finalGrade: json['final_grade'] as int?,
      descriptor: json['descriptor'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'class_title': classTitle,
    'subject_group': subjectGroup,
    'period_grades': periodGrades,
    'final_grade': finalGrade,
    'descriptor': descriptor,
  };
}

class Sf10PreviousSubjectModel extends Sf10PreviousSubject {
  const Sf10PreviousSubjectModel({
    required super.subjectName,
    super.subjectGroup,
    super.q1Grade,
    super.q2Grade,
    super.q3Grade,
    super.q4Grade,
    super.finalGrade,
    super.descriptor,
  });

  factory Sf10PreviousSubjectModel.fromJson(Map<String, dynamic> json) {
    return Sf10PreviousSubjectModel(
      subjectName: json['subject_name'] as String,
      subjectGroup: json['subject_group'] as String?,
      q1Grade: json['q1_grade'] as int?,
      q2Grade: json['q2_grade'] as int?,
      q3Grade: json['q3_grade'] as int?,
      q4Grade: json['q4_grade'] as int?,
      finalGrade: json['final_grade'] as int?,
      descriptor: json['descriptor'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'subject_name': subjectName,
    'subject_group': subjectGroup,
    'q1_grade': q1Grade,
    'q2_grade': q2Grade,
    'q3_grade': q3Grade,
    'q4_grade': q4Grade,
    'final_grade': finalGrade,
    'descriptor': descriptor,
  };
}

class Sf10AttendanceMonthModel extends Sf10AttendanceMonth {
  const Sf10AttendanceMonthModel({
    required super.month,
    required super.schoolDays,
    required super.daysPresent,
    required super.daysAbsent,
  });

  factory Sf10AttendanceMonthModel.fromJson(Map<String, dynamic> json) {
    return Sf10AttendanceMonthModel(
      month: json['month'] as String,
      schoolDays: json['school_days'] as int,
      daysPresent: json['days_present'] as int,
      daysAbsent: json['days_absent'] as int,
    );
  }

  Map<String, dynamic> toJson() => {
    'month': month,
    'school_days': schoolDays,
    'days_present': daysPresent,
    'days_absent': daysAbsent,
  };
}
