import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/presentation/layouts/desktop/desktop_page_scaffold.dart';
import 'package:likha/presentation/widgets/desktop/teacher/shared/empty_state.dart';
import 'package:likha/presentation/providers/student_records_provider.dart';
import 'package:likha/domain/classes/entities/class_detail.dart';

const _coreValues = ['Maka-Diyos', 'Maka-tao', 'Maka-bayan', 'Maka-kalikasan'];
const _markings = ['AO', 'SO', 'NO', 'RO'];
const _periods = [1, 2, 3, 4];

class CoreValuesSection extends ConsumerStatefulWidget {
  final String classId;
  final List<Participant> students;
  final String? schoolYear;

  const CoreValuesSection({
    super.key,
    required this.classId,
    required this.students,
    this.schoolYear,
  });

  @override
  ConsumerState<CoreValuesSection> createState() => _CoreValuesSectionState();
}

class _CoreValuesSectionState extends ConsumerState<CoreValuesSection> {
  String? _selectedStudentId;
  String? _selectedStudentName;

  @override
  Widget build(BuildContext context) {
    if (widget.students.isEmpty) {
      return DesktopPageScaffold(
        title: 'Core Values',
        subtitle: 'Character development records for SF10',
        body: const EmptyState.generic(title: 'No students enrolled'),
      );
    }

    final state = ref.watch(coreValuesProvider);

    return DesktopPageScaffold(
      title: 'Core Values',
      subtitle: 'Character development records for SF10',
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
                      ref.read(coreValuesProvider.notifier).load(widget.classId, s.student.id, schoolYear: widget.schoolYear);
                    },
                  );
                },
              ),
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: _selectedStudentId == null
                ? const EmptyState.generic(title: 'Select a student', subtitle: 'Choose a student to view/edit core values')
                : _CoreValuesGrid(
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

class _CoreValuesGrid extends StatelessWidget {
  final String classId;
  final String studentId;
  final String studentName;
  final String schoolYear;
  final CoreValuesState state;
  final WidgetRef ref;

  const _CoreValuesGrid({
    required this.classId,
    required this.studentId,
    required this.studentName,
    required this.schoolYear,
    required this.state,
    required this.ref,
  });

  String? _getMarking(int period, String coreValue) {
    final rec = state.records.where((r) => r.gradingPeriodNumber == period && r.coreValue == coreValue).firstOrNull;
    return rec?.marking;
  }

  Future<void> _saveMarking(BuildContext context, int period, String coreValue, String marking) async {
    final success = await ref.read(coreValuesProvider.notifier).save(classId, studentId, {
      'class_id': classId,
      'school_year': schoolYear,
      'grading_period_number': period,
      'core_value': coreValue,
      'behavior_statement': '',
      'marking': marking,
    });
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? '$coreValue ($period) saved' : 'Failed to save'),
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
          Text(studentName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.foregroundDark)),
          if (state.error != null) ...[
            const SizedBox(height: 12),
            Text(state.error!, style: const TextStyle(fontSize: 13, color: AppColors.semanticError)),
          ],
          const SizedBox(height: 20),
          if (state.isLoading)
            const Center(child: CircularProgressIndicator(color: AppColors.foregroundPrimary, strokeWidth: 2.5))
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
                    _header('Core Value'),
                    _header('Q1'),
                    _header('Q2'),
                    _header('Q3'),
                    _header('Q4'),
                  ],
                ),
                ..._coreValues.map((cv) => TableRow(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Text(cv, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.foregroundDark)),
                    ),
                    ..._periods.map((p) => _markingCell(context, p, cv)),
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

  Widget _markingCell(BuildContext context, int period, String coreValue) {
    final current = _getMarking(period, coreValue);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
      child: DropdownButtonFormField<String>(
        value: current,
        decoration: InputDecoration(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: AppColors.borderLight)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          isDense: true,
        ),
        items: _markings.map((m) => DropdownMenuItem(value: m, child: Text(m, style: const TextStyle(fontSize: 12)))).toList(),
        onChanged: (v) => _saveMarking(context, period, coreValue, v ?? 'NO'),
      ),
    );
  }
}
