import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/presentation/widgets/mobile/teacher/grade/descriptor_badge.dart';

/// Desktop quarterly grade table with inline QG editing and stats footer.
class DesktopQuarterlyGradeTable extends StatefulWidget {
  final List<Map<String, dynamic>> summary;
  final void Function(String studentId, int grade) onQgChanged;

  const DesktopQuarterlyGradeTable({
    super.key,
    required this.summary,
    required this.onQgChanged,
  });

  @override
  State<DesktopQuarterlyGradeTable> createState() => _DesktopQuarterlyGradeTableState();
}

class _DesktopQuarterlyGradeTableState extends State<DesktopQuarterlyGradeTable> {
  String? _editingStudentId;
  final _qgEditController = TextEditingController();
  final _qgFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _qgFocusNode.addListener(() {
      if (!_qgFocusNode.hasFocus && _editingStudentId != null) {
        _commitQgEdit();
      }
    });
  }

  @override
  void dispose() {
    _qgEditController.dispose();
    _qgFocusNode.dispose();
    super.dispose();
  }

  void _startQgEdit(String studentId, int? currentGrade) {
    if (_editingStudentId != null) _commitQgEdit();
    setState(() {
      _editingStudentId = studentId;
      _qgEditController.text = currentGrade != null ? currentGrade.toString() : '';
      _qgEditController.selection = TextSelection.fromPosition(
        TextPosition(offset: _qgEditController.text.length),
      );
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _qgFocusNode.requestFocus());
  }

  void _commitQgEdit() {
    final raw = _qgEditController.text.trim();
    final grade = int.tryParse(raw);
    if (grade != null && _editingStudentId != null) {
      widget.onQgChanged(_editingStudentId!, grade);
    }
    if (mounted) setState(() => _editingStudentId = null);
  }

  void _cancelQgEdit() {
    if (mounted) setState(() => _editingStudentId = null);
  }

  static String _formatScore(dynamic value) {
    if (value == null) return '-';
    if (value is num) return value.toStringAsFixed(1);
    return value.toString();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.summary.isEmpty) {
      return const Center(
        child: Text(
          'No quarterly grades available.',
          style: TextStyle(color: AppColors.foregroundSecondary),
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(AppColors.backgroundTertiary),
              columnSpacing: 24,
              columns: const [
                DataColumn(
                  label: SizedBox(
                    width: 160,
                    child: Text('Student', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
                DataColumn(
                  label: Text('WW%', style: TextStyle(fontWeight: FontWeight.w700)),
                  numeric: true,
                ),
                DataColumn(
                  label: Text('PT%', style: TextStyle(fontWeight: FontWeight.w700)),
                  numeric: true,
                ),
                DataColumn(
                  label: Text('QA%', style: TextStyle(fontWeight: FontWeight.w700)),
                  numeric: true,
                ),
                DataColumn(
                  label: Text('QG', style: TextStyle(fontWeight: FontWeight.w700)),
                  numeric: true,
                ),
                DataColumn(
                  label: Text('Descriptor', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ],
              rows: List.generate(widget.summary.length, (index) {
                final row = widget.summary[index];
                final qg = (row['quarterly_grade'] as num?)?.toInt();
                final studentId = row['student_id']?.toString() ?? '';
                final isEven = index % 2 == 0;
                final isEditingQg = _editingStudentId == studentId;

                return DataRow(
                  color: WidgetStateProperty.all(
                    isEven ? Colors.white : AppColors.backgroundSecondary,
                  ),
                  cells: [
                    DataCell(SizedBox(
                      width: 160,
                      child: Text(
                        row['student_name']?.toString() ?? '',
                        overflow: TextOverflow.ellipsis,
                      ),
                    )),
                    DataCell(Text(_formatScore(row['ww_weighted_score']), textAlign: TextAlign.right)),
                    DataCell(Text(_formatScore(row['pt_weighted_score']), textAlign: TextAlign.right)),
                    DataCell(Text(_formatScore(row['qa_weighted_score']), textAlign: TextAlign.right)),
                    DataCell(
                      isEditingQg
                          ? SizedBox(
                              width: 56,
                              child: CallbackShortcuts(
                                bindings: {
                                  const SingleActivator(LogicalKeyboardKey.escape): _cancelQgEdit,
                                },
                                child: TextField(
                                  controller: _qgEditController,
                                  focusNode: _qgFocusNode,
                                  autofocus: true,
                                  textAlign: TextAlign.right,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                                  onSubmitted: (_) => _commitQgEdit(),
                                  decoration: InputDecoration(
                                    isDense: true,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(4),
                                      borderSide: const BorderSide(color: AppColors.accentCharcoal, width: 1.5),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(4),
                                      borderSide: const BorderSide(color: AppColors.accentCharcoal, width: 1.5),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(4),
                                      borderSide: const BorderSide(color: AppColors.accentCharcoal, width: 1.5),
                                    ),
                                  ),
                                ),
                              ),
                            )
                          : GestureDetector(
                              onTap: () => _startQgEdit(studentId, qg),
                              child: Text(
                                qg?.toString() ?? '-',
                                textAlign: TextAlign.right,
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: qg != null && qg >= 75
                                      ? AppColors.foregroundDark
                                      : AppColors.semanticError,
                                ),
                              ),
                            ),
                    ),
                    DataCell(DescriptorBadge(grade: qg)),
                  ],
                );
              }),
            ),
          ),
          const SizedBox(height: 16),
          _DesktopGradeStatsFooter(summary: widget.summary),
        ],
      ),
    );
  }
}

class _DesktopGradeStatsFooter extends StatelessWidget {
  final List<Map<String, dynamic>> summary;

  const _DesktopGradeStatsFooter({required this.summary});

  @override
  Widget build(BuildContext context) {
    final grades = summary
        .map((r) => (r['quarterly_grade'] as num?)?.toInt())
        .whereType<int>()
        .toList();

    if (grades.isEmpty) return const SizedBox.shrink();

    final average = grades.reduce((a, b) => a + b) / grades.length;
    final highest = grades.reduce((a, b) => a > b ? a : b);
    final lowest = grades.reduce((a, b) => a < b ? a : b);
    final passCount = grades.where((g) => g >= 75).length;
    final passRate = (passCount / grades.length * 100).toStringAsFixed(1);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _statItem('Average', average.toStringAsFixed(1)),
          _statItem('Highest', highest.toString()),
          _statItem('Lowest', lowest.toString()),
          _statItem('Pass Rate', '$passRate%'),
        ],
      ),
    );
  }

  Widget _statItem(String label, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.foregroundSecondary, fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.foregroundDark)),
      ],
    );
  }
}
