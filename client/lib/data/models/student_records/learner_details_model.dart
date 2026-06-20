import 'package:likha/domain/student_records/entities/learner_details.dart';

class LearnerDetailsModel extends LearnerDetails {
  const LearnerDetailsModel({
    required super.id,
    required super.userId,
    super.lrn,
    super.age,
    super.sex,
    super.trackStrand,
    super.curriculum,
    super.birthdate,
    super.birthplace,
    super.homeAddress,
    super.fatherName,
    super.motherName,
    super.guardianName,
    super.guardianContact,
    super.dateAdmitted,
    super.admittedToGrade,
  });

  factory LearnerDetailsModel.fromJson(Map<String, dynamic> json) {
    return LearnerDetailsModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      lrn: json['lrn'] as String?,
      age: json['age'] as int?,
      sex: json['sex'] as String?,
      trackStrand: json['track_strand'] as String?,
      curriculum: json['curriculum'] as String?,
      birthdate: json['birthdate'] as String?,
      birthplace: json['birthplace'] as String?,
      homeAddress: json['home_address'] as String?,
      fatherName: json['father_name'] as String?,
      motherName: json['mother_name'] as String?,
      guardianName: json['guardian_name'] as String?,
      guardianContact: json['guardian_contact'] as String?,
      dateAdmitted: json['date_admitted'] as String?,
      admittedToGrade: json['admitted_to_grade'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'lrn': lrn,
      'age': age,
      'sex': sex,
      'track_strand': trackStrand,
      'curriculum': curriculum,
      'birthdate': birthdate,
      'birthplace': birthplace,
      'home_address': homeAddress,
      'father_name': fatherName,
      'mother_name': motherName,
      'guardian_name': guardianName,
      'guardian_contact': guardianContact,
      'date_admitted': dateAdmitted,
      'admitted_to_grade': admittedToGrade,
    };
  }
}
