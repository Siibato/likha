import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/presentation/layouts/desktop/desktop_page_scaffold.dart';
import 'package:likha/presentation/widgets/desktop/teacher/shared/empty_state.dart';
import 'package:likha/presentation/widgets/desktop/teacher/shared/base_data_table.dart';
import 'package:likha/presentation/providers/student_records_provider.dart';
import 'package:likha/presentation/providers/sf9_provider.dart';
import 'package:likha/presentation/providers/document_export_provider.dart';
import 'package:likha/presentation/widgets/desktop/teacher/student_records/sf10_school_history_edit_page.dart';
import 'package:likha/domain/student_records/entities/sf10_response.dart';
import 'package:likha/domain/student_records/entities/school_history.dart';

class Sf10Section extends ConsumerStatefulWidget {
  final String classId;

  const Sf10Section({super.key, required this.classId});

  @override
  ConsumerState<Sf10Section> createState() => _Sf10SectionState();
}

class _Sf10SectionState extends ConsumerState<Sf10Section> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(generalAveragesProvider.notifier).loadStudents(widget.classId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(generalAveragesProvider);

    return DesktopPageScaffold(
      title: 'SF10 (School Form 10)',
      subtitle: 'Learner Permanent Record — complete scholastic history',
      body: state.isLoading && state.students.isEmpty
          ? const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator(color: AppColors.foregroundPrimary, strokeWidth: 2.5)))
          : state.error != null
              ? EmptyState.generic(title: 'Error loading students', subtitle: state.error ?? '')
          : state.students.isEmpty
              ? const EmptyState.generic(title: 'No students enrolled', subtitle: 'No students enrolled in this advisory class')
              : BaseDataTable(
                  items: state.students,
                  columnFlexes: const [3, 1, 1, 1],
                  columns: const [
                    DataColumn(label: Text('Student Name', style: dataTableHeaderStyle)),
                    DataColumn(label: Text('General Average', style: dataTableHeaderStyle)),
                    DataColumn(label: Text('Subject Count', style: dataTableHeaderStyle)),
                    DataColumn(label: Text('Status', style: dataTableHeaderStyle)),
                  ],
                  rowBuilder: (context, student, index) {
                    return Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Text(
                            student.studentName,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.foregroundDark),
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Text(
                            student.generalAverage?.toString() ?? 'N/A',
                            style: const TextStyle(fontSize: 14, color: AppColors.foregroundSecondary),
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Text(
                            student.subjectCount.toString(),
                            style: const TextStyle(fontSize: 14, color: AppColors.foregroundSecondary),
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: student.generalAverage != null
                                  ? AppColors.semanticSuccessAlt.withValues(alpha: 0.12)
                                  : AppColors.foregroundTertiary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              student.generalAverage != null ? 'Complete' : 'Pending',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: student.generalAverage != null ? AppColors.semanticSuccessAlt : AppColors.foregroundTertiary,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                  onTap: (student) => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => Sf10DetailPage(
                        classId: widget.classId,
                        studentId: student.studentId,
                        studentName: student.studentName,
                      ),
                    ),
                  ),
                ),
    );
  }
}

class Sf10DetailPage extends ConsumerStatefulWidget {
  final String classId;
  final String studentId;
  final String studentName;

  const Sf10DetailPage({
    super.key,
    required this.classId,
    required this.studentId,
    required this.studentName,
  });

  @override
  ConsumerState<Sf10DetailPage> createState() => _Sf10DetailPageState();
}

class _Sf10DetailPageState extends ConsumerState<Sf10DetailPage> {
  bool _isDownloading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(sf10Provider.notifier).load(widget.classId, widget.studentId);
    });
  }

  Future<void> _downloadSf10(bool isPdf) async {
    setState(() => _isDownloading = true);
    try {
      if (isPdf) {
        await ref.read(documentExportProvider.notifier).exportSf10Pdf(
          classId: widget.classId,
          studentId: widget.studentId,
          studentName: widget.studentName,
        );
      } else {
        await ref.read(documentExportProvider.notifier).exportSf10Excel(
          classId: widget.classId,
          studentId: widget.studentId,
          studentName: widget.studentName,
        );
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('SF10 ${isPdf ? 'PDF' : 'Excel'} downloaded successfully'),
            backgroundColor: AppColors.semanticSuccess,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to download SF10: $e'),
            backgroundColor: AppColors.semanticError,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(sf10Provider);

    return Scaffold(
      backgroundColor: AppColors.backgroundSecondary,
      appBar: AppBar(
        title: Text('SF10 — ${widget.studentName}'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.foregroundDark,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (state.data != null) ...[
            TextButton.icon(
              onPressed: _isDownloading ? null : () => _downloadSf10(true),
              icon: _isDownloading
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.picture_as_pdf_rounded, size: 18),
              label: Text(_isDownloading ? 'Generating...' : 'PDF'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: AppColors.accentCharcoal,
              ),
            ),
            const SizedBox(width: 8),
            TextButton.icon(
              onPressed: _isDownloading ? null : () => _downloadSf10(false),
              icon: const Icon(Icons.table_chart_rounded, size: 18),
              label: const Text('Excel'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: AppColors.semanticSuccessAlt,
              ),
            ),
            const SizedBox(width: 16),
          ],
        ],
      ),
      body: state.isLoading && state.data == null
          ? const Center(child: CircularProgressIndicator(color: AppColors.foregroundPrimary, strokeWidth: 2.5))
          : state.error != null
              ? Center(child: Text(state.error!, style: const TextStyle(color: AppColors.semanticError)))
              : state.data == null
                  ? const Center(child: Text('No data available'))
                  : _Sf10Content(data: state.data!, classId: widget.classId, studentId: widget.studentId),
    );
  }
}

class _Sf10Content extends StatelessWidget {
  final Sf10Response data;
  final String classId;
  final String studentId;

  const _Sf10Content({required this.data, required this.classId, required this.studentId});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Personal info card
              _infoCard('Learner Information', [
                _infoRow('Name', data.studentName),
                _infoRow('LRN', data.lrn ?? 'N/A'),
                _infoRow('Sex', data.sex ?? 'N/A'),
                _infoRow('Age', data.age?.toString() ?? 'N/A'),
                _infoRow('Birthdate', data.birthdate ?? 'N/A'),
                _infoRow('Birthplace', data.birthplace ?? 'N/A'),
                _infoRow('Home Address', data.homeAddress ?? 'N/A'),
                _infoRow('Father', data.fatherName ?? 'N/A'),
                _infoRow('Mother', data.motherName ?? 'N/A'),
                _infoRow('Guardian', data.guardianName ?? 'N/A'),
                _infoRow('Guardian Contact', data.guardianContact ?? 'N/A'),
                _infoRow('Track/Strand', data.trackStrand ?? 'N/A'),
                _infoRow('Curriculum', data.curriculum ?? 'N/A'),
              ]),
              const SizedBox(height: 24),
              // Scholastic records
              const Text('Scholastic Records', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.foregroundDark)),
              const SizedBox(height: 12),
              ...data.scholasticRecords.map((yr) => _yearCard(yr)),
              const SizedBox(height: 24),
              // School history
              if (data.schoolHistory.isNotEmpty) ...[
                Row(
                  children: [
                    const Text('School History', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.foregroundDark)),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => Sf10SchoolHistoryEditPage(
                            classId: classId,
                            studentId: studentId,
                            studentName: data.studentName,
                          ),
                        ),
                      ),
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('Add Previous School'),
                      style: TextButton.styleFrom(foregroundColor: AppColors.foregroundPrimary),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...data.schoolHistory.map((h) => _tappableHistoryCard(context, h)),
              ] else ...[
                Row(
                  children: [
                    const Text('School History', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.foregroundDark)),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => Sf10SchoolHistoryEditPage(
                            classId: classId,
                            studentId: studentId,
                            studentName: data.studentName,
                          ),
                        ),
                      ),
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('Add Previous School'),
                      style: TextButton.styleFrom(foregroundColor: AppColors.foregroundPrimary),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.borderLight)),
                  child: const Text('No previous school records. Click "Add Previous School" to add one.', style: TextStyle(fontSize: 13, color: AppColors.foregroundTertiary)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoCard(String title, List<Widget> rows) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.borderLight)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.foregroundDark)),
          const SizedBox(height: 16),
          ...rows,
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.foregroundSecondary)),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13, color: AppColors.foregroundDark))),
        ],
      ),
    );
  }

  Widget _yearCard(Sf10YearRecord yr) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.borderLight)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('${yr.schoolYear} — ${yr.gradeLevel}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.foregroundDark)),
              if (yr.section != null) ...[
                const SizedBox(width: 8),
                Text('(${yr.section})', style: const TextStyle(fontSize: 13, color: AppColors.foregroundSecondary)),
              ],
              const Spacer(),
              if (yr.finalAverage != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(color: AppColors.foregroundPrimary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)),
                  child: Text('Gen Avg: ${yr.finalAverage}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.foregroundPrimary)),
                ),
            ],
          ),
          if (yr.schoolName.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(yr.schoolName, style: const TextStyle(fontSize: 13, color: AppColors.foregroundSecondary)),
          ],
          const SizedBox(height: 12),
          Table(
            columnWidths: const {
              0: FlexColumnWidth(3),
              1: FlexColumnWidth(1),
              2: FlexColumnWidth(1),
              3: FlexColumnWidth(1),
              4: FlexColumnWidth(1),
              5: FlexColumnWidth(1),
              6: FlexColumnWidth(2),
            },
            children: [
              TableRow(children: [
                _th('Subject'),
                _th('Q1'), _th('Q2'), _th('Q3'), _th('Q4'),
                _th('Final'),
                _th('Descriptor'),
              ]),
              ...yr.subjects.map((s) => TableRow(children: [
                _td(s.classTitle),
                _td(s.termGrades.isNotEmpty ? s.termGrades[0]?.toString() ?? '-' : '-'),
                _td(s.termGrades.length > 1 ? s.termGrades[1]?.toString() ?? '-' : '-'),
                _td(s.termGrades.length > 2 ? s.termGrades[2]?.toString() ?? '-' : '-'),
                _td(s.termGrades.length > 3 ? s.termGrades[3]?.toString() ?? '-' : '-'),
                _td(s.finalGrade?.toString() ?? '-'),
                _td(s.descriptor ?? '-'),
              ])),
            ],
          ),
          if (yr.attendance.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text('Attendance', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.foregroundSecondary)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 12,
              runSpacing: 4,
              children: yr.attendance.map((a) => Text(
                '${a.month}: ${a.daysPresent}/${a.schoolDays}',
                style: const TextStyle(fontSize: 12, color: AppColors.foregroundSecondary),
              )).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _tappableHistoryCard(BuildContext context, Sf10SchoolHistory h) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => Sf10SchoolHistoryEditPage(
            classId: classId,
            studentId: studentId,
            studentName: data.studentName,
            schoolHistory: SchoolHistory(
              id: h.id,
              studentId: studentId,
              schoolName: h.schoolName,
              schoolId: h.schoolId,
              gradeLevel: h.gradeLevel,
              schoolYear: h.schoolYear,
              section: h.section,
              dateFrom: h.dateFrom,
              dateTo: h.dateTo,
              recordType: h.recordType,
            ),
          ),
        ),
      ),
      child: _historyCard(h),
    );
  }

  Widget _historyCard(Sf10SchoolHistory h) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.borderLight)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('${h.schoolYear} — ${h.gradeLevel}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.foregroundDark)),
              const SizedBox(width: 8),
              Text(h.schoolName, style: const TextStyle(fontSize: 13, color: AppColors.foregroundSecondary)),
            ],
          ),
          if (h.subjects.isNotEmpty) ...[
            const SizedBox(height: 12),
            Table(
              columnWidths: const {
                0: FlexColumnWidth(3),
                1: FlexColumnWidth(1),
                2: FlexColumnWidth(1),
                3: FlexColumnWidth(1),
                4: FlexColumnWidth(1),
                5: FlexColumnWidth(1),
              },
              children: [
                TableRow(children: [_th('Subject'), _th('T1'), _th('T2'), _th('T3'), _th('T4'), _th('Final')]),
                ...h.subjects.map((s) {
                  final tg = s.termGrades;
                  return TableRow(children: [
                    _td(s.subjectName),
                    _td(tg.isNotEmpty ? tg[0]?.toString() ?? '-' : '-'),
                    _td(tg.length > 1 ? tg[1]?.toString() ?? '-' : '-'),
                    _td(tg.length > 2 ? tg[2]?.toString() ?? '-' : '-'),
                    _td(tg.length > 3 ? tg[3]?.toString() ?? '-' : '-'),
                    _td(s.finalGrade?.toString() ?? '-'),
                  ]);
                }),
              ],
            ),
          ],
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
