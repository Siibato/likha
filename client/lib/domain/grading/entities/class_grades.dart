import 'package:likha/domain/grading/entities/grade_config.dart';
import 'package:likha/domain/grading/entities/grade_item.dart';
import 'package:likha/domain/grading/entities/grade_score.dart';

class ClassGrades {
  final String classId;
  final int gradingPeriodNumber;
  final List<GradeItem> items;
  final Map<String, List<GradeScore>> scoresByItem;
  final GradeConfig? config;
  final List<Map<String, dynamic>>? summary;

  const ClassGrades({
    required this.classId,
    required this.gradingPeriodNumber,
    required this.items,
    required this.scoresByItem,
    this.config,
    this.summary,
  });

  bool get isConfigured => config != null;
}
