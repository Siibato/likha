import 'package:flutter/material.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/domain/classes/entities/class_detail.dart';

class StudentDataTable extends StatelessWidget {
  final List<Participant> students;
  final ValueChanged<Participant>? onTap;

  const StudentDataTable({
    super.key,
    required this.students,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (students.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(48),
          child: Column(
            children: [
              Icon(Icons.people_outline_rounded,
                  size: 48, color: AppColors.borderLight),
              SizedBox(height: 12),
              Text(
                'No students enrolled',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: AppColors.foregroundTertiary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final sorted = List<Participant>.from(students)
      ..sort((a, b) => a.student.fullName
          .toLowerCase()
          .compareTo(b.student.fullName.toLowerCase()));

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: DataTable(
          headingRowColor:
              WidgetStateProperty.all(AppColors.backgroundTertiary),
          dataRowMaxHeight: 56,
          horizontalMargin: 20,
          columnSpacing: 24,
          showCheckboxColumn: false,
          columns: const [
            DataColumn(label: Text('Student', style: _headerStyle)),
            DataColumn(label: Text('Username', style: _headerStyle)),
            DataColumn(label: Text('Joined', style: _headerStyle)),
          ],
          rows: sorted.map((participant) {
            return DataRow(
              onSelectChanged:
                  onTap != null ? (_) => onTap!(participant) : null,
              cells: [
                DataCell(
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.backgroundTertiary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          participant.student.fullName.isNotEmpty
                              ? participant.student.fullName[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.foregroundPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        participant.student.fullName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.foregroundDark,
                        ),
                      ),
                    ],
                  ),
                ),
                DataCell(Text(
                  participant.student.username,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.foregroundSecondary,
                  ),
                )),
                DataCell(Text(
                  _formatDate(participant.joinedAt),
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.foregroundTertiary,
                  ),
                )),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  static const _headerStyle = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w700,
    color: AppColors.foregroundSecondary,
  );
}
