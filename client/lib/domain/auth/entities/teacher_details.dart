import 'package:equatable/equatable.dart';

class TeacherDetails extends Equatable {
  final String id;
  final String userId;
  final String? licenseId;
  final String? rank;
  final String? position;
  final String? sex;
  final String? birthdate;
  final String? homeAddress;
  final String? dateHired;
  final String? educationLevel;
  final String? specialization;
  final String? contactNumber;

  const TeacherDetails({
    required this.id,
    required this.userId,
    this.licenseId,
    this.rank,
    this.position,
    this.sex,
    this.birthdate,
    this.homeAddress,
    this.dateHired,
    this.educationLevel,
    this.specialization,
    this.contactNumber,
  });

  @override
  List<Object?> get props => [id];
}
