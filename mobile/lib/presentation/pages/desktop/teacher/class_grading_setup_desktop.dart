import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/domain/grading/usecases/setup_grading.dart';
import 'package:likha/presentation/pages/desktop/core/desktop_page_scaffold.dart';
import 'package:likha/presentation/providers/grading_provider.dart';

class ClassGradingSetupDesktop extends ConsumerStatefulWidget {
  final String classId;

  const ClassGradingSetupDesktop({super.key, required this.classId});

  @override
  ConsumerState<ClassGradingSetupDesktop> createState() =>
      _ClassGradingSetupDesktopState();
}

class _ClassGradingSetupDesktopState
    extends ConsumerState<ClassGradingSetupDesktop> {
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
      backgroundColor: AppColors.backgroundSecondary,
      body: DesktopPageScaffold(
        title: 'Grading Setup',
        maxWidth: 600,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.foregroundPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        body: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.borderLight, width: 1),
          ),
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
              DropdownButtonFormField<String>(
                value: _selectedGradeLevel,
                decoration: const InputDecoration(
                  labelText: 'Grade Level',
                  prefixIcon: Icon(Icons.school_outlined),
                  border: OutlineInputBorder(),
                ),
                items: _gradeLevels
                    .map((g) => DropdownMenuItem(value: g, child: Text(g)))
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
              DropdownButtonFormField<String>(
                value: _selectedSubjectGroup,
                decoration: const InputDecoration(
                  labelText: 'Subject Group',
                  prefixIcon: Icon(Icons.category_outlined),
                  border: OutlineInputBorder(),
                ),
                items: _availableSubjectGroups.entries
                    .map((e) =>
                        DropdownMenuItem(value: e.key, child: Text(e.value)))
                    .toList(),
                onChanged: _selectedGradeLevel != null
                    ? (val) => setState(() => _selectedSubjectGroup = val)
                    : null,
              ),
              const SizedBox(height: 16),

              // School Year
              TextFormField(
                controller: _schoolYearController,
                decoration: const InputDecoration(
                  labelText: 'School Year',
                  prefixIcon: Icon(Icons.calendar_today_outlined),
                  hintText: '2025-2026',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // Semester (SHS only)
              if (_isShs) ...[
                DropdownButtonFormField<int>(
                  value: _selectedSemester,
                  decoration: const InputDecoration(
                    labelText: 'Semester',
                    prefixIcon: Icon(Icons.view_timeline_outlined),
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 1, child: Text('1st Semester')),
                    DropdownMenuItem(value: 2, child: Text('2nd Semester')),
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
                    color: AppColors.backgroundTertiary,
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
                          color: AppColors.foregroundPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Based on DepEd Order No. 8',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.foregroundTertiary,
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
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: configState.isLoading ? null : _saveConfig,
                  icon: configState.isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.check_rounded),
                  label: const Text('Use Standard Weights'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.foregroundPrimary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
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
            color: AppColors.backgroundSecondary,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '$percentage%',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.foregroundPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
