import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/presentation/providers/student_records_provider.dart';
import 'package:likha/presentation/widgets/shared/forms/school_year_dropdown.dart';
import 'package:likha/presentation/widgets/shared/forms/styled_button.dart';
import 'package:likha/presentation/widgets/shared/forms/styled_text_field.dart';
import 'package:likha/presentation/layouts/desktop/desktop_page_scaffold.dart';
import 'package:likha/domain/student_records/entities/school_history.dart';

class Sf10SchoolHistoryEditPage extends ConsumerStatefulWidget {
  final String classId;
  final String studentId;
  final String studentName;
  final SchoolHistory? schoolHistory;

  const Sf10SchoolHistoryEditPage({
    super.key,
    required this.classId,
    required this.studentId,
    required this.studentName,
    this.schoolHistory,
  });

  @override
  ConsumerState<Sf10SchoolHistoryEditPage> createState() => _Sf10SchoolHistoryEditPageState();
}

class _Sf10SchoolHistoryEditPageState extends ConsumerState<Sf10SchoolHistoryEditPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _schoolNameCtrl;
  late final TextEditingController _schoolIdCtrl;
  late final TextEditingController _gradeLevelCtrl;
  String? _selectedSchoolYear;
  late final TextEditingController _sectionCtrl;
  late final TextEditingController _dateFromCtrl;
  late final TextEditingController _dateToCtrl;
  late final TextEditingController _recordTypeCtrl;

  bool get _isNew => widget.schoolHistory == null;

  @override
  void initState() {
    super.initState();
    final h = widget.schoolHistory;
    _schoolNameCtrl = TextEditingController(text: h?.schoolName ?? '');
    _schoolIdCtrl = TextEditingController(text: h?.schoolId ?? '');
    _gradeLevelCtrl = TextEditingController(text: h?.gradeLevel ?? '');
    final schoolYear = h?.schoolYear;
    _selectedSchoolYear = (schoolYear != null && schoolYear.isNotEmpty) ? schoolYear : SchoolYearDropdown.currentSchoolYear;
    _sectionCtrl = TextEditingController(text: h?.section ?? '');
    _dateFromCtrl = TextEditingController(text: h?.dateFrom ?? '');
    _dateToCtrl = TextEditingController(text: h?.dateTo ?? '');
    _recordTypeCtrl = TextEditingController(text: h?.recordType ?? 'previous');

    if (!_isNew) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(previousSubjectsProvider.notifier).load(widget.classId, widget.studentId, schoolHistoryId: widget.schoolHistory!.id);
        ref.read(previousAttendanceProvider.notifier).load(widget.classId, widget.studentId, schoolHistoryId: widget.schoolHistory!.id);
      });
    }
  }

  @override
  void dispose() {
    _schoolNameCtrl.dispose();
    _schoolIdCtrl.dispose();
    _gradeLevelCtrl.dispose();
    _sectionCtrl.dispose();
    _dateFromCtrl.dispose();
    _dateToCtrl.dispose();
    _recordTypeCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveSchoolInfo() async {
    if (!_formKey.currentState!.validate()) return;
    final data = {
      'school_name': _schoolNameCtrl.text,
      'school_id': _schoolIdCtrl.text.isEmpty ? null : _schoolIdCtrl.text,
      'grade_level': _gradeLevelCtrl.text,
      'school_year': _selectedSchoolYear,
      'section': _sectionCtrl.text.isEmpty ? null : _sectionCtrl.text,
      'date_from': _dateFromCtrl.text.isEmpty ? null : _dateFromCtrl.text,
      'date_to': _dateToCtrl.text.isEmpty ? null : _dateToCtrl.text,
      'record_type': _recordTypeCtrl.text,
    };

    bool success;
    if (_isNew) {
      success = await ref.read(schoolHistoryProvider.notifier).create(widget.classId, widget.studentId, data);
    } else {
      success = await ref.read(schoolHistoryProvider.notifier).update(widget.classId, widget.studentId, widget.schoolHistory!.id, data);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'School info saved' : 'Failed to save school info'),
          backgroundColor: success ? AppColors.semanticSuccess : AppColors.semanticError,
        ),
      );
      if (success && _isNew) {
        Navigator.pop(context);
      }
    }
  }

  Future<void> _pickDate(TextEditingController controller, String helpText) async {
    final currentText = controller.text;
    DateTime? initialDate;
    if (currentText.isNotEmpty) {
      initialDate = DateTime.tryParse(currentText);
    }
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
      initialEntryMode: DatePickerEntryMode.input,
      helpText: helpText,
    );
    if (picked != null) {
      controller.text = picked.toIso8601String().split('T').first;
    }
  }

  Future<void> _deleteSchoolHistory() async {
    if (_isNew) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete School History'),
        content: const Text('Are you sure you want to delete this school history record?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.semanticError),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final success = await ref.read(schoolHistoryProvider.notifier).delete(widget.classId, widget.studentId, widget.schoolHistory!.id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'School history deleted' : 'Failed to delete'),
          backgroundColor: success ? AppColors.semanticSuccess : AppColors.semanticError,
        ),
      );
      if (success) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final subjectsState = ref.watch(previousSubjectsProvider);
    final attendanceState = ref.watch(previousAttendanceProvider);
    final historyState = ref.watch(schoolHistoryProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundSecondary,
      body: DesktopPageScaffold(
        title: _isNew ? 'Add Previous School' : 'Edit School History',
        subtitle: widget.studentName,
        maxWidth: 900,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          color: AppColors.foregroundPrimary,
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (!_isNew) ...[
            StyledButton(
              text: 'Delete',
              icon: Icons.delete_outline_rounded,
              variant: StyledButtonVariant.destructive,
              fullWidth: false,
              isLoading: historyState.isSaving,
              onPressed: _deleteSchoolHistory,
            ),
            const SizedBox(width: 12),
          ],
          StyledButton(
            text: 'Save School Info',
            icon: Icons.save_rounded,
            variant: StyledButtonVariant.primary,
            fullWidth: false,
            isLoading: historyState.isSaving,
            onPressed: _saveSchoolInfo,
          ),
          const SizedBox(width: 16),
        ],
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle('School Information'),
            const SizedBox(height: 16),
            _schoolInfoForm(),
            const SizedBox(height: 32),
            if (!_isNew) ...[
              _sectionTitle('Subjects'),
              const SizedBox(height: 16),
              _subjectsTable(subjectsState),
              const SizedBox(height: 32),
              _sectionTitle('Attendance'),
              const SizedBox(height: 16),
              _attendanceTable(attendanceState),
            ],
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.foregroundPrimary));
  }

  Widget _schoolInfoForm() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.borderLight)),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: StyledTextField(
                  controller: _schoolNameCtrl,
                  label: 'School Name',
                  icon: Icons.school_outlined,
                  validator: (v) => v == null || v.isEmpty ? 'School Name is required' : null,
                )),
                const SizedBox(width: 16),
                Expanded(child: StyledTextField(
                  controller: _schoolIdCtrl,
                  label: 'School ID',
                  icon: Icons.badge_outlined,
                )),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: StyledTextField(
                  controller: _gradeLevelCtrl,
                  label: 'Grade Level',
                  icon: Icons.grade_outlined,
                  validator: (v) => v == null || v.isEmpty ? 'Grade Level is required' : null,
                )),
                const SizedBox(width: 16),
                Expanded(
                  child: SchoolYearDropdown(
                    value: _selectedSchoolYear,
                    onChanged: (val) => setState(() => _selectedSchoolYear = val),
                    validator: (v) => v == null || v.isEmpty ? 'School Year is required' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: StyledTextField(
                  controller: _sectionCtrl,
                  label: 'Section',
                  icon: Icons.group_outlined,
                )),
                const SizedBox(width: 16),
                Expanded(child: StyledTextField(
                  controller: _recordTypeCtrl,
                  label: 'Record Type',
                  icon: Icons.category_outlined,
                  validator: (v) => v == null || v.isEmpty ? 'Record Type is required' : null,
                )),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: StyledTextField(
                  controller: _dateFromCtrl,
                  label: 'Date From',
                  icon: Icons.event_outlined,
                  hintText: 'YYYY-MM-DD',
                  readOnly: true,
                  onTap: () => _pickDate(_dateFromCtrl, 'Select Date From'),
                )),
                const SizedBox(width: 16),
                Expanded(child: StyledTextField(
                  controller: _dateToCtrl,
                  label: 'Date To',
                  icon: Icons.event_outlined,
                  hintText: 'YYYY-MM-DD',
                  readOnly: true,
                  onTap: () => _pickDate(_dateToCtrl, 'Select Date To'),
                )),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _subjectsTable(PreviousSubjectsState state) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.borderLight)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Subject Records', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.foregroundDark)),
              const Spacer(),
              StyledButton(
                text: 'Add Subject',
                icon: Icons.add_rounded,
                variant: StyledButtonVariant.outlined,
                fullWidth: false,
                isLoading: false,
                onPressed: () => _showAddSubjectDialog(),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (state.isLoading)
            const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator(color: AppColors.foregroundPrimary, strokeWidth: 2.5)))
          else if (state.error != null)
            Text(state.error!, style: const TextStyle(color: AppColors.semanticError, fontSize: 13))
          else if (state.records.isEmpty)
            const Text('No subjects added yet', style: TextStyle(color: AppColors.foregroundTertiary, fontSize: 13))
          else
            Table(
              columnWidths: const {
                0: FlexColumnWidth(3),
                1: FlexColumnWidth(2),
                2: FlexColumnWidth(1),
                3: FlexColumnWidth(1),
                4: FlexColumnWidth(1),
                5: FlexColumnWidth(1),
                6: FlexColumnWidth(1),
                7: FlexColumnWidth(2),
              },
              children: [
                TableRow(children: [
                  _th('Subject'), _th('Group'), _th('T1'), _th('T2'), _th('T3'), _th('T4'), _th('Final'), _th('Descriptor'),
                ]),
                ...state.records.map((s) {
                  final tg = s.termGrades;
                  return TableRow(children: [
                    _td(s.subjectName),
                    _td(s.subjectGroup ?? '-'),
                    _td(tg.isNotEmpty ? tg[0]?.toString() ?? '-' : '-'),
                    _td(tg.length > 1 ? tg[1]?.toString() ?? '-' : '-'),
                    _td(tg.length > 2 ? tg[2]?.toString() ?? '-' : '-'),
                    _td(tg.length > 3 ? tg[3]?.toString() ?? '-' : '-'),
                    _td(s.finalGrade?.toString() ?? '-'),
                    _td(s.descriptor ?? '-'),
                  ]);
                }),
              ],
            ),
        ],
      ),
    );
  }

  Widget _attendanceTable(PreviousAttendanceState state) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.borderLight)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Monthly Attendance', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.foregroundDark)),
              const Spacer(),
              StyledButton(
                text: 'Add Month',
                icon: Icons.add_rounded,
                variant: StyledButtonVariant.outlined,
                fullWidth: false,
                isLoading: false,
                onPressed: () => _showAddAttendanceDialog(),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (state.isLoading)
            const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator(color: AppColors.foregroundPrimary, strokeWidth: 2.5)))
          else if (state.error != null)
            Text(state.error!, style: const TextStyle(color: AppColors.semanticError, fontSize: 13))
          else if (state.records.isEmpty)
            const Text('No attendance records yet', style: TextStyle(color: AppColors.foregroundTertiary, fontSize: 13))
          else
            Table(
              columnWidths: const {
                0: FlexColumnWidth(2),
                1: FlexColumnWidth(1),
                2: FlexColumnWidth(1),
              },
              children: [
                TableRow(children: [_th('Month'), _th('School Days'), _th('Days Present')]),
                ...state.records.map((a) => TableRow(children: [
                  _td(a.month),
                  _td(a.schoolDays.toString()),
                  _td(a.daysPresent.toString()),
                ])),
              ],
            ),
        ],
      ),
    );
  }

  void _showAddSubjectDialog() {
    final nameCtrl = TextEditingController();
    final groupCtrl = TextEditingController();
    final t1Ctrl = TextEditingController();
    final t2Ctrl = TextEditingController();
    final t3Ctrl = TextEditingController();
    final t4Ctrl = TextEditingController();
    final finalCtrl = TextEditingController();
    final descriptorCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Subject'),
        content: SizedBox(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              StyledTextField(controller: nameCtrl, label: 'Subject Name', icon: Icons.book_outlined),
              const SizedBox(height: 12),
              StyledTextField(controller: groupCtrl, label: 'Subject Group (optional)', icon: Icons.category_outlined),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: StyledTextField(controller: t1Ctrl, label: 'T1', icon: Icons.grade_outlined, keyboardType: TextInputType.number)),
                  const SizedBox(width: 8),
                  Expanded(child: StyledTextField(controller: t2Ctrl, label: 'T2', icon: Icons.grade_outlined, keyboardType: TextInputType.number)),
                  const SizedBox(width: 8),
                  Expanded(child: StyledTextField(controller: t3Ctrl, label: 'T3', icon: Icons.grade_outlined, keyboardType: TextInputType.number)),
                  const SizedBox(width: 8),
                  Expanded(child: StyledTextField(controller: t4Ctrl, label: 'T4', icon: Icons.grade_outlined, keyboardType: TextInputType.number)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: StyledTextField(controller: finalCtrl, label: 'Final Grade', icon: Icons.grade_outlined, keyboardType: TextInputType.number)),
                  const SizedBox(width: 8),
                  Expanded(child: StyledTextField(controller: descriptorCtrl, label: 'Descriptor', icon: Icons.description_outlined)),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              if (nameCtrl.text.isEmpty) return;
              Navigator.pop(ctx);
              final data = {
                'school_history_id': widget.schoolHistory!.id,
                'subject_name': nameCtrl.text,
                'subject_group': groupCtrl.text.isEmpty ? null : groupCtrl.text,
                'term_type': 'quarterly',
                'term_grades': [
                  int.tryParse(t1Ctrl.text),
                  int.tryParse(t2Ctrl.text),
                  int.tryParse(t3Ctrl.text),
                  int.tryParse(t4Ctrl.text),
                ],
                'final_grade': int.tryParse(finalCtrl.text),
                'descriptor': descriptorCtrl.text.isEmpty ? null : descriptorCtrl.text,
              };
              final success = await ref.read(previousSubjectsProvider.notifier).save(widget.classId, widget.studentId, data);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success ? 'Subject saved' : 'Failed to save subject'),
                    backgroundColor: success ? AppColors.semanticSuccess : AppColors.semanticError,
                  ),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showAddAttendanceDialog() {
    final monthCtrl = TextEditingController();
    final schoolDaysCtrl = TextEditingController();
    final daysPresentCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Attendance Month'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              StyledTextField(controller: monthCtrl, label: 'Month (e.g. June)', icon: Icons.calendar_month_outlined),
              const SizedBox(height: 12),
              StyledTextField(controller: schoolDaysCtrl, label: 'School Days', icon: Icons.calendar_today_outlined, keyboardType: TextInputType.number),
              const SizedBox(height: 12),
              StyledTextField(controller: daysPresentCtrl, label: 'Days Present', icon: Icons.check_circle_outline, keyboardType: TextInputType.number),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              if (monthCtrl.text.isEmpty) return;
              Navigator.pop(ctx);
              final data = {
                'school_history_id': widget.schoolHistory!.id,
                'school_year': widget.schoolHistory!.schoolYear,
                'month': monthCtrl.text,
                'school_days': int.tryParse(schoolDaysCtrl.text) ?? 0,
                'days_present': int.tryParse(daysPresentCtrl.text) ?? 0,
              };
              final success = await ref.read(previousAttendanceProvider.notifier).save(widget.classId, widget.studentId, data);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success ? 'Attendance saved' : 'Failed to save attendance'),
                    backgroundColor: success ? AppColors.semanticSuccess : AppColors.semanticError,
                  ),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Widget _th(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(text, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.foregroundSecondary)),
  );

  Widget _td(String text) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Text(text, style: const TextStyle(fontSize: 12, color: AppColors.foregroundDark)),
  );
}
