import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/domain/assignments/entities/assignment.dart';
import 'package:likha/presentation/providers/assignment_provider.dart';
import 'package:likha/presentation/widgets/shared/dialogs/app_dialogs.dart';

/// Popup menu for assignment actions (publish / unpublish / delete).
class AssignmentActionsMenu extends ConsumerWidget {
  final Assignment assignment;
  final String assignmentId;

  const AssignmentActionsMenu({
    super.key,
    required this.assignment,
    required this.assignmentId,
  });

  void _confirmPublish(BuildContext context, WidgetRef ref) {
    AppDialogs.showConfirmation(
      context: context,
      title: 'Publish Assignment',
      body:
          'Publish "${assignment.title}"? Students will be able to see and submit to this assignment.',
      confirmLabel: 'Publish',
      onConfirm: () => ref
          .read(assignmentProvider.notifier)
          .publishAssignment(assignmentId),
    );
  }

  void _confirmUnpublish(BuildContext context, WidgetRef ref) {
    AppDialogs.showDestructive(
      context: context,
      title: 'Move to Draft',
      body:
          'Move "${assignment.title}" back to draft? Students will no longer be able to access it.',
      confirmLabel: 'Move to Draft',
      onConfirm: () => ref
          .read(assignmentProvider.notifier)
          .unpublishAssignment(assignmentId),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    AppDialogs.showDestructive(
      context: context,
      title: 'Delete Assignment',
      body: 'Delete "${assignment.title}"? This cannot be undone.',
      confirmLabel: 'Delete',
      onConfirm: () => ref
          .read(assignmentProvider.notifier)
          .deleteAssignment(assignmentId),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert_rounded,
          color: AppColors.foregroundDark),
      onSelected: (value) {
        switch (value) {
          case 'publish':
            _confirmPublish(context, ref);
            break;
          case 'unpublish':
            _confirmUnpublish(context, ref);
            break;
          case 'delete':
            _confirmDelete(context, ref);
            break;
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: assignment.isPublished ? 'unpublish' : 'publish',
          child: Row(
            children: [
              Icon(
                assignment.isPublished
                    ? Icons.unpublished_rounded
                    : Icons.publish_rounded,
                size: 18,
                color: AppColors.foregroundSecondary,
              ),
              const SizedBox(width: 12),
              Text(assignment.isPublished ? 'Unpublish' : 'Publish'),
            ],
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete_rounded,
                  size: 18, color: AppColors.semanticError),
              SizedBox(width: 12),
              Text('Delete',
                  style: TextStyle(color: AppColors.semanticError)),
            ],
          ),
        ),
      ],
    );
  }
}
