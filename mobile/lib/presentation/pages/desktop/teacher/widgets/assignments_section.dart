import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/presentation/pages/desktop/core/desktop_page_scaffold.dart';
import 'package:likha/presentation/pages/desktop/teacher/create_assignment_desktop.dart';
import 'package:likha/presentation/pages/desktop/teacher/assignment_detail_desktop.dart';
import 'package:likha/presentation/pages/desktop/teacher/widgets/assignment_data_table.dart';
import 'package:likha/presentation/providers/assignment_provider.dart';

/// Assignments section widget for TeacherClassDetailDesktop
/// Displays a list of assignments with create and navigation functionality
class AssignmentsSection extends ConsumerWidget {
  final String classId;

  const AssignmentsSection({
    super.key,
    required this.classId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(assignmentProvider);

    return DesktopPageScaffold(
      title: 'Assignments',
      actions: [
        FilledButton.icon(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CreateAssignmentDesktop(classId: classId),
            ),
          ).then((result) {
            if (result == true) {
              ref
                  .read(assignmentProvider.notifier)
                  .loadAssignments(classId);
            }
          }),
          icon: const Icon(Icons.add_rounded, size: 18),
          label: const Text('Create Assignment'),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.foregroundDark,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
        ),
      ],
      body: state.isLoading && state.assignments.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(
                  color: AppColors.foregroundPrimary,
                  strokeWidth: 2.5,
                ),
              ),
            )
          : AssignmentDataTable(
              assignments: state.assignments,
              onTap: (assignment) => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      AssignmentDetailDesktop(assignmentId: assignment.id),
                ),
              ).then((_) => ref
                  .read(assignmentProvider.notifier)
                  .loadAssignments(classId)),
            ),
    );
  }
}
