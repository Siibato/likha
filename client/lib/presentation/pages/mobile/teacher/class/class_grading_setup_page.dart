import 'package:flutter/material.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/domain/grading/usecases/setup_grading.dart';
import 'package:likha/presentation/widgets/shared/primitives/class_section_header.dart';
import 'package:likha/presentation/widgets/shared/forms/styled_button.dart';
import 'package:likha/presentation/widgets/shared/forms/styled_dropdown.dart';
import 'package:likha/presentation/widgets/shared/forms/school_year_dropdown.dart';
import 'package:likha/presentation/widgets/shared/forms/styled_text_field.dart';
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
  String? _selectedSchoolYear;

  final _customWwController = TextEditingController();
  final _customPtController = TextEditingController();
  final _customQaController = TextEditingController();

  @override
  void dispose() {
    _customWwController.dispose();
    _customPtController.dispose();
    _customQaController.dispose();
    super.dispose();
  }

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
    'jhs_academic_do015': 'Academic (DO 015 s 2026)',
    'others': 'Others (Custom Weights)',
  };

  static const _shsSubjectGroups = {
    'shs_core': 'Core Subjects',
    'shs_academic': 'Academic Track',
    'shs_tvl': 'TVL / Sports / Arts',
    'shs_immersion': 'Work Immersion / Research',
    'shs_core_do015': 'Core & Academic Electives',
    'shs_field_exposure': 'Field Exposure / Arts',
    'shs_arts_sports_health': 'Arts / Sports / Health',
    'shs_research_design': 'Research & Design',
    'shs_techpro': 'TechPro Electives',
    'shs_work_immersion_do015': 'Work Immersion (DO 015)',
    'others': 'Others (Custom Weights)',
  };

  /// DepEd weight presets (WW / PT / QA)
  static const _weightPresets = {
    'language': (ww: 30, pt: 50, qa: 20),
    'ap_esp': (ww: 30, pt: 50, qa: 20),
    'math_sci': (ww: 40, pt: 40, qa: 20),
    'mapeh_tle': (ww: 20, pt: 60, qa: 20),
    'jhs_academic_do015': (ww: 20, pt: 50, qa: 30),
    'shs_core': (ww: 25, pt: 50, qa: 25),
    'shs_academic': (ww: 25, pt: 45, qa: 30),
    'shs_tvl': (ww: 35, pt: 40, qa: 25),
    'shs_immersion': (ww: 20, pt: 60, qa: 20),
    'shs_core_do015': (ww: 20, pt: 50, qa: 30),
    'shs_field_exposure': (ww: 15, pt: 70, qa: 15),
    'shs_arts_sports_health': (ww: 20, pt: 60, qa: 20),
    'shs_research_design': (ww: 40, pt: 60, qa: 0),
    'shs_techpro': (ww: 15, pt: 65, qa: 20),
    'shs_work_immersion_do015': (ww: 20, pt: 80, qa: 0),
  };

  bool get _isOthers => _selectedSubjectGroup == 'others';

  int get _customTotal {
    final ww = int.tryParse(_customWwController.text) ?? 0;
    final pt = int.tryParse(_customPtController.text) ?? 0;
    final qa = int.tryParse(_customQaController.text) ?? 0;
    return ww + pt + qa;
  }

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
    _selectedSchoolYear = SchoolYearDropdown.currentSchoolYear;
  }

  Future<void> _saveConfig() async {
    if (_selectedGradeLevel == null ||
        _selectedSubjectGroup == null ||
        (_selectedSchoolYear?.isEmpty ?? true)) {
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

    double? customWw;
    double? customPt;
    double? customQa;

    if (_isOthers) {
      customWw = double.tryParse(_customWwController.text);
      customPt = double.tryParse(_customPtController.text);
      customQa = double.tryParse(_customQaController.text);

      if (customWw == null || customPt == null || customQa == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Please enter valid numbers for all weights')),
        );
        return;
      }

      final total = customWw + customPt + customQa;
      if ((total - 100).abs() > 0.01) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Weights must total 100%. Current total: ${total.toStringAsFixed(0)}%')),
        );
        return;
      }
    }

    await ref.read(gradingConfigProvider.notifier).setupGrading(
          SetupGradingParams(
            classId: widget.classId,
            gradeLevel: _selectedGradeLevel!,
            subjectGroup: _selectedSubjectGroup!,
            schoolYear: _selectedSchoolYear!,
            semester: _isShs ? _selectedSemester : null,
            wwWeight: customWw,
            ptWeight: customPt,
            qaWeight: customQa,
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
    final weights = _selectedSubjectGroup != null && !_isOthers
        ? _weightPresets[_selectedSubjectGroup!]
        : null;

    return Scaffold(
      backgroundColor: AppColors.backgroundSecondary,
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
                        color: AppColors.foregroundTertiary,
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
                    SchoolYearDropdown(
                      value: _selectedSchoolYear,
                      onChanged: (val) => setState(() => _selectedSchoolYear = val),
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
                            color: AppColors.borderLight,
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
                                color: AppColors.accentCharcoal,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _selectedSubjectGroup!.contains('do015')
                                  ? 'Based on DepEd Order No. 015, s. 2026'
                                  : 'Based on DepEd Order No. 8, s. 2015',
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
                              label: 'Term Assessment',
                              percentage: weights.qa,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Custom Weight Input (Others)
                    if (_isOthers) ...[
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: AppColors.borderLight,
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Custom Weight Distribution',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.accentCharcoal,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Set your own weights — total must equal 100%',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade500,
                              ),
                            ),
                            const SizedBox(height: 16),
                            StyledTextField(
                              controller: _customWwController,
                              label: 'Written Works',
                              icon: Icons.edit_note_outlined,
                              keyboardType: TextInputType.number,
                              onChanged: (_) => setState(() {}),
                            ),
                            const SizedBox(height: 12),
                            StyledTextField(
                              controller: _customPtController,
                              label: 'Performance Tasks',
                              icon: Icons.task_alt_outlined,
                              keyboardType: TextInputType.number,
                              onChanged: (_) => setState(() {}),
                            ),
                            const SizedBox(height: 12),
                            StyledTextField(
                              controller: _customQaController,
                              label: 'Term Assessment',
                              icon: Icons.assessment_outlined,
                              keyboardType: TextInputType.number,
                              onChanged: (_) => setState(() {}),
                            ),
                            const SizedBox(height: 16),
                            Builder(builder: (context) {
                              final total = _customTotal;
                              final isValid = total == 100;
                              return Row(
                                children: [
                                  const Spacer(),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: isValid
                                          ? const Color(0xFFE8F5E9)
                                          : (total > 100
                                              ? const Color(0xFFFFEBEE)
                                              : AppColors.backgroundTertiary),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: isValid
                                            ? const Color(0xFF4CAF50)
                                            : (total > 100
                                                ? const Color(0xFFE53935)
                                                : AppColors.borderLight),
                                      ),
                                    ),
                                    child: Text(
                                      'Total: $total%${isValid ? ' ✓' : (total == 0 ? '' : ' — must be 100%')}',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: isValid
                                            ? const Color(0xFF2E7D32)
                                            : (total > 100
                                                ? const Color(0xFFC62828)
                                                : AppColors.foregroundTertiary),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            }),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Save Button
                    StyledButton(
                      text: _isOthers ? 'Save Custom Weights' : 'Use Standard Weights',
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
              color: AppColors.foregroundSecondary,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.backgroundTertiary,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '$percentage%',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.accentCharcoal,
            ),
          ),
        ),
      ],
    );
  }
}

