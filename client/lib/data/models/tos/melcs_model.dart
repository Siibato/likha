class MelcEntryModel {
  final int id;
  final String subject;
  final String gradeLevel;
  final int? quarter;
  final String competencyCode;
  final String competencyText;
  final String? domain;

  const MelcEntryModel({
    required this.id,
    required this.subject,
    required this.gradeLevel,
    this.quarter,
    required this.competencyCode,
    required this.competencyText,
    this.domain,
  });

  factory MelcEntryModel.fromJson(Map<String, dynamic> json) {
    return MelcEntryModel(
      id: json['id'] as int,
      subject: json['subject'] as String,
      gradeLevel: json['grade_level'] as String,
      quarter: json['quarter'] as int?,
      competencyCode: json['competency_code'] as String,
      competencyText: json['competency_text'] as String,
      domain: json['domain'] as String?,
    );
  }
}
