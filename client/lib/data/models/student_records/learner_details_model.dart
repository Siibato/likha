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
    super.fatherContact,
    super.motherName,
    super.motherContact,
    super.guardianName,
    super.guardianContact,
    super.dateAdmitted,
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
      fatherContact: json['father_contact'] as String?,
      motherName: json['mother_name'] as String?,
      motherContact: json['mother_contact'] as String?,
      guardianName: json['guardian_name'] as String?,
      guardianContact: json['guardian_contact'] as String?,
      dateAdmitted: json['date_admitted'] as String?,
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
      'father_contact': fatherContact,
      'mother_name': motherName,
      'mother_contact': motherContact,
      'guardian_name': guardianName,
      'guardian_contact': guardianContact,
      'date_admitted': dateAdmitted,
    };
  }
}
