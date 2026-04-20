import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/domain/tos/entities/tos_entity.dart';
import 'package:likha/presentation/pages/desktop/core/desktop_page_scaffold.dart';
import 'package:likha/presentation/pages/desktop/teacher/tos/edit_tos_desktop.dart';
import 'package:likha/presentation/pages/shared/widgets/cards/info_panel.dart';
import 'package:likha/presentation/pages/shared/widgets/dialogs/app_dialogs.dart';
import 'package:likha/presentation/pages/shared/widgets/forms/styled_text_field.dart';
import 'package:likha/presentation/widgets/styled_dialog.dart';
import 'package:likha/presentation/pages/teacher/assessment/widgets/bulk_paste_sheet.dart';
import 'package:likha/presentation/pages/desktop/teacher/tos/widgets/melcs_search_dialog.dart';
import 'package:likha/presentation/pages/teacher/tos/widgets/tos_grid_table.dart';
import 'package:likha/presentation/pages/teacher/tos/widgets/tos_print_preview.dart';
import 'package:likha/presentation/pages/teacher/tos/widgets/tos_summary_row.dart';
import 'package:likha/presentation/providers/tos_provider.dart';

class TosDetailDesktop extends ConsumerStatefulWidget {
  final String tosId;
  final String classId;

  const TosDetailDesktop({
    super.key,
    required this.tosId,
    required this.classId,
  });

  @override
  ConsumerState<TosDetailDesktop> createState() => _TosDetailDesktopState();
}

class _TosDetailDesktopState extends ConsumerState<TosDetailDesktop> {
  final _competencyController = TextEditingController();
  final _timeUnitsTaughtController = TextEditingController();
  final _editCompetencyController = TextEditingController();
  final _editDaysTaughtController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(tosProvider.notifier).loadTosDetail(widget.tosId);
    });
  }

  @override
  void dispose() {
    _competencyController.dispose();
    _timeUnitsTaughtController.dispose();
    _editCompetencyController.dispose();
    _editDaysTaughtController.dispose();
    super.dispose();
  }

  void _handleEdit(TableOfSpecifications tos) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => EditTosDesktop(tos: tos)),
    ).then((_) {
      ref.read(tosProvider.notifier).loadTosDetail(widget.tosId);
    });
  }

  void _handlePrint(
      TableOfSpecifications tos, List<TosCompetency> competencies) {
    TosPrintService.printTos(context, tos, competencies);
  }

  void _handleDelete() {
    AppDialogs.showDestructive(
      context: context,
      title: 'Delete TOS',
      body:
          'This will permanently delete this Table of Specifications and all its competencies.',
      confirmLabel: 'Delete',
      onConfirm: () async {
        await ref.read(tosProvider.notifier).deleteTos(widget.tosId);
        if (mounted) Navigator.pop(context);
      },
    );
  }

  void _handleAddCompetency(String timeUnit) {
    _competencyController.clear();
    _timeUnitsTaughtController.text = '1';
    final unitLabel = timeUnit == 'hours' ? 'Hours' : 'Days';
    showDialog(
      context: context,
      builder: (ctx) => StyledDialog(
        title: 'Add Competency',
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            StyledTextField(
              controller: _competencyController,
              label: 'Competency description',
              icon: Icons.edit_rounded,
            ),
            const SizedBox(height: 12),
            StyledTextField(
              controller: _timeUnitsTaughtController,
              label: '$unitLabel taught',
              icon: Icons.schedule_outlined,
              keyboardType: TextInputType.number,
              hintText: '1',
            ),
          ],
        ),
        actions: [
          StyledDialogAction(
            label: 'Cancel',
            onPressed: () => Navigator.pop(ctx),
          ),
          StyledDialogAction(
            label: 'Add',
            isPrimary: true,
            onPressed: () {
              Navigator.pop(ctx);
              final text = _competencyController.text;
              if (text.trim().isNotEmpty) {
                ref.read(tosProvider.notifier).addCompetency(
                  widget.tosId,
                  {
                    'competency_text': text.trim(),
                    'days_taught': int.tryParse(_timeUnitsTaughtController.text.trim()) ?? 1,
                    'order_index': ref.read(tosProvider).competencies.length,
                  },
                );
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(tosProvider);
    final tos = state.currentTos;
    final competencies = state.competencies;

    ref.listen<TosState>(tosProvider, (prev, next) {
      if (next.successMessage != null &&
          prev?.successMessage != next.successMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.successMessage!),
            backgroundColor: AppColors.semanticSuccess,
          ),
        );
        ref.read(tosProvider.notifier).clearMessages();
      }
      if (next.error != null && prev?.error != next.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: AppColors.semanticError,
          ),
        );
        ref.read(tosProvider.notifier).clearMessages();
      }
    });

    return Scaffold(
      backgroundColor: AppColors.backgroundSecondary,
      body: DesktopPageScaffold(
        title: tos?.title ?? 'TOS Detail',
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
          tooltip: 'Back',
        ),
        actions: [
          if (tos != null) ...[
            FilledButton.tonalIcon(
              onPressed: () => _handleEdit(tos),
              icon: const Icon(Icons.edit_outlined, size: 18),
              label: const Text('Edit'),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: () => _handlePrint(tos, competencies),
              icon: const Icon(Icons.print_outlined),
              tooltip: 'Print',
            ),
            const SizedBox(width: 4),
            IconButton(
              onPressed: _handleDelete,
              icon: const Icon(Icons.delete_outline_rounded,
                  color: AppColors.semanticError),
              tooltip: 'Delete',
            ),
          ],
        ],
        body: state.isLoading && tos == null
            ? const Center(
                child: CircularProgressIndicator(
                  color: AppColors.foregroundPrimary,
                  strokeWidth: 2.5,
                ),
              )
            : tos == null
                ? const Center(child: Text('TOS not found'))
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left column: Settings + Competencies
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Settings card
                            _buildSettingsPanel(tos, competencies),
                            const SizedBox(height: 20),

                            // Competencies header
                            const Text(
                              'Competencies',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: AppColors.foregroundDark,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Competency list
                            if (competencies.isEmpty)
                              Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border:
                                      Border.all(color: AppColors.borderLight),
                                ),
                                child: const Center(
                                  child: Text(
                                    'No competencies added yet.',
                                    style: TextStyle(
                                      color: AppColors.foregroundSecondary,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              )
                            else
                              ...competencies.map(
                                  (c) => _buildCompetencyTile(c, tos.timeUnit)),

                            const SizedBox(height: 16),

                            // Action buttons
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                OutlinedButton.icon(
                                  onPressed: () => _handleAddCompetency(tos.timeUnit),
                                  icon: const Icon(Icons.add, size: 18),
                                  label: const Text('Add Competency'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor:
                                        AppColors.foregroundPrimary,
                                    side: const BorderSide(
                                        color: AppColors.borderLight),
                                  ),
                                ),
                                OutlinedButton.icon(
                                  onPressed: () => MelcsSearchDialog.show(
                                      context, widget.tosId),
                                  icon: const Icon(Icons.search, size: 18),
                                  label: const Text('Import from MELCs'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor:
                                        AppColors.foregroundPrimary,
                                    side: const BorderSide(
                                        color: AppColors.borderLight),
                                  ),
                                ),
                                OutlinedButton.icon(
                                  onPressed: () => BulkPasteSheet.show(
                                      context, widget.tosId),
                                  icon: const Icon(Icons.paste, size: 18),
                                  label: const Text('Bulk Paste'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor:
                                        AppColors.foregroundPrimary,
                                    side: const BorderSide(
                                        color: AppColors.borderLight),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 24),

                      // Right column: TOS Matrix
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Specification Grid',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: AppColors.foregroundDark,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 12),
                            if (competencies.isEmpty)
                              Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border:
                                      Border.all(color: AppColors.borderLight),
                                ),
                                child: const Center(
                                  child: Text(
                                    'Add competencies to see the grid.',
                                    style: TextStyle(
                                      color: AppColors.foregroundSecondary,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              )
                            else ...[
                              TosGridTable(
                                competencies: competencies,
                                tos: tos,
                                onCellChanged: (id, key, val) => ref
                                    .read(tosProvider.notifier)
                                    .updateCompetency(
                                        id, {'${key}_count': val}),
                                onCompetencyTextChanged: (id, text) => ref
                                    .read(tosProvider.notifier)
                                    .updateCompetency(
                                        id, {'competency_text': text}),
                                onDaysTaughtChanged: (id, days) => ref
                                    .read(tosProvider.notifier)
                                    .updateCompetency(
                                        id, {'days_taught': days}),
                              ),
                              const SizedBox(height: 12),
                              TosSummaryRow(
                                competencies: competencies,
                                totalItems: tos.totalItems,
                                timeUnit: tos.timeUnit,
                              ),
                              _buildMissingPointsBanner(competencies, tos),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }

  Widget _buildSettingsPanel(
      TableOfSpecifications tos, List<TosCompetency> competencies) {
    final modeLabel = tos.classificationMode == 'blooms'
        ? "Bloom's Taxonomy"
        : 'Difficulty Level';
    final totalDays =
        competencies.fold<int>(0, (sum, c) => sum + c.timeUnitsTaught);

    return InfoPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Settings',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.foregroundDark,
            ),
          ),
          const SizedBox(height: 12),
          _settingsRow('Quarter', 'Q${tos.gradingPeriodNumber}'),
          _settingsRow('Mode', modeLabel),
          _settingsRow('Total Items', '${tos.totalItems}'),
          _settingsRow('Competencies', '${competencies.length}'),
          _settingsRow('Total ${tos.timeUnit == 'hours' ? 'Hours' : 'Days'}', '$totalDays'),
        ],
      ),
    );
  }

  Widget _settingsRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.foregroundSecondary,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.foregroundPrimary,
            ),
          ),
        ],
      ),
    );
  }

  void _handleEditCompetency(TosCompetency competency, String timeUnit) {
    _editCompetencyController.text = competency.competencyText;
    _editDaysTaughtController.text = '${competency.timeUnitsTaught}';
    final unitLabel = timeUnit == 'hours' ? 'Hours' : 'Days';
    showDialog(
      context: context,
      builder: (ctx) => StyledDialog(
        title: 'Edit Competency',
        leadingAction: StyledDialogAction(
          label: 'Delete',
          onPressed: () {
            Navigator.pop(ctx);
            AppDialogs.showDestructive(
              context: context,
              title: 'Delete Competency',
              body: 'Remove this competency?',
              confirmLabel: 'Delete',
              onConfirm: () => ref
                  .read(tosProvider.notifier)
                  .deleteCompetency(competency.id),
            );
          },
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            StyledTextField(
              controller: _editCompetencyController,
              label: 'Competency description',
              icon: Icons.edit_rounded,
            ),
            const SizedBox(height: 12),
            StyledTextField(
              controller: _editDaysTaughtController,
              label: '$unitLabel taught',
              icon: Icons.schedule_outlined,
              keyboardType: TextInputType.number,
              hintText: '1',
            ),
          ],
        ),
        actions: [
          StyledDialogAction(
            label: 'Cancel',
            onPressed: () => Navigator.pop(ctx),
          ),
          StyledDialogAction(
            label: 'Save',
            isPrimary: true,
            onPressed: () {
              Navigator.pop(ctx);
              final text = _editCompetencyController.text.trim();
              final days = int.tryParse(_editDaysTaughtController.text.trim());
              if (text.isNotEmpty) {
                ref.read(tosProvider.notifier).updateCompetency(
                  competency.id,
                  {
                    'competency_text': text,
                    if (days != null) 'days_taught': days,
                  },
                );
              }
            },
          ),
        ],
      ),
    );
  }

Widget _buildCompetencyTile(TosCompetency competency, String timeUnit) {
    return GestureDetector(
      onTap: () => _handleEditCompetency(competency, timeUnit),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    competency.competencyText,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.foregroundPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${competency.timeUnitsTaught} ${timeUnit == 'hours' ? (competency.timeUnitsTaught == 1 ? 'hour' : 'hours') : (competency.timeUnitsTaught == 1 ? 'day' : 'days')} taught',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.foregroundSecondary,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () => _handleEditCompetency(competency, timeUnit),
              icon: const Icon(Icons.edit_outlined, size: 18),
              color: AppColors.foregroundSecondary,
              tooltip: 'Edit',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMissingPointsBanner(
      List<TosCompetency> competencies, TableOfSpecifications tos) {
    final totalDays =
        competencies.fold<int>(0, (sum, c) => sum + c.timeUnitsTaught);

    // Use the SAME formula as the grid: sum of actual cognitive cells per row.
    // This respects per-competency overrides so banner and grid always agree.
    final isBloomsMode = tos.classificationMode == 'blooms';
    final assigned = competencies.fold<int>(0, (sum, c) {
      if (totalDays == 0) return sum;
      final targetItems =
          (c.timeUnitsTaught / totalDays * tos.totalItems).round();
      if (isBloomsMode) {
        final r = c.rememberingCount ?? (targetItems * tos.rememberingPercentage / 100).round();
        final u = c.understandingCount ?? (targetItems * tos.understandingPercentage / 100).round();
        final ap = c.applyingCount ?? (targetItems * tos.applyingPercentage / 100).round();
        final an = c.analyzingCount ?? (targetItems * tos.analyzingPercentage / 100).round();
        final e = c.evaluatingCount ?? (targetItems * tos.evaluatingPercentage / 100).round();
        final bl = c.creatingCount ?? (targetItems * tos.creatingPercentage / 100).round();
        return sum + r + u + ap + an + e + bl;
      }
      final easy = c.easyCount ?? (targetItems * tos.easyPercentage / 100).round();
      final medium = c.mediumCount ?? (targetItems * tos.mediumPercentage / 100).round();
      final hard = c.hardCount ?? (targetItems * tos.hardPercentage / 100).round();
      return sum + easy + medium + hard;
    });

    final diff = tos.totalItems - assigned;
    if (diff == 0) return const SizedBox.shrink();

    final message = diff > 0
        ? '$diff item${diff == 1 ? '' : 's'} under target. '
            'Total assigned: $assigned / ${tos.totalItems}'
        : '${-diff} item${-diff == 1 ? '' : 's'} over target. '
            'Total assigned: $assigned / ${tos.totalItems}';

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF3E0),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFFF9800)),
        ),
        child: Row(
          children: [
            const Icon(Icons.warning_amber_outlined,
                size: 16, color: Color(0xFFE65100)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF6D4C41),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
