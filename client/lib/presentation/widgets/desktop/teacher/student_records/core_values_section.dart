import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/core/constants/core_values_constants.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/core/utils/term_utils.dart';
import 'package:likha/presentation/layouts/desktop/desktop_page_scaffold.dart';
import 'package:likha/presentation/widgets/desktop/teacher/shared/empty_state.dart';
import 'package:likha/presentation/providers/student_records_provider.dart';
import 'package:likha/domain/classes/entities/class_detail.dart';
import 'package:likha/presentation/widgets/desktop/teacher/student_records/skeletons/core_values_skeleton.dart';

final _terms = List.generate(termCountFromType(null), (i) => i + 1);

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
      return const DesktopPageScaffold(
        title: 'Core Values',
        subtitle: 'Character development records for SF10',
        body: EmptyState.generic(
          title: 'No students enrolled',
          subtitle: 'Students will appear here once they join the advisory class',
        ),
      );
    }

    final state = ref.watch(coreValuesProvider);

    return DesktopPageScaffold(
      scrollable: false,
      title: 'Core Values',
      subtitle: 'Character development records for SF10',
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
                  itemCount: widget.students.length,
                  separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.borderLight),
                  itemBuilder: (context, index) {
                    final s = widget.students[index];
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
                  : SingleChildScrollView(
                      child: _CoreValuesGrid(
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
    super.key,
    required this.classId,
    required this.studentId,
    required this.studentName,
    required this.schoolYear,
    required this.state,
    required this.ref,
  });

  String? _getMarking(int term, int statementId) {
    final rec = state.records.where((r) => r.termNumber == term && r.coreValueId == statementId).firstOrNull;
    return rec?.marking;
  }

  Future<void> _saveMarking(BuildContext context, int term, int statementId, String label) async {
    final success = await ref.read(coreValuesProvider.notifier).save(classId, studentId, {
      'class_id': classId,
      'school_year': schoolYear,
      'term_number': term,
      'core_value_id': statementId,
      'marking': label,
    });
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Statement #$statementId (T$term) saved' : 'Failed to save'),
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
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(studentName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.foregroundDark)),
          if (state.error != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.semanticError.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)),
              child: Text(state.error!, style: const TextStyle(fontSize: 13, color: AppColors.semanticError)),
            ),
          ],
          const SizedBox(height: 20),
          if (state.isLoading && state.records.isEmpty)
            const CoreValuesSkeleton()
          else
            ...coreValueNames.map((cvName) {
              final stmts = statementsForCoreValue(cvName);
              return Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(cvName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.foregroundDark)),
                    const SizedBox(height: 12),
                    Table(
                      columnWidths: {
                        0: const FlexColumnWidth(3),
                        ...Map.fromEntries(_terms.asMap().entries.map((e) => MapEntry(e.key + 1, const FlexColumnWidth(1)))),
                      },
                      children: [
                        TableRow(
                          children: [
                            _header('Behavior Statement'),
                            ..._terms.map((t) => _header('T$t')),
                          ],
                        ),
                        ...stmts.map((stmt) => TableRow(
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              child: Text(stmt.statement, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: AppColors.foregroundDark)),
                            ),
                            ..._terms.map((t) => _markingCell(context, t, stmt.id)),
                          ],
                        )),
                      ],
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _header(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.foregroundSecondary)),
  );

  Widget _markingCell(BuildContext context, int term, int statementId) {
    final current = _getMarking(term, statementId);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
      child: DropdownButtonFormField<String>(
        initialValue: current,
        decoration: InputDecoration(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: AppColors.borderLight)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          isDense: true,
        ),
        items: coreValueMarkings.map((m) => DropdownMenuItem(value: m, child: Text(m, style: const TextStyle(fontSize: 12)))).toList(),
        onChanged: (v) => _saveMarking(context, term, statementId, v ?? 'NO'),
      ),
    );
  }
}
