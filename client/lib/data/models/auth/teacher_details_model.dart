import 'package:likha/domain/auth/entities/teacher_details.dart';

class TeacherDetailsModel extends TeacherDetails {
  const TeacherDetailsModel({
    required super.id,
    required super.userId,
    super.licenseId,
    super.rank,
    super.position,
    super.sex,
    super.birthdate,
    super.homeAddress,
    super.dateHired,
    super.educationLevel,
    super.specialization,
    super.contactNumber,
  });

  factory TeacherDetailsModel.fromJson(Map<String, dynamic> json) {
    return TeacherDetailsModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      licenseId: json['license_id'] as String?,
      rank: json['rank'] as String?,
      position: json['position'] as String?,
      sex: json['sex'] as String?,
      birthdate: json['birthdate'] as String?,
      homeAddress: json['home_address'] as String?,
      dateHired: json['date_hired'] as String?,
      educationLevel: json['education_level'] as String?,
      specialization: json['specialization'] as String?,
      contactNumber: json['contact_number'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'license_id': licenseId,
      'rank': rank,
      'position': position,
      'sex': sex,
      'birthdate': birthdate,
      'home_address': homeAddress,
      'date_hired': dateHired,
      'education_level': educationLevel,
      'specialization': specialization,
      'contact_number': contactNumber,
    };
  }
}
