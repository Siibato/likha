import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/domain/grading/usecases/setup_grading.dart';
import 'package:likha/presentation/pages/shared/class_section_header.dart';
import 'package:likha/presentation/pages/shared/widgets/forms/styled_button.dart';
import 'package:likha/presentation/pages/shared/widgets/forms/styled_dropdown.dart';
import 'package:likha/presentation/pages/shared/widgets/forms/styled_text_field.dart';
import 'package:likha/presentation/providers/grading_provider.dart';

class ClassGradingSetupPage extends ConsumerStatefulWidget {
  final String classId;

  const ClassGradingSetupPage({super.key, required this.classId});

  @override
  ConsumerState<ClassGradingSetupPage> createState() =>
      _ClassGradingSetupPageState();
}

class _ClassGradingSetupPageState extends ConsumerState<ClassGradingSetupPage> {
  String? _selectedGradeLevel;
  String? _selectedSubjectGroup;
  int? _selectedSemester;
  late TextEditingController _schoolYearController;

  static const _gradeLevels = [
    'Grade 7',
    'Grade 8',
    'Grade 9',
    'Grade 10',
    'Grade 11',
    'Grade 12',
  ];

  static const _jhsSubjectGroups = {
    'language': 'Language',
    'ap_esp': 'AP / EsP',
    'math_sci': 'Math & Science',
    'mapeh_tle': 'MAPEH / EPP / TLE',
  };

  static const _shsSubjectGroups = {
    'shs_core': 'Core Subjects',
    'shs_academic': 'Academic Track',
    'shs_tvl': 'TVL / Sports / Arts',
    'shs_immersion': 'Work Immersion / Research',
  };

  /// DepEd Order No. 8 weight presets (WW / PT / QA)
  static const _weightPresets = {
    'language': (ww: 30, pt: 50, qa: 20),
    'ap_esp': (ww: 30, pt: 50, qa: 20),
    'math_sci': (ww: 40, pt: 40, qa: 20),
    'mapeh_tle': (ww: 20, pt: 60, qa: 20),
    'shs_core': (ww: 25, pt: 50, qa: 25),
    'shs_academic': (ww: 25, pt: 45, qa: 30),
    'shs_tvl': (ww: 25, pt: 45, qa: 30),
    'shs_immersion': (ww: 35, pt: 40, qa: 25),
  };

  bool get _isShs {
    if (_selectedGradeLevel == null) return false;
    final num = int.tryParse(_selectedGradeLevel!.replaceAll('Grade ', ''));
    return num != null && num >= 11;
  }

  Map<String, String> get _availableSubjectGroups =>
      _isShs ? _shsSubjectGroups : _jhsSubjectGroups;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final startYear = now.month >= 6 ? now.year : now.year - 1;
    _schoolYearController =
        TextEditingController(text: '$startYear-${startYear + 1}');
  }

  @override
  void dispose() {
    _schoolYearController.dispose();
    super.dispose();
  }

  Future<void> _saveConfig() async {
    if (_selectedGradeLevel == null ||
        _selectedSubjectGroup == null ||
        _schoolYearController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all required fields')),
      );
      return;
    }

    if (_isShs && _selectedSemester == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a semester')),
      );
      return;
    }

    await ref.read(gradingConfigProvider.notifier).setupGrading(
          SetupGradingParams(
            classId: widget.classId,
            gradeLevel: _selectedGradeLevel!,
            subjectGroup: _selectedSubjectGroup!,
            schoolYear: _schoolYearController.text,
            semester: _isShs ? _selectedSemester : null,
          ),
        );

    final state = ref.read(gradingConfigProvider);
    if (mounted) {
      if (state.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: ${state.error}')),
        );
      } else {
        Navigator.pop(context, true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final configState = ref.watch(gradingConfigProvider);
    final weights = _selectedSubjectGroup != null
        ? _weightPresets[_selectedSubjectGroup!]
        : null;

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: SafeArea(
        child: Column(
          children: [
            const ClassSectionHeader(
              title: 'Grading Setup',
              showBackButton: true,
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Configure DepEd-compliant grading weights for this class.',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF999999),
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Grade Level
                    StyledDropdown<String>(
                      value: _selectedGradeLevel,
                      label: 'Grade Level',
                      icon: Icons.school_outlined,
                      items: _gradeLevels
                          .map((g) => DropdownMenuItem(
                                value: g,
                                child: Text(g),
                              ))
                          .toList(),
                      onChanged: (val) {
                        setState(() {
                          _selectedGradeLevel = val;
                          if (!_availableSubjectGroups
                              .containsKey(_selectedSubjectGroup)) {
                            _selectedSubjectGroup = null;
                          }
                          if (!_isShs) _selectedSemester = null;
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    // Subject Group
                    StyledDropdown<String>(
                      value: _selectedSubjectGroup,
                      label: 'Subject Group',
                      icon: Icons.category_outlined,
                      enabled: _selectedGradeLevel != null,
                      items: _availableSubjectGroups.entries
                          .map((e) => DropdownMenuItem(
                                value: e.key,
                                child: Text(e.value),
                              ))
                          .toList(),
                      onChanged: (val) =>
                          setState(() => _selectedSubjectGroup = val),
                    ),
                    const SizedBox(height: 16),

                    // School Year
                    StyledTextField(
                      controller: _schoolYearController,
                      label: 'School Year',
                      icon: Icons.calendar_today_outlined,
                      hintText: '2025-2026',
                    ),
                    const SizedBox(height: 16),

                    // Semester (SHS only)
                    if (_isShs) ...[
                      StyledDropdown<int>(
                        value: _selectedSemester,
                        label: 'Semester',
                        icon: Icons.view_timeline_outlined,
                        items: const [
                          DropdownMenuItem(
                              value: 1, child: Text('1st Semester')),
                          DropdownMenuItem(
                              value: 2, child: Text('2nd Semester')),
                        ],
                        onChanged: (val) =>
                            setState(() => _selectedSemester = val),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Weight Preview
                    if (weights != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: const Color(0xFFE0E0E0),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'DepEd Weight Distribution',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF2B2B2B),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Based on DepEd Order No. 8',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade500,
                              ),
                            ),
                            const SizedBox(height: 16),
                            _WeightRow(
                              label: 'Written Works',
                              percentage: weights.ww,
                            ),
                            const SizedBox(height: 10),
                            _WeightRow(
                              label: 'Performance Tasks',
                              percentage: weights.pt,
                            ),
                            const SizedBox(height: 10),
                            _WeightRow(
                              label: 'Quarterly Assessment',
                              percentage: weights.qa,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Save Button
                    StyledButton(
                      text: 'Use Standard Weights',
                      isLoading: configState.isLoading,
                      icon: Icons.check_rounded,
                      onPressed: _saveConfig,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WeightRow extends StatelessWidget {
  final String label;
  final int percentage;

  const _WeightRow({required this.label, required this.percentage});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF666666),
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFF8F9FA),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '$percentage%',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF2B2B2B),
            ),
          ),
        ),
      ],
    );
  }
}
