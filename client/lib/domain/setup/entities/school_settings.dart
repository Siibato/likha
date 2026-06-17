import 'package:equatable/equatable.dart';

class SchoolSettings extends Equatable {
  final String id;
  final String schoolName;
  final String schoolRegion;
  final String schoolDivision;
  final String schoolYear;
  final String schoolCode;

  const SchoolSettings({
    required this.id,
    required this.schoolName,
    required this.schoolRegion,
    required this.schoolDivision,
    required this.schoolYear,
    required this.schoolCode,
  });

  @override
  List<Object> get props => [
        id,
        schoolName,
        schoolRegion,
        schoolDivision,
        schoolYear,
        schoolCode,
      ];
}
