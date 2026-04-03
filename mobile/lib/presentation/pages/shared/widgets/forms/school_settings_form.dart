import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/presentation/pages/shared/widgets/cards/info_panel.dart';
import 'package:likha/presentation/pages/shared/widgets/forms/styled_text_field.dart';

/// Custom input formatter to convert text to uppercase
class UppercaseInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return newValue.copyWith(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}

/// Shared form widget for school settings (name, region, division, school year, and optional code).
/// Used by both the first-time setup page and the admin settings page.
class SchoolSettingsForm extends StatelessWidget {
  final TextEditingController schoolNameController;
  final TextEditingController regionController;
  final TextEditingController divisionController;
  final TextEditingController schoolYearController;
  final TextEditingController? schoolCodeController;
  final bool enabled;
  final ValueChanged<String>? onSchoolNameChanged;

  const SchoolSettingsForm({
    super.key,
    required this.schoolNameController,
    required this.regionController,
    required this.divisionController,
    required this.schoolYearController,
    this.schoolCodeController,
    this.enabled = true,
    this.onSchoolNameChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        StyledTextField(
          controller: schoolNameController,
          label: 'School Name',
          icon: Icons.school_outlined,
          enabled: enabled,
          hintText: 'e.g., Mabini National High School',
          onChanged: onSchoolNameChanged,
        ),
        const SizedBox(height: 16),
        StyledTextField(
          controller: regionController,
          label: 'Region',
          icon: Icons.map_outlined,
          enabled: enabled,
          hintText: 'e.g., Region IV-A (CALABARZON)',
        ),
        const SizedBox(height: 16),
        StyledTextField(
          controller: divisionController,
          label: 'Division',
          icon: Icons.location_city_outlined,
          enabled: enabled,
          hintText: 'e.g., Division of Batangas',
        ),
        const SizedBox(height: 16),
        StyledTextField(
          controller: schoolYearController,
          label: 'School Year',
          icon: Icons.calendar_today_outlined,
          enabled: enabled,
          hintText: 'e.g., 2025-2026',
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9\-]')),
            LengthLimitingTextInputFormatter(9),
          ],
        ),
        if (schoolCodeController != null) ...[
          const SizedBox(height: 16),
          const InfoPanel(
            child: Text(
              'This 6-character code is used by students and teachers to connect to your school during initial setup. Changing it will only affect new device registrations.',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.foregroundSecondary,
              ),
            ),
          ),
          const SizedBox(height: 16),
          StyledTextField(
            controller: schoolCodeController!,
            label: 'School Code',
            icon: Icons.vpn_key_outlined,
            enabled: enabled,
            hintText: 'e.g., ESATQL',
            inputFormatters: [
              UppercaseInputFormatter(),
              LengthLimitingTextInputFormatter(6),
              FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
            ],
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'School code is required';
              }
              if (value.length != 6) {
                return 'School code must be exactly 6 characters';
              }
              return null;
            },
          ),
        ],
      ],
    );
  }
}
