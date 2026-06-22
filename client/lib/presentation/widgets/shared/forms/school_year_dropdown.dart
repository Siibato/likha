import 'package:flutter/material.dart';
import 'package:likha/presentation/widgets/shared/forms/styled_dropdown.dart';

/// A dropdown for selecting a school year in "YYYY-YYYY+1" format.
///
/// Generates options from 100 years ago to the year after the current year.
/// For example, if the current year is 2026, the most recent option is
/// "2027-2028" and the oldest is "1927-1928".
class SchoolYearDropdown extends StatelessWidget {
  final String? value;
  final ValueChanged<String?>? onChanged;
  final bool enabled;
  final String? Function(String?)? validator;
  final String label;

  const SchoolYearDropdown({
    super.key,
    this.value,
    this.onChanged,
    this.enabled = true,
    this.validator,
    this.label = 'School Year',
  });

  /// Computes the current school year based on the month.
  /// School year starts in June, so if month >= 6, current year is the start year.
  static String get currentSchoolYear {
    final now = DateTime.now();
    final startYear = now.month >= 6 ? now.year : now.year - 1;
    return '$startYear-${startYear + 1}';
  }

  /// Generates school year options from 100 years ago to the year after now.
  static List<String> get options {
    final now = DateTime.now();
    final mostRecentStart = now.year + 1;
    final oldestStart = mostRecentStart - 100;
    return List.generate(
      mostRecentStart - oldestStart + 1,
      (i) {
        final start = mostRecentStart - i;
        return '$start-${start + 1}';
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return StyledDropdown<String>(
      value: value,
      label: label,
      icon: Icons.calendar_today_outlined,
      items: options
          .map((year) => DropdownMenuItem(value: year, child: Text(year)))
          .toList(),
      onChanged: onChanged,
      enabled: enabled,
      validator: validator,
    );
  }
}
