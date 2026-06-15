import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/domain/tos/entities/tos_entity.dart';
import 'package:likha/presentation/widgets/mobile/teacher/tos/tos_table_cells.dart';

/// Renders all cells for a single TOS competency row.
///
/// Editing state is managed by the parent [TosGridTable]. The parent passes
/// down [editingCellKey] and callbacks so only one cell is active at a time
/// across all rows.
class TosCompetencyDataRow extends StatelessWidget {
  final TosCompetency competency;
  final TableOfSpecifications tos;
  final int targetItems;
  final double competencyWidth;
  final int totalDays;

  /// Active cell key from parent: "{fieldType}_{competencyId}"
  final String? editingCellKey;
  final TextEditingController editController;
  final FocusNode focusNode;
  final bool inlineMode;

  final void Function(String competencyId, String fieldType, String value) onStartEdit;
  final VoidCallback onCommitEdit;
  final VoidCallback onCancelEdit;
  final void Function(String competencyId, String levelKey, int? currentOverride)? onCellTap;

  const TosCompetencyDataRow({
    super.key,
    required this.competency,
    required this.tos,
    required this.targetItems,
    required this.competencyWidth,
    required this.totalDays,
    required this.editingCellKey,
    required this.editController,
    required this.focusNode,
    required this.inlineMode,
    required this.onStartEdit,
    required this.onCommitEdit,
    required this.onCancelEdit,
    this.onCellTap,
  });

  bool get _isBloomsMode => tos.classificationMode == 'blooms';

  double get _cogColWidth => _isBloomsMode ? 80 : 48;

  @override
  Widget build(BuildContext context) {
    final weight = totalDays > 0
        ? competency.timeUnitsTaught / totalDays * 100
        : 0.0;

    return Row(
      children: [
        _competencyCell(),
        _daysCell(),
        TosTableCells.staticCell(
          '${weight.toStringAsFixed(1)}%',
          72,
          align: TextAlign.center,
        ),
        ..._buildCognitiveCells(),
        TosTableCells.staticCell(
          '$_rowTotal',
          56,
          align: TextAlign.center,
          bold: true,
        ),
      ],
    );
  }

  int get _rowTotal {
    if (_isBloomsMode) {
      final r = competency.rememberingCount ?? (targetItems * tos.rememberingPercentage / 100).round();
      final u = competency.understandingCount ?? (targetItems * tos.understandingPercentage / 100).round();
      final ap = competency.applyingCount ?? (targetItems * tos.applyingPercentage / 100).round();
      final an = competency.analyzingCount ?? (targetItems * tos.analyzingPercentage / 100).round();
      final e = competency.evaluatingCount ?? (targetItems * tos.evaluatingPercentage / 100).round();
      final bl = competency.creatingCount ?? (targetItems * tos.creatingPercentage / 100).round();
      return r + u + ap + an + e + bl;
    }
    final easy = competency.easyCount ?? (targetItems * tos.easyPercentage / 100).round();
    final med = competency.mediumCount ?? (targetItems * tos.mediumPercentage / 100).round();
    final hard = competency.hardCount ?? (targetItems * tos.hardPercentage / 100).round();
    return easy + med + hard;
  }

  Widget _competencyCell() {
    final label = competency.competencyCode != null
        ? '${competency.competencyCode} - ${competency.competencyText}'
        : competency.competencyText;
    final cellKey = 'competency_${competency.id}';

    if (inlineMode) {
      if (editingCellKey == cellKey) {
        return _inlineTextField(width: competencyWidth, isNumeric: false);
      }
      return MouseRegion(
        cursor: SystemMouseCursors.text,
        child: GestureDetector(
          onTap: () => onStartEdit(competency.id, 'competency', competency.competencyText),
          child: TosTableCells.textCell(label, competencyWidth, maxLines: 2),
        ),
      );
    }

    return TosTableCells.staticCell(label, competencyWidth, maxLines: 2);
  }

  Widget _daysCell() {
    final cellKey = 'days_${competency.id}';

    if (inlineMode) {
      if (editingCellKey == cellKey) {
        return _inlineTextField(width: 56, isNumeric: true);
      }
      return MouseRegion(
        cursor: SystemMouseCursors.text,
        child: GestureDetector(
          onTap: () => onStartEdit(competency.id, 'days', '${competency.timeUnitsTaught}'),
          child: TosTableCells.textCell('${competency.timeUnitsTaught}', 56, align: TextAlign.center),
        ),
      );
    }

    return TosTableCells.staticCell('${competency.timeUnitsTaught}', 56, align: TextAlign.center);
  }

  List<Widget> _buildCognitiveCells() {
    final easy = competency.easyCount ?? (targetItems * tos.easyPercentage / 100).round();
    final medium = competency.mediumCount ?? (targetItems * tos.mediumPercentage / 100).round();
    final hard = competency.hardCount ?? (targetItems * tos.hardPercentage / 100).round();

    if (!_isBloomsMode) {
      return [
        _cognitiveCell('easy', '$easy', competency.easyCount != null),
        _cognitiveCell('medium', '$medium', competency.mediumCount != null),
        _cognitiveCell('hard', '$hard', competency.hardCount != null),
      ];
    }

    final r = competency.rememberingCount ?? (targetItems * tos.rememberingPercentage / 100).round();
    final u = competency.understandingCount ?? (targetItems * tos.understandingPercentage / 100).round();
    final ap = competency.applyingCount ?? (targetItems * tos.applyingPercentage / 100).round();
    final an = competency.analyzingCount ?? (targetItems * tos.analyzingPercentage / 100).round();
    final e = competency.evaluatingCount ?? (targetItems * tos.evaluatingPercentage / 100).round();
    final bl = competency.creatingCount ?? (targetItems * tos.creatingPercentage / 100).round();

    return [
      _cognitiveCell('remembering', '$r', competency.rememberingCount != null),
      _cognitiveCell('understanding', '$u', competency.understandingCount != null),
      _cognitiveCell('applying', '$ap', competency.applyingCount != null),
      _cognitiveCell('analyzing', '$an', competency.analyzingCount != null),
      _cognitiveCell('evaluating', '$e', competency.evaluatingCount != null),
      _cognitiveCell('creating', '$bl', competency.creatingCount != null),
    ];
  }

  Widget _cognitiveCell(String levelKey, String displayValue, bool isOverride) {
    final cellKey = '${levelKey}_${competency.id}';

    if (inlineMode) {
      if (editingCellKey == cellKey) {
        return _inlineTextField(width: _cogColWidth, isNumeric: true);
      }
      final overrideForLevel = _overrideForLevel(levelKey);
      return MouseRegion(
        cursor: SystemMouseCursors.text,
        child: GestureDetector(
          onTap: () => onStartEdit(
            competency.id,
            levelKey,
            overrideForLevel?.toString() ?? displayValue,
          ),
          child: SizedBox(
            width: _cogColWidth,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
              child: Text(
                displayValue,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isOverride ? FontWeight.w700 : FontWeight.w400,
                  color: AppColors.accentCharcoal,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: onCellTap == null
          ? null
          : () => onCellTap!(competency.id, levelKey, _overrideForLevel(levelKey)),
      child: SizedBox(
        width: _cogColWidth,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
          child: Text(
            displayValue,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isOverride ? FontWeight.w700 : FontWeight.w400,
              color: AppColors.accentCharcoal,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  int? _overrideForLevel(String levelKey) => switch (levelKey) {
        'easy' => competency.easyCount,
        'medium' => competency.mediumCount,
        'hard' => competency.hardCount,
        'remembering' => competency.rememberingCount,
        'understanding' => competency.understandingCount,
        'applying' => competency.applyingCount,
        'analyzing' => competency.analyzingCount,
        'evaluating' => competency.evaluatingCount,
        'creating' => competency.creatingCount,
        _ => null,
      };

  Widget _inlineTextField({required double width, required bool isNumeric}) {
    return SizedBox(
      width: width,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        child: CallbackShortcuts(
          bindings: {
            const SingleActivator(LogicalKeyboardKey.escape): onCancelEdit,
          },
          child: TextField(
            controller: editController,
            focusNode: focusNode,
            autofocus: true,
            textAlign: TextAlign.center,
            keyboardType: isNumeric
                ? const TextInputType.numberWithOptions(decimal: false)
                : TextInputType.text,
            style: const TextStyle(fontSize: 12),
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
              isDense: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: const BorderSide(color: AppColors.accentCharcoal),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: const BorderSide(color: AppColors.accentCharcoal, width: 1.5),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: const BorderSide(color: AppColors.accentCharcoal),
              ),
            ),
            onSubmitted: (_) => onCommitEdit(),
          ),
        ),
      ),
    );
  }
}
