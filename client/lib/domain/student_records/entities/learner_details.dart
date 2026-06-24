import 'package:equatable/equatable.dart';

class LearnerDetails extends Equatable {
  final String id;
  final String userId;
  final String? lrn;
  final String? sex;
  final int? age;
  final String? trackStrand;
  final String? curriculum;
  final String? birthdate;
  final String? birthplace;
  final String? homeAddress;
  final String? fatherName;
  final String? fatherContact;
  final String? motherName;
  final String? motherContact;
  final String? guardianName;
  final String? guardianContact;
  final String? dateAdmitted;

  const LearnerDetails({
    required this.id,
    required this.userId,
    this.lrn,
    this.sex,
    this.age,
    this.trackStrand,
    this.curriculum,
    this.birthdate,
    this.birthplace,
    this.homeAddress,
    this.fatherName,
    this.fatherContact,
    this.motherName,
    this.motherContact,
    this.guardianName,
    this.guardianContact,
    this.dateAdmitted,
  });

  @override
  List<Object?> get props => [id];
}
