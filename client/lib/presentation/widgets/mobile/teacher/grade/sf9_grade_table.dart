import 'package:flutter/material.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/core/utils/grading_period_utils.dart';
import 'package:likha/domain/grading/entities/sf9.dart';

class Sf9GradeTable extends StatelessWidget {
  final List<Sf9SubjectRow> subjects;
  final Sf9PeriodAverages? generalAverage;
  final String? gradingPeriodType;

  const Sf9GradeTable({
    super.key,
    required this.subjects,
    this.generalAverage,
    this.gradingPeriodType,
  });

  @override
  Widget build(BuildContext context) {
    const nameWidth = 150.0;
    const cellWidth = 56.0;
    const fgWidth = 64.0;
    const descWidth = 80.0;
    const cellHeight = 40.0;

    final periodCount = periodCountFromType(gradingPeriodType);
    final prefix = periodLabelPrefix(gradingPeriodType);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              decoration: const BoxDecoration(
                color: AppColors.backgroundTertiary,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(11),
                  topRight: Radius.circular(11),
                ),
              ),
              child: Row(
                children: [
                  _cell('Learning Area', nameWidth, cellHeight, bold: true, align: Alignment.centerLeft),
                  ...List.generate(periodCount, (i) => _cell('$prefix${i + 1}', cellWidth, cellHeight, bold: true)),
                  _cell('Final', fgWidth, cellHeight, bold: true),
                  _cell('Remarks', descWidth, cellHeight, bold: true),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.borderLight),
            // Subject rows
            ...subjects.asMap().entries.map((entry) {
              final i = entry.key;
              final s = entry.value;
              return Container(
                color: i.isEven ? Colors.white : AppColors.backgroundSecondary,
                child: Row(
                  children: [
                    _cell(s.classTitle, nameWidth, cellHeight, align: Alignment.centerLeft),
                    ...List.generate(periodCount, (pi) => _gradeCell(
                      s.periodGrades.length > pi ? s.periodGrades[pi] : null,
                      cellWidth,
                      cellHeight,
                    )),
                    _gradeCell(s.finalGrade, fgWidth, cellHeight, bold: true),
                    _cell(_passFail(s.finalGrade), descWidth, cellHeight,
                        color: AppColors.foregroundSecondary, size: 10),
                  ],
                ),
              );
            }),
            // General Average row
            if (generalAverage != null) ...[
              const Divider(height: 1, color: AppColors.borderLight),
              Container(
                decoration: const BoxDecoration(
                  color: AppColors.borderLight,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(11),
                    bottomRight: Radius.circular(11),
                  ),
                ),
                child: Builder(
                  builder: (context) {
                    final ga = generalAverage!;
                    return Row(
                      children: [
                        _cell('General Average', nameWidth, cellHeight,
                            bold: true, align: Alignment.centerLeft),
                        ...List.generate(periodCount, (pi) => _gradeCell(
                          ga.periodGrades.length > pi ? ga.periodGrades[pi] : null,
                          cellWidth,
                          cellHeight,
                          bold: true,
                        )),
                        _gradeCell(ga.finalAverage, fgWidth, cellHeight, bold: true),
                        _cell(_passFail(ga.finalAverage), descWidth, cellHeight,
                            bold: true, size: 10),
                      ],
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _passFail(int? grade) {
    if (grade == null) return '--';
    return grade >= 75 ? 'Passed' : 'Failed';
  }

  Widget _cell(
    String text,
    double width,
    double height, {
    bool bold = false,
    Alignment align = Alignment.center,
    Color color = AppColors.accentCharcoal,
    double size = 12,
  }) {
    return SizedBox(
      width: width,
      height: height,
      child: Align(
        alignment: align,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            text,
            style: TextStyle(
              fontSize: size,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }

  Widget _gradeCell(int? grade, double width, double height, {bool bold = false}) {
    return _cell(
      grade?.toString() ?? '--',
      width,
      height,
      bold: bold,
      color: grade != null ? AppColors.accentCharcoal : AppColors.foregroundLight,
    );
  }
}
