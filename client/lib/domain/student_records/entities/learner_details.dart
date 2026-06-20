import 'package:equatable/equatable.dart';

class LearnerDetails extends Equatable {
  final String id;
  final String userId;
  final String? lrn;
  final int? age;
  final String? sex;
  final String? trackStrand;
  final String? curriculum;
  final String? birthdate;
  final String? birthplace;
  final String? homeAddress;
  final String? fatherName;
  final String? motherName;
  final String? guardianName;
  final String? guardianContact;
  final String? dateAdmitted;
  final String? admittedToGrade;

  const LearnerDetails({
    required this.id,
    required this.userId,
    this.lrn,
    this.age,
    this.sex,
    this.trackStrand,
    this.curriculum,
    this.birthdate,
    this.birthplace,
    this.homeAddress,
    this.fatherName,
    this.motherName,
    this.guardianName,
    this.guardianContact,
    this.dateAdmitted,
    this.admittedToGrade,
  });

  @override
  List<Object?> get props => [id];
}
