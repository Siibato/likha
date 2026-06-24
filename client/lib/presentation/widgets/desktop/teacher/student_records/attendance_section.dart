import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/presentation/layouts/desktop/desktop_page_scaffold.dart';
import 'package:likha/presentation/widgets/desktop/teacher/shared/empty_state.dart';
import 'package:likha/presentation/providers/student_records_provider.dart';
import 'package:likha/domain/classes/entities/class_detail.dart';
import 'package:likha/presentation/widgets/desktop/teacher/student_records/skeletons/attendance_skeleton.dart';

const _months = [
  'June', 'July', 'August', 'September', 'October', 'November',
  'December', 'January', 'February', 'March', 'April',
];

class AttendanceSection extends ConsumerStatefulWidget {
  final String classId;
  final List<Participant> students;
  final String? schoolYear;

  const AttendanceSection({
    super.key,
    required this.classId,
    required this.students,
    this.schoolYear,
  });

  @override
  ConsumerState<AttendanceSection> createState() => _AttendanceSectionState();
}

class _AttendanceSectionState extends ConsumerState<AttendanceSection> {
  String? _selectedStudentId;
  String? _selectedStudentName;

  @override
  Widget build(BuildContext context) {
    final students = List<Participant>.from(widget.students)
      ..sort((a, b) {
        final lastCmp = a.student.lastName.toLowerCase().compareTo(
            b.student.lastName.toLowerCase());
        if (lastCmp != 0) return lastCmp;
        return a.student.firstName.toLowerCase().compareTo(
            b.student.firstName.toLowerCase());
      });

    if (students.isEmpty) {
      return const DesktopPageScaffold(
        title: 'Attendance',
        subtitle: 'Monthly attendance records for SF10',
        body: EmptyState.generic(
          title: 'No students enrolled',
          subtitle: 'Students will appear here once they join the advisory class',
        ),
      );
    }

    final state = ref.watch(attendanceProvider);

    return DesktopPageScaffold(
      scrollable: false,
      title: 'Attendance',
      subtitle: 'Monthly attendance records for SF10',
      body: SizedBox.expand(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: 280,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: ListView.separated(
                  itemCount: students.length,
                  separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.borderLight),
                  itemBuilder: (context, index) {
                    final s = students[index];
                    final isSelected = s.student.id == _selectedStudentId;
                    return ListTile(
                      selected: isSelected,
                      selectedTileColor: AppColors.foregroundPrimary.withValues(alpha: 0.08),
                      leading: CircleAvatar(
                        backgroundColor: AppColors.foregroundPrimary.withValues(alpha: 0.1),
                        child: Text(
                          s.student.fullName.isNotEmpty ? s.student.fullName[0].toUpperCase() : '?',
                          style: const TextStyle(color: AppColors.foregroundPrimary, fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                      ),
                      title: Text(
                        s.student.fullName,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                          color: isSelected ? AppColors.foregroundPrimary : AppColors.foregroundDark,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onTap: () {
                        setState(() {
                          _selectedStudentId = s.student.id;
                          _selectedStudentName = s.student.fullName;
                        });
                        ref.read(attendanceProvider.notifier).load(widget.classId, s.student.id, schoolYear: widget.schoolYear);
                      },
                    );
                  },
                ),
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _BulkSchoolDaysCard(
                    classId: widget.classId,
                    studentIds: students.map((s) => s.student.id).toList(),
                    schoolYear: widget.schoolYear ?? '',
                    isBulkSaving: state.isBulkSaving,
                    ref: ref,
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: _selectedStudentId == null
                        ? const EmptyState.generic(title: 'Select a student', subtitle: 'Choose a student to view/edit attendance')
                        : SingleChildScrollView(
                            child: _AttendanceGrid(
                              key: ValueKey(_selectedStudentId),
                              classId: widget.classId,
                              studentId: _selectedStudentId!,
                              studentName: _selectedStudentName ?? 'Student',
                              schoolYear: widget.schoolYear ?? '',
                              state: state,
                              ref: ref,
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BulkSchoolDaysCard extends StatefulWidget {
  final String classId;
  final List<String> studentIds;
  final String schoolYear;
  final bool isBulkSaving;
  final WidgetRef ref;

  const _BulkSchoolDaysCard({
    required this.classId,
    required this.studentIds,
    required this.schoolYear,
    required this.isBulkSaving,
    required this.ref,
  });

  @override
  State<_BulkSchoolDaysCard> createState() => _BulkSchoolDaysCardState();
}

class _BulkSchoolDaysCardState extends State<_BulkSchoolDaysCard> {
  String? _selectedMonth;
  final _schoolDaysCtrl = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _schoolDaysCtrl.dispose();
    super.dispose();
  }

  Future<void> _applyToAll() async {
    if (_selectedMonth == null) {
      setState(() => _error = 'Select a month');
      return;
    }
    final sd = int.tryParse(_schoolDaysCtrl.text);
    if (sd == null || sd < 0) {
      setState(() => _error = 'Enter a valid number of school days');
      return;
    }
    setState(() => _error = null);

    final (allSuccess, successCount, failCount) = await widget.ref
        .read(attendanceProvider.notifier)
        .bulkSaveSchoolDays(
          classId: widget.classId,
          studentIds: widget.studentIds,
          schoolYear: widget.schoolYear,
          month: _selectedMonth!,
          schoolDays: sd,
        );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            allSuccess
                ? 'School days set to $sd for $successCount student${successCount == 1 ? '' : 's'} in $_selectedMonth'
                : 'Updated $successCount student${successCount == 1 ? '' : 's'}, $failCount failed',
          ),
          backgroundColor: allSuccess ? AppColors.semanticSuccess : AppColors.semanticError,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        children: [
          const Icon(Icons.group_rounded, size: 20, color: AppColors.foregroundPrimary),
          const SizedBox(width: 12),
          const Text(
            'Set school days for all students',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.foregroundDark),
          ),
          const SizedBox(width: 20),
          SizedBox(
            width: 140,
            child: DropdownButtonFormField<String>(
              initialValue: _selectedMonth,
              decoration: InputDecoration(
                labelText: 'Month',
                labelStyle: const TextStyle(fontSize: 12, color: AppColors.foregroundSecondary),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: AppColors.borderLight)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                isDense: true,
              ),
              items: _months.map((m) => DropdownMenuItem(value: m, child: Text(m, style: const TextStyle(fontSize: 12)))).toList(),
              onChanged: widget.isBulkSaving ? null : (v) => setState(() { _selectedMonth = v; _error = null; }),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 80,
            child: TextField(
              controller: _schoolDaysCtrl,
              keyboardType: TextInputType.number,
              enabled: !widget.isBulkSaving,
              decoration: InputDecoration(
                labelText: 'School Days',
                labelStyle: const TextStyle(fontSize: 12, color: AppColors.foregroundSecondary),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: _error != null ? AppColors.semanticError : AppColors.borderLight)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                isDense: true,
              ),
              style: const TextStyle(fontSize: 13),
              onChanged: (_) => setState(() => _error = null),
            ),
          ),
          const SizedBox(width: 12),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text(_error!, style: const TextStyle(fontSize: 12, color: AppColors.semanticError)),
            ),
          const Spacer(),
          FilledButton.icon(
            onPressed: widget.isBulkSaving ? null : _applyToAll,
            icon: widget.isBulkSaving
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.check_circle_outline, size: 18),
            label: const Text('Set for All'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.foregroundPrimary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }
}

class _AttendanceGrid extends StatefulWidget {
  final String classId;
  final String studentId;
  final String studentName;
  final String schoolYear;
  final AttendanceState state;
  final WidgetRef ref;

  const _AttendanceGrid({
    super.key,
    required this.classId,
    required this.studentId,
    required this.studentName,
    required this.schoolYear,
    required this.state,
    required this.ref,
  });

  @override
  State<_AttendanceGrid> createState() => _AttendanceGridState();
}

class _AttendanceGridState extends State<_AttendanceGrid> {
  final Map<String, TextEditingController> _schoolDaysCtrls = {};
  final Map<String, TextEditingController> _presentCtrls = {};
  final Map<String, String?> _validationErrors = {};
  bool _synced = false;
  bool _isSaving = false;
  bool _showSaved = false;
  Timer? _savedTimer;

  @override
  void didUpdateWidget(_AttendanceGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only sync when not in the middle of saving and the records list
    // identity has actually changed. Otherwise toggles like isSaving
    // trigger rebuilds that overwrite user-edited controller values.
    if (!_isSaving && oldWidget.state.records != widget.state.records) {
      _syncFromState();
    }
  }

  void _syncFromState() {
    if (!_synced || widget.state.records.isNotEmpty) {
      for (final m in _months) {
        final rec = widget.state.records.where((r) => r.month == m).firstOrNull;
        _schoolDaysCtrls[m]?.text = rec?.schoolDays.toString() ?? '';
        _presentCtrls[m]?.text = rec?.daysPresent.toString() ?? '';
      }
      _synced = true;
    }
  }

  @override
  void initState() {
    super.initState();
    for (final m in _months) {
      _schoolDaysCtrls[m] = TextEditingController();
      _presentCtrls[m] = TextEditingController();
    }
    _syncFromState();
  }

  @override
  void dispose() {
    for (final c in _schoolDaysCtrls.values) {
      c.dispose();
    }
    for (final c in _presentCtrls.values) {
      c.dispose();
    }
    _savedTimer?.cancel();
    super.dispose();
  }

  bool _validate() {
    bool valid = true;
    for (final month in _months) {
      final sd = int.tryParse(_schoolDaysCtrls[month]!.text) ?? 0;
      final dp = int.tryParse(_presentCtrls[month]!.text) ?? 0;
      if (dp > sd) {
        _validationErrors[month] = 'Cannot exceed school days';
        valid = false;
      } else {
        _validationErrors[month] = null;
      }
    }
    return valid;
  }

  Future<void> _saveAll() async {
    if (!_validate()) {
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Fix validation errors before saving'),
          backgroundColor: AppColors.semanticError,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    setState(() => _isSaving = true);
    // Snapshot controller values before any async work so that
    // _syncFromState() cannot overwrite them mid-loop.
    final snapshot = <String, (int, int)>{
      for (final month in _months)
        month: (
          int.tryParse(_schoolDaysCtrls[month]!.text) ?? 0,
          int.tryParse(_presentCtrls[month]!.text) ?? 0,
        ),
    };
    bool allSuccess = true;
    for (final month in _months) {
      final (sd, dp) = snapshot[month]!;
      final success = await widget.ref.read(attendanceProvider.notifier).save(widget.classId, widget.studentId, {
        'class_id': widget.classId,
        'school_year': widget.schoolYear,
        'month': month,
        'school_days': sd,
        'days_present': dp,
      });
      if (!success) allSuccess = false;
    }
    if (mounted) {
      setState(() {
        _isSaving = false;
        if (allSuccess) {
          _showSaved = true;
          _savedTimer?.cancel();
          _savedTimer = Timer(const Duration(seconds: 2), () {
            if (mounted) setState(() => _showSaved = false);
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
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
              Text(widget.studentName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.foregroundDark)),
              const Spacer(),
              if (_showSaved)
                const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle_rounded, size: 18, color: AppColors.semanticSuccess),
                    SizedBox(width: 6),
                    Text('Saved', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.semanticSuccess)),
                    SizedBox(width: 12),
                  ],
                ),
              FilledButton.icon(
                onPressed: _isSaving ? null : _saveAll,
                icon: _isSaving
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.save_outlined, size: 18),
                label: const Text('Save'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.foregroundPrimary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
          if (widget.state.error != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.semanticError.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)),
              child: Text(widget.state.error!, style: const TextStyle(fontSize: 13, color: AppColors.semanticError)),
            ),
          ],
          const SizedBox(height: 20),
          if (widget.state.isLoading && widget.state.records.isEmpty)
            const AttendanceSkeleton()
          else
            Table(
              columnWidths: const {
                0: FlexColumnWidth(2),
                1: FlexColumnWidth(1),
                2: FlexColumnWidth(1),
              },
              children: [
                TableRow(
                  children: [
                    _header('Month'),
                    _header('School Days'),
                    _header('Days Present'),
                  ],
                ),
                ..._months.map((m) => TableRow(
                  children: [
                    Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Text(m, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.foregroundDark))),
                    _cell(_schoolDaysCtrls[m]!, onChanged: () => _clearError(m)),
                    _cell(_presentCtrls[m]!, errorText: _validationErrors[m], onChanged: () => _clearError(m)),
                  ],
                )),
              ],
            ),
        ],
      ),
    );
  }

  Widget _header(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.foregroundSecondary)),
  );

  void _clearError(String month) {
    if (_validationErrors[month] != null) {
      setState(() => _validationErrors[month] = null);
    }
  }

  Widget _cell(TextEditingController ctrl, {String? errorText, VoidCallback? onChanged}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 36,
          child: TextField(
            controller: ctrl,
            keyboardType: TextInputType.number,
            onChanged: (_) => onChanged?.call(),
            decoration: InputDecoration(
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: errorText != null ? AppColors.semanticError : AppColors.borderLight)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              isDense: true,
            ),
            style: const TextStyle(fontSize: 13),
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: 2),
          Text(errorText, style: const TextStyle(fontSize: 11, color: AppColors.semanticError)),
        ],
      ],
    ),
  );
}
