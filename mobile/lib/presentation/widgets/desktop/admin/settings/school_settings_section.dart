import 'package:flutter/material.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/presentation/widgets/shared/cards/info_panel.dart';
import 'package:likha/presentation/widgets/shared/forms/school_settings_form.dart';
import 'package:likha/presentation/widgets/shared/dialogs/styled_dialog.dart';
import 'package:likha/presentation/widgets/desktop/admin/shared/form_fields.dart';

/// A comprehensive school settings section widget
/// that includes the form, save functionality, and QR code generation.
class SchoolSettingsSection extends StatefulWidget {
  final TextEditingController schoolNameController;
  final TextEditingController regionController;
  final TextEditingController divisionController;
  final TextEditingController schoolYearController;
  final TextEditingController schoolCodeController;
  final String originalSchoolCode;
  final bool isLoading;
  final bool isSaving;
  final String? qrBase64;
  final VoidCallback onSave;
  final VoidCallback onShowQrCode;
  final ValueChanged<String>? onSchoolNameChanged;

  const SchoolSettingsSection({
    super.key,
    required this.schoolNameController,
    required this.regionController,
    required this.divisionController,
    required this.schoolYearController,
    required this.schoolCodeController,
    required this.originalSchoolCode,
    this.isLoading = false,
    this.isSaving = false,
    this.qrBase64,
    required this.onSave,
    required this.onShowQrCode,
    this.onSchoolNameChanged,
  });

  @override
  State<SchoolSettingsSection> createState() => _SchoolSettingsSectionState();
}

class _SchoolSettingsSectionState extends State<SchoolSettingsSection> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppColors.foregroundPrimary,
          strokeWidth: 2.5,
        ),
      );
    }

    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Info panel
            const InfoPanel(
              child: Text(
                'These settings are used in printed reports (TOS, Item Analysis) for DepEd-formatted headers.',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.foregroundSecondary,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Form
            Form(
              key: _formKey,
              child: SchoolSettingsForm(
                schoolNameController: widget.schoolNameController,
                regionController: widget.regionController,
                divisionController: widget.divisionController,
                schoolYearController: widget.schoolYearController,
                schoolCodeController: widget.schoolCodeController,
                enabled: !widget.isSaving,
                onSchoolNameChanged: widget.onSchoolNameChanged,
              ),
            ),
            const SizedBox(height: 32),

            // Action buttons
            Row(
              children: [
                // Save button
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: DesktopFormField.button(
                      onPressed: widget.isSaving ? () {} : () => _handleSave(context),
                      text: 'Save Settings',
                      isLoading: widget.isSaving,
                      icon: Icons.save_rounded,
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // QR Code button
                SizedBox(
                  height: 48,
                  child: DesktopFormField.button(
                    onPressed: widget.isSaving ? () {} : widget.onShowQrCode,
                    text: 'View QR Code',
                    isPrimary: false,
                    icon: Icons.qr_code,
                  ),
                ),
              ],
            ),

            // Additional info section
            const SizedBox(height: 24),
            _buildAdditionalInfo(),
          ],
        ),
      ),
    );
  }

  void _handleSave(BuildContext context) {
    if (!_formKey.currentState!.validate()) return;

    final newCode = widget.schoolCodeController.text.trim().toUpperCase();
    final codeChanged = newCode != widget.originalSchoolCode;

    // Show confirmation dialog if code changed
    if (codeChanged) {
      showDialog(
        context: context,
        builder: (context) => StyledDialog(
          title: 'Change School Code?',
          content: const Text(
            'Changing the code will affect new student and teacher setups. Existing users will not be impacted. Are you sure?',
          ),
          actions: [
            StyledDialogAction(
              label: 'Cancel',
              onPressed: () => Navigator.pop(context),
            ),
            StyledDialogAction(
              label: 'Confirm',
              isPrimary: true,
              onPressed: () {
                Navigator.pop(context);
                widget.onSave();
              },
            ),
          ],
        ),
      );
    } else {
      widget.onSave();
    }
  }

  Widget _buildAdditionalInfo() {
    return InfoPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'School Information',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.foregroundPrimary,
            ),
          ),
          const SizedBox(height: 12),
          _InfoRow(
            label: 'School Name',
            value: widget.schoolNameController.text.isNotEmpty
                ? widget.schoolNameController.text
                : 'Not set',
          ),
          const SizedBox(height: 8),
          _InfoRow(
            label: 'School Code',
            value: widget.schoolCodeController.text.isNotEmpty
                ? widget.schoolCodeController.text.toUpperCase()
                : 'Not set',
          ),
          if (widget.regionController.text.isNotEmpty) ...[
            const SizedBox(height: 8),
            _InfoRow(
              label: 'Region',
              value: widget.regionController.text,
            ),
          ],
          if (widget.divisionController.text.isNotEmpty) ...[
            const SizedBox(height: 8),
            _InfoRow(
              label: 'Division',
              value: widget.divisionController.text,
            ),
          ],
          if (widget.schoolYearController.text.isNotEmpty) ...[
            const SizedBox(height: 8),
            _InfoRow(
              label: 'School Year',
              value: widget.schoolYearController.text,
            ),
          ],
        ],
      ),
    );
  }
}

/// A simple info row widget for displaying key-value pairs
class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.foregroundTertiary,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.foregroundSecondary,
            ),
          ),
        ),
      ],
    );
  }
}

/// A compact school settings card for dashboard use
class SchoolSettingsCard extends StatelessWidget {
  final String schoolName;
  final String? schoolCode;
  final String? region;
  final String? division;
  final String? schoolYear;
  final VoidCallback? onTap;
  final double? width;

  const SchoolSettingsCard({
    super.key,
    required this.schoolName,
    this.schoolCode,
    this.region,
    this.division,
    this.schoolYear,
    this.onTap,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: width,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.accentCharcoal.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.school_rounded,
                      size: 24,
                      color: AppColors.accentCharcoal,
                    ),
                  ),
                  const Spacer(),
                  if (onTap != null)
                    const Icon(
                      Icons.chevron_right_rounded,
                      size: 20,
                      color: AppColors.foregroundTertiary,
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'School Settings',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.foregroundTertiary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                schoolName.isNotEmpty ? schoolName : 'Not configured',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: schoolName.isNotEmpty 
                      ? AppColors.foregroundPrimary 
                      : AppColors.foregroundTertiary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (schoolCode != null && schoolCode!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.accentAmber.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Code: ${schoolCode!.toUpperCase()}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.accentAmber,
                    ),
                  ),
                ),
              ],
              if (region != null || division != null || schoolYear != null) ...[
                const SizedBox(height: 12),
                Text(
                  [
                    if (region != null && region!.isNotEmpty) region,
                    if (division != null && division!.isNotEmpty) division,
                    if (schoolYear != null && schoolYear!.isNotEmpty) 'SY $schoolYear',
                  ].join(' '),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.foregroundTertiary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
