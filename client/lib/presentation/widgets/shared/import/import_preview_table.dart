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
          columnSpacing: 16,
          horizontalMargin: 16,
          columns: [
            const DataColumn(label: Text('#', style: TextStyle(fontWeight: FontWeight.w700))),
            ...columns.map((c) => DataColumn(
                  label: Text(c, style: const TextStyle(fontWeight: FontWeight.w700)),
                )),
            const DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.w700))),
            if (onRemoveRow != null)
              const DataColumn(label: Text('', style: TextStyle(fontWeight: FontWeight.w700))),
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
                DataCell(Text('${row.rowIndex}')),
                ...columns.map((c) {
                  final val = row.data[c];
                  final display = val == null ? '-' : val.toString();
                  return DataCell(Text(display));
                }),
                DataCell(
                  hasErrors
                      ? _StatusChip(
                          icon: Icons.error_outline,
                          color: AppColors.semanticError,
                          label: '${row.errors.length} error(s)',
                        )
                      : hasWarnings
                          ? _StatusChip(
                              icon: Icons.warning_amber_rounded,
                              color: AppColors.accentAmberBorder,
                              label: '${row.warnings.length} warning(s)',
                            )
                          : const _StatusChip(
                              icon: Icons.check_circle_outline,
                              color: AppColors.semanticSuccess,
                              label: 'OK',
                            ),
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

class _StatusChip extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;

  const _StatusChip({required this.icon, required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color),
        ),
      ],
    );
  }
}
