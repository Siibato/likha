import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:likha/presentation/pages/shared/widgets/forms/styled_text_field.dart';

/// Shared form widget for school settings (name, region, division, school year).
/// Used by both the first-time setup page and the admin settings page.
class SchoolSettingsForm extends StatelessWidget {
  final TextEditingController schoolNameController;
  final TextEditingController regionController;
  final TextEditingController divisionController;
  final TextEditingController schoolYearController;
  final bool enabled;
  final ValueChanged<String>? onSchoolNameChanged;

  const SchoolSettingsForm({
    super.key,
    required this.schoolNameController,
    required this.regionController,
    required this.divisionController,
    required this.schoolYearController,
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
      ],
    );
  }
}
