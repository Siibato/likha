import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/presentation/providers/student_records_provider.dart';
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
  late final TextEditingController _schoolYearCtrl;
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
    _schoolYearCtrl = TextEditingController(text: h?.schoolYear ?? '');
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
    _schoolYearCtrl.dispose();
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
      'school_year': _schoolYearCtrl.text,
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
      appBar: AppBar(
        title: Text(_isNew ? 'Add Previous School — ${widget.studentName}' : 'Edit School History — ${widget.studentName}'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.foregroundDark,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (!_isNew)
            TextButton.icon(
              onPressed: historyState.isSaving ? null : _deleteSchoolHistory,
              icon: const Icon(Icons.delete_outline_rounded, size: 18),
              label: const Text('Delete'),
              style: TextButton.styleFrom(foregroundColor: AppColors.semanticError),
            ),
          const SizedBox(width: 8),
          TextButton.icon(
            onPressed: historyState.isSaving ? null : _saveSchoolInfo,
            icon: historyState.isSaving
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.save_rounded, size: 18),
            label: const Text('Save School Info'),
            style: TextButton.styleFrom(foregroundColor: Colors.white, backgroundColor: AppColors.foregroundPrimary),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Column(
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
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.foregroundDark));
  }

  Widget _schoolInfoForm() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.borderLight)),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            Row(
              children: [
                Expanded(child: _textField(_schoolNameCtrl, 'School Name', required: true)),
                const SizedBox(width: 16),
                Expanded(child: _textField(_schoolIdCtrl, 'School ID')),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _textField(_gradeLevelCtrl, 'Grade Level', required: true)),
                const SizedBox(width: 16),
                Expanded(child: _textField(_schoolYearCtrl, 'School Year', required: true, hint: 'e.g. 2023-2024')),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _textField(_sectionCtrl, 'Section')),
                const SizedBox(width: 16),
                Expanded(child: _textField(_recordTypeCtrl, 'Record Type', required: true)),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _textField(_dateFromCtrl, 'Date From', hint: 'YYYY-MM-DD')),
                const SizedBox(width: 16),
                Expanded(child: _textField(_dateToCtrl, 'Date To', hint: 'YYYY-MM-DD')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _textField(TextEditingController controller, String label, {bool required = false, String? hint}) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(8))),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
      validator: required ? (v) => v == null || v.isEmpty ? '$label is required' : null : null,
    );
  }

  Widget _subjectsTable(PreviousSubjectsState state) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.borderLight)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Subject Records', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.foregroundDark)),
              const Spacer(),
              TextButton.icon(
                onPressed: () => _showAddSubjectDialog(),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Add Subject'),
                style: TextButton.styleFrom(foregroundColor: AppColors.foregroundPrimary),
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
                  _th('Subject'), _th('Group'), _th('Q1'), _th('Q2'), _th('Q3'), _th('Q4'), _th('Final'), _th('Descriptor'),
                ]),
                ...state.records.map((s) => TableRow(children: [
                  _td(s.subjectName),
                  _td(s.subjectGroup ?? '-'),
                  _td(s.q1Grade?.toString() ?? '-'),
                  _td(s.q2Grade?.toString() ?? '-'),
                  _td(s.q3Grade?.toString() ?? '-'),
                  _td(s.q4Grade?.toString() ?? '-'),
                  _td(s.finalGrade?.toString() ?? '-'),
                  _td(s.descriptor ?? '-'),
                ])),
              ],
            ),
        ],
      ),
    );
  }

  Widget _attendanceTable(PreviousAttendanceState state) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.borderLight)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Monthly Attendance', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.foregroundDark)),
              const Spacer(),
              TextButton.icon(
                onPressed: () => _showAddAttendanceDialog(),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Add Month'),
                style: TextButton.styleFrom(foregroundColor: AppColors.foregroundPrimary),
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
                3: FlexColumnWidth(1),
              },
              children: [
                TableRow(children: [_th('Month'), _th('School Days'), _th('Days Present'), _th('Days Absent')]),
                ...state.records.map((a) => TableRow(children: [
                  _td(a.month),
                  _td(a.schoolDays.toString()),
                  _td(a.daysPresent.toString()),
                  _td(a.daysAbsent.toString()),
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
    final q1Ctrl = TextEditingController();
    final q2Ctrl = TextEditingController();
    final q3Ctrl = TextEditingController();
    final q4Ctrl = TextEditingController();
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
              _dialogField(nameCtrl, 'Subject Name'),
              const SizedBox(height: 12),
              _dialogField(groupCtrl, 'Subject Group (optional)'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _dialogField(q1Ctrl, 'Q1', numeric: true)),
                  const SizedBox(width: 8),
                  Expanded(child: _dialogField(q2Ctrl, 'Q2', numeric: true)),
                  const SizedBox(width: 8),
                  Expanded(child: _dialogField(q3Ctrl, 'Q3', numeric: true)),
                  const SizedBox(width: 8),
                  Expanded(child: _dialogField(q4Ctrl, 'Q4', numeric: true)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _dialogField(finalCtrl, 'Final Grade', numeric: true)),
                  const SizedBox(width: 8),
                  Expanded(child: _dialogField(descriptorCtrl, 'Descriptor')),
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
                'q1_grade': int.tryParse(q1Ctrl.text),
                'q2_grade': int.tryParse(q2Ctrl.text),
                'q3_grade': int.tryParse(q3Ctrl.text),
                'q4_grade': int.tryParse(q4Ctrl.text),
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
    final daysAbsentCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Attendance Month'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _dialogField(monthCtrl, 'Month (e.g. June)'),
              const SizedBox(height: 12),
              _dialogField(schoolDaysCtrl, 'School Days', numeric: true),
              const SizedBox(height: 12),
              _dialogField(daysPresentCtrl, 'Days Present', numeric: true),
              const SizedBox(height: 12),
              _dialogField(daysAbsentCtrl, 'Days Absent', numeric: true),
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
                'days_absent': int.tryParse(daysAbsentCtrl.text) ?? 0,
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

  Widget _dialogField(TextEditingController controller, String label, {bool numeric = false}) {
    return TextField(
      controller: controller,
      keyboardType: numeric ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(8))),
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
