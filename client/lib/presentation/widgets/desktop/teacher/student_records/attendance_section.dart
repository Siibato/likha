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
    if (widget.students.isEmpty) {
      return const DesktopPageScaffold(
        title: 'Attendance',
        subtitle: 'Monthly attendance records for SF10',
        body: EmptyState.generic(title: 'No students enrolled'),
      );
    }

    final state = ref.watch(attendanceProvider);

    return DesktopPageScaffold(
      title: 'Attendance',
      subtitle: 'Monthly attendance records for SF10',
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
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
                shrinkWrap: true,
                itemCount: widget.students.length,
                separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.borderLight),
                itemBuilder: (context, index) {
                  final s = widget.students[index];
                  final isSelected = s.student.id == _selectedStudentId;
                  return ListTile(
                    selected: isSelected,
                    selectedTileColor: AppColors.foregroundPrimary.withValues(alpha: 0.08),
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
            child: _selectedStudentId == null
                ? const EmptyState.generic(title: 'Select a student', subtitle: 'Choose a student to view/edit attendance')
                : _AttendanceGrid(
                    key: ValueKey(_selectedStudentId),
                    classId: widget.classId,
                    studentId: _selectedStudentId!,
                    studentName: _selectedStudentName ?? 'Student',
                    schoolYear: widget.schoolYear ?? '',
                    state: state,
                    ref: ref,
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
  final Map<String, TextEditingController> _absentCtrls = {};
  bool _synced = false;

  @override
  void didUpdateWidget(_AttendanceGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncFromState();
  }

  void _syncFromState() {
    if (!_synced || widget.state.records.isNotEmpty) {
      for (final m in _months) {
        final rec = widget.state.records.where((r) => r.month == m).firstOrNull;
        _schoolDaysCtrls[m]?.text = rec?.schoolDays.toString() ?? '';
        _presentCtrls[m]?.text = rec?.daysPresent.toString() ?? '';
        _absentCtrls[m]?.text = rec?.daysAbsent.toString() ?? '';
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
      _absentCtrls[m] = TextEditingController();
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
    for (final c in _absentCtrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _saveMonth(String month) async {
    final sd = int.tryParse(_schoolDaysCtrls[month]!.text) ?? 0;
    final dp = int.tryParse(_presentCtrls[month]!.text) ?? 0;
    final da = int.tryParse(_absentCtrls[month]!.text) ?? 0;
    final success = await widget.ref.read(attendanceProvider.notifier).save(widget.classId, widget.studentId, {
      'class_id': widget.classId,
      'school_year': widget.schoolYear,
      'month': month,
      'school_days': sd,
      'days_present': dp,
      'days_absent': da,
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? '$month attendance saved' : 'Failed to save'),
          backgroundColor: success ? AppColors.semanticSuccessAlt : AppColors.semanticError,
          duration: const Duration(seconds: 2),
        ),
      );
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
        children: [
          Text(widget.studentName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.foregroundDark)),
          if (widget.state.error != null) ...[
            const SizedBox(height: 12),
            Text(widget.state.error!, style: const TextStyle(fontSize: 13, color: AppColors.semanticError)),
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
                3: FlexColumnWidth(1),
                4: FlexColumnWidth(1),
              },
              children: [
                TableRow(
                  children: [
                    _header('Month'),
                    _header('School Days'),
                    _header('Days Present'),
                    _header('Days Absent'),
                    _header(''),
                  ],
                ),
                ..._months.map((m) => TableRow(
                  children: [
                    Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Text(m, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.foregroundDark))),
                    _cell(_schoolDaysCtrls[m]!),
                    _cell(_presentCtrls[m]!),
                    _cell(_absentCtrls[m]!),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: TextButton(
                        onPressed: () => _saveMonth(m),
                        child: const Text('Save', style: TextStyle(fontSize: 12, color: AppColors.foregroundPrimary)),
                      ),
                    ),
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

  Widget _cell(TextEditingController ctrl) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
    child: SizedBox(
      height: 36,
      child: TextField(
        controller: ctrl,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: AppColors.borderLight)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          isDense: true,
        ),
        style: const TextStyle(fontSize: 13),
      ),
    ),
  );
}
