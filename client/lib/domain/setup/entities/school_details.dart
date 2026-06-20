import 'package:equatable/equatable.dart';

class SchoolDetails extends Equatable {
  final String id;
  final String schoolName;
  final String schoolRegion;
  final String schoolDivision;
  final String schoolYear;
  final String schoolCode;
  final String? schoolDistrict;
  final String? schoolHeadName;
  final String? schoolHeadPosition;

  const SchoolDetails({
    required this.id,
    required this.schoolName,
    required this.schoolRegion,
    required this.schoolDivision,
    required this.schoolYear,
    required this.schoolCode,
    this.schoolDistrict,
    this.schoolHeadName,
    this.schoolHeadPosition,
  });

  @override
  List<Object?> get props => [
        id,
        schoolName,
        schoolRegion,
        schoolDivision,
        schoolYear,
        schoolCode,
        schoolDistrict,
        schoolHeadName,
        schoolHeadPosition,
      ];
}
