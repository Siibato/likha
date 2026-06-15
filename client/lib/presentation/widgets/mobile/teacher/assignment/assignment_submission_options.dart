import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:likha/core/theme/app_colors.dart';

/// Submission-method section: text/file checkboxes plus optional file-type
/// selector and max-file-size field when file submission is enabled.
class AssignmentSubmissionOptions extends StatelessWidget {
  final bool allowsTextSubmission;
  final bool allowsFileSubmission;
  final Set<String> selectedFileTypes;
  final TextEditingController maxFileSizeController;
  final bool enabled;
  final void Function(bool) onTextToggle;
  final void Function(bool) onFileToggle;
  final VoidCallback onPickFileTypes;

  const AssignmentSubmissionOptions({
    super.key,
    required this.allowsTextSubmission,
    required this.allowsFileSubmission,
    required this.selectedFileTypes,
    required this.maxFileSizeController,
    required this.enabled,
    required this.onTextToggle,
    required this.onFileToggle,
    required this.onPickFileTypes,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Submission Options',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.foregroundTertiary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        CheckboxListTile(
          title: const Text('Allow text submission'),
          value: allowsTextSubmission,
          enabled: enabled,
          onChanged: (v) => onTextToggle(v ?? false),
          dense: true,
          contentPadding: EdgeInsets.zero,
        ),
        CheckboxListTile(
          title: const Text('Allow file submission'),
          value: allowsFileSubmission,
          enabled: enabled,
          onChanged: (v) => onFileToggle(v ?? false),
          dense: true,
          contentPadding: EdgeInsets.zero,
        ),
        if (allowsFileSubmission) ...[
          const SizedBox(height: 16),
          _AllowedFileTypesSelector(
            selectedTypes: selectedFileTypes,
            enabled: enabled,
            onTap: onPickFileTypes,
          ),
          const SizedBox(height: 16),
          _MaxFileSizeField(
            controller: maxFileSizeController,
            enabled: enabled,
          ),
        ],
      ],
    );
  }
}

class _AllowedFileTypesSelector extends StatelessWidget {
  final Set<String> selectedTypes;
  final bool enabled;
  final VoidCallback onTap;

  const _AllowedFileTypesSelector({
    required this.selectedTypes,
    required this.enabled,
    required this.onTap,
  });

  String _displayText() {
    if (selectedTypes.isEmpty) return 'Any file type';
    if (selectedTypes.length <= 3) return selectedTypes.join(', ');
    return '${selectedTypes.length} types selected';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Allowed File Types (optional)',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.foregroundTertiary,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: enabled ? onTap : null,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderLight, width: 1),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                const Icon(
                  Icons.file_present_rounded,
                  color: AppColors.foregroundSecondary,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _displayText(),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: selectedTypes.isEmpty
                          ? AppColors.foregroundLight
                          : AppColors.accentCharcoal,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _MaxFileSizeField extends StatelessWidget {
  final TextEditingController controller;
  final bool enabled;

  const _MaxFileSizeField({required this.controller, required this.enabled});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: AppColors.accentCharcoal,
      ),
      decoration: InputDecoration(
        labelText: 'Max File Size (MB)',
        labelStyle: const TextStyle(
          fontSize: 14,
          color: AppColors.foregroundTertiary,
        ),
        prefixIcon: const Icon(
          Icons.sd_storage_rounded,
          color: AppColors.foregroundSecondary,
          size: 20,
        ),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.borderLight, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.borderLight, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: AppColors.accentCharcoal, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }
}
