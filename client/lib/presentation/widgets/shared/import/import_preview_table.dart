import 'package:flutter/material.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/data/models/import/import_preview_model.dart';

class ImportPreviewTable extends StatelessWidget {
  final PreviewResponseModel preview;
  final List<String> columns;
  final void Function(int rowIndex)? onRemoveRow;

  const ImportPreviewTable({
    super.key,
    required this.preview,
    required this.columns,
    this.onRemoveRow,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columnSpacing: 20,
          horizontalMargin: 16,
          headingRowHeight: 40,
          dataRowMinHeight: 48,
          dataRowMaxHeight: 72,
          columns: [
            const DataColumn(
              label: Text('#', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
            ),
            ...columns.map((c) => DataColumn(
                  label: Text(c, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                )),
            const DataColumn(
              label: Text('Status', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
            ),
            if (onRemoveRow != null)
              const DataColumn(label: SizedBox.shrink()),
          ],
          rows: preview.rows.map((row) {
            final hasErrors = row.hasErrors;
            final hasWarnings = row.hasWarnings;

            return DataRow(
              color: hasErrors
                  ? WidgetStateProperty.all(AppColors.semanticErrorBackground.withValues(alpha: 0.1))
                  : hasWarnings
                      ? WidgetStateProperty.all(AppColors.accentAmberSurface.withValues(alpha: 0.1))
                      : null,
              cells: [
                DataCell(Text('${row.rowIndex}', style: const TextStyle(fontSize: 13))),
                ...columns.map((c) {
                  final val = row.data[c];
                  final display = val == null ? '-' : val.toString();
                  return DataCell(
                    Text(
                      display,
                      style: TextStyle(
                        fontSize: 13,
                        color: display == '-' ? AppColors.foregroundTertiary : AppColors.foregroundDark,
                      ),
                    ),
                  );
                }),
                DataCell(
                  hasErrors
                      ? _ErrorPill(messages: row.errors)
                      : hasWarnings
                          ? _ErrorPill(messages: row.warnings, isWarning: true)
                          : const _ErrorPill(messages: ['Valid'], isValid: true),
                ),
                if (onRemoveRow != null)
                  DataCell(
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 16),
                      color: AppColors.foregroundTertiary,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => onRemoveRow!(row.rowIndex),
                    ),
                  ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _ErrorPill extends StatelessWidget {
  final List<String> messages;
  final bool isWarning;
  final bool isValid;

  const _ErrorPill({
    required this.messages,
    this.isWarning = false,
    this.isValid = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isValid) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle_outline, size: 14, color: AppColors.semanticSuccess),
          const SizedBox(width: 4),
          Text(
            'Valid',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.semanticSuccess),
          ),
        ],
      );
    }

    final color = isWarning ? AppColors.accentAmberBorder : AppColors.semanticError;
    final icon = isWarning ? Icons.warning_amber_rounded : Icons.error_outline;
    final text = messages.join(', ');

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(icon, size: 14, color: color),
        ),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            text,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: color, height: 1.3),
            softWrap: true,
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          ),
        ),
      ],
    );
  }
}
