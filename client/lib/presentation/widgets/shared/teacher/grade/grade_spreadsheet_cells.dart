import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:likha/core/theme/app_colors.dart';

/// Cell and row dimensions for the DepEd Class Record spreadsheet.
///
/// Use [GradeSpreadsheetDimensions.standard] for desktop (wide columns) and
/// [GradeSpreadsheetDimensions.compact] for mobile (narrower columns).
class GradeSpreadsheetDimensions {
  final double nameColW;
  final double scoreColW;
  final double sumColW;
  final double pctColW;
  final double initGradeW;
  final double qgColW;
  final double remarksW;
  final double rowH;
  final double hdrH1;
  final double hdrH2;

  const GradeSpreadsheetDimensions({
    required this.nameColW,
    required this.scoreColW,
    required this.sumColW,
    required this.pctColW,
    required this.initGradeW,
    required this.qgColW,
    required this.remarksW,
    required this.rowH,
    required this.hdrH1,
    required this.hdrH2,
  });

  /// Desktop — wider columns, suitable for large screens.
  const GradeSpreadsheetDimensions.standard()
      : nameColW = 180.0,
        scoreColW = 68.0,
        sumColW = 68.0,
        pctColW = 72.0,
        initGradeW = 80.0,
        qgColW = 68.0,
        remarksW = 96.0,
        rowH = 44.0,
        hdrH1 = 28.0,
        hdrH2 = 40.0;

  /// Mobile — narrower columns, suitable for small screens.
  const GradeSpreadsheetDimensions.compact()
      : nameColW = 130.0,
        scoreColW = 52.0,
        sumColW = 58.0,
        pctColW = 58.0,
        initGradeW = 66.0,
        qgColW = 56.0,
        remarksW = 76.0,
        rowH = 44.0,
        hdrH1 = 26.0,
        hdrH2 = 36.0;
}

/// Computed statistics for one grade component section.
class GradeScoreStats {
  final double? total;
  final double hs;
  final double? pct;
  final double? ws;

  const GradeScoreStats({
    required this.total,
    required this.hs,
    required this.pct,
    required this.ws,
  });
}

/// Colored group-header cell spanning an entire component section.
class GradeGroupHeaderCell extends StatelessWidget {
  final String label;
  final double width;
  final Color color;
  final double height;

  const GradeGroupHeaderCell({
    super.key,
    required this.label,
    required this.width,
    required this.color,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      color: color,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: AppColors.foregroundDark,
        ),
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
        textAlign: TextAlign.center,
      ),
    );
  }
}

/// Gray column-header cell (used for item numbers, "Total", "HS", etc.).
class GradeColumnHeaderCell extends StatelessWidget {
  final String text;
  final double width;
  final double height;
  final Alignment align;
  final EdgeInsets padding;

  const GradeColumnHeaderCell({
    super.key,
    required this.text,
    required this.width,
    required this.height,
    this.align = Alignment.center,
    this.padding = const EdgeInsets.symmetric(horizontal: 6),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      padding: padding,
      decoration: const BoxDecoration(
        color: AppColors.backgroundTertiary,
        border: Border(
          right: BorderSide(color: AppColors.borderLight, width: 0.5),
          bottom: BorderSide(color: AppColors.borderLight, width: 0.5),
        ),
      ),
      alignment: align,
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.foregroundSecondary,
        ),
        overflow: TextOverflow.ellipsis,
        maxLines: 2,
        textAlign: TextAlign.center,
      ),
    );
  }
}

/// Tappable cell showing a student's raw score.
/// [isOverride] renders the score in bold charcoal when a teacher override exists.
class GradeScoreCell extends StatelessWidget {
  final String text;
  final double width;
  final double height;
  final Color bgColor;
  final bool isOverride;
  final bool empty;

  const GradeScoreCell({
    super.key,
    required this.text,
    required this.width,
    required this.height,
    required this.bgColor,
    this.isOverride = false,
    this.empty = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: bgColor,
        border: const Border(
          right: BorderSide(color: AppColors.borderLight, width: 0.5),
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          fontWeight: isOverride ? FontWeight.w700 : FontWeight.w400,
          color: isOverride
              ? AppColors.accentCharcoal
              : (empty
                  ? AppColors.foregroundTertiary
                  : AppColors.foregroundPrimary),
        ),
      ),
    );
  }
}

/// Read-only cell showing a server-computed or derived value (gray background).
class GradeComputedCell extends StatelessWidget {
  final String text;
  final double width;
  final double height;
  final bool bold;
  final Color? color;

  const GradeComputedCell({
    super.key,
    required this.text,
    required this.width,
    required this.height,
    this.bold = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: const BoxDecoration(
        color: AppColors.backgroundTertiary,
        border: Border(
          right: BorderSide(color: AppColors.borderLight, width: 0.5),
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
          color: color ??
              (text == '--'
                  ? AppColors.foregroundTertiary
                  : AppColors.foregroundSecondary),
        ),
      ),
    );
  }
}

/// Remarks cell showing a "Passed" or "Failed" badge, or "--" when absent.
class GradeRemarksCell extends StatelessWidget {
  final String? remarks;
  final Color bgColor;
  final double width;
  final double height;

  const GradeRemarksCell({
    super.key,
    required this.remarks,
    required this.bgColor,
    required this.width,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    if (remarks == null) {
      return GradeComputedCell(text: '--', width: width, height: height);
    }
    final passed = remarks == 'Passed';
    return Container(
      width: width,
      height: height,
      color: AppColors.backgroundTertiary,
      alignment: Alignment.center,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: passed
              ? AppColors.semanticSuccessAlt.withValues(alpha: 0.12)
              : AppColors.semanticErrorDark.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          remarks!,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: passed
                ? AppColors.semanticSuccessAlt
                : AppColors.semanticErrorDark,
          ),
        ),
      ),
    );
  }
}

/// Inline text-editing cell for score or quarterly-grade input.
class GradeInlineEditCell extends StatelessWidget {
  final TextEditingController ctrl;
  final FocusNode focus;
  final VoidCallback onCommit;
  final VoidCallback onCancel;
  final double width;
  final double height;
  final Color bgColor;

  const GradeInlineEditCell({
    super.key,
    required this.ctrl,
    required this.focus,
    required this.onCommit,
    required this.onCancel,
    required this.width,
    required this.height,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        child: CallbackShortcuts(
          bindings: {const SingleActivator(LogicalKeyboardKey.escape): onCancel},
          child: TextField(
            controller: ctrl,
            focusNode: focus,
            autofocus: true,
            textAlign: TextAlign.center,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
            ],
            style: const TextStyle(fontSize: 13),
            onSubmitted: (_) => onCommit(),
            decoration: InputDecoration(
              isDense: true,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide:
                    const BorderSide(color: AppColors.accentCharcoal, width: 1.5),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide:
                    const BorderSide(color: AppColors.accentCharcoal, width: 1.5),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide:
                    const BorderSide(color: AppColors.accentCharcoal, width: 1.5),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
