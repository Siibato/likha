import 'package:flutter/material.dart';
import 'package:likha/core/theme/app_colors.dart';

/// "No submission required" and "Publish immediately" toggle settings.
class AssignmentPublishSettings extends StatelessWidget {
  final bool noSubmissionRequired;
  final bool isPublished;
  final bool enabled;
  final void Function(bool) onNoSubmissionChanged;
  final void Function(bool) onPublishChanged;

  const AssignmentPublishSettings({
    super.key,
    required this.noSubmissionRequired,
    required this.isPublished,
    required this.enabled,
    required this.onNoSubmissionChanged,
    required this.onPublishChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ToggleCard(
          title: 'No submission required',
          subtitle: 'Grade item only — no student submission expected',
          value: noSubmissionRequired,
          enabled: enabled,
          onChanged: onNoSubmissionChanged,
        ),
        const SizedBox(height: 16),
        _ToggleCard(
          title: 'Publish immediately',
          subtitle: 'Students can see this assignment right away',
          value: isPublished,
          enabled: enabled,
          onChanged: onPublishChanged,
        ),
      ],
    );
  }
}

class _ToggleCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final bool enabled;
  final void Function(bool) onChanged;

  const _ToggleCard({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight, width: 1),
      ),
      child: SwitchListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.accentCharcoal,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.foregroundTertiary,
          ),
        ),
        value: value,
        activeThumbColor: AppColors.accentCharcoal,
        onChanged: enabled ? onChanged : null,
      ),
    );
  }
}
