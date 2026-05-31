import 'package:flutter/material.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/presentation/pages/shared/class_section_header.dart';
import 'package:likha/presentation/widgets/shared/dialogs/app_dialogs.dart';
import 'package:likha/presentation/widgets/shared/forms/styled_text_field.dart';
import 'package:likha/presentation/widgets/shared/dialogs/styled_dialog.dart';
import 'package:likha/presentation/pages/teacher/tos/edit_tos_page.dart';
import 'package:likha/presentation/widgets/mobile/teacher/assessment/bulk_paste_sheet.dart';
import 'package:likha/presentation/widgets/mobile/teacher/assessment/melcs_search_sheet.dart';
import 'package:likha/presentation/widgets/mobile/teacher/tos/tos_competency_row.dart';
import 'package:likha/presentation/widgets/mobile/teacher/tos/tos_grid_table.dart';
import 'package:likha/presentation/widgets/mobile/teacher/tos/tos_print_preview.dart';
import 'package:likha/presentation/widgets/mobile/teacher/tos/tos_settings_card.dart';
import 'package:likha/presentation/widgets/mobile/teacher/tos/tos_summary_row.dart';
import 'package:likha/domain/tos/entities/tos_entity.dart';
import 'package:likha/presentation/providers/tos_provider.dart';

class TosDetailPage extends ConsumerStatefulWidget {
  final String tosId;
  final String classId;

  const TosDetailPage({
    super.key,
    required this.tosId,
    required this.classId,
  });

  @override
  ConsumerState<TosDetailPage> createState() => _TosDetailPageState();
}

class _TosDetailPageState extends ConsumerState<TosDetailPage> {
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
    _cellOverrideController.dispose();
    _editCompetencyController.dispose();
    _editDaysTaughtController.dispose();
    super.dispose();
  }

  void _handleDelete() {
    AppDialogs.showDestructive(
      context: context,
      title: 'Delete TOS',
      body: 'This will permanently delete this Table of Specifications and all its competencies.',
      confirmLabel: 'Delete',
      onConfirm: () async {
        await ref.read(tosProvider.notifier).deleteTos(widget.tosId);
        if (mounted) Navigator.pop(context);
      },
    );
  }

  final _competencyController = TextEditingController();
  final _timeUnitsTaughtController = TextEditingController();
  final _cellOverrideController = TextEditingController();
  final _editCompetencyController = TextEditingController();
  final _editDaysTaughtController = TextEditingController();

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

  void _handleEditCompetency(TosCompetency competency, String timeUnit) {
    _editCompetencyController.text = competency.competencyText;
    _editDaysTaughtController.text = '${competency.timeUnitsTaught}';
    final unitLabel = timeUnit == 'hours' ? 'Hours' : 'Days';
    showDialog(
      context: context,
      builder: (ctx) => StyledDialog(
        title: 'Edit Competency',
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

  void _handleCellTap(
    String competencyId,
    String levelKey,
    int? currentOverride,
  ) {
    _cellOverrideController.text = currentOverride?.toString() ?? '';
    AppDialogs.showInput(
      context: context,
      title: 'Set Item Count',
      controller: _cellOverrideController,
      labelText: 'Number of items (leave blank to auto)',
      confirmLabel: 'Save',
      keyboardType: TextInputType.number,
      onConfirm: () {
        final raw = _cellOverrideController.text.trim();
        final override = raw.isEmpty ? null : int.tryParse(raw);
        ref.read(tosProvider.notifier).updateCompetency(
          competencyId,
          {'${levelKey}_count': override},
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(tosProvider);
    final tos = state.currentTos;
    final competencies = state.competencies;

    ref.listen<TosState>(tosProvider, (prev, next) {
      if (next.successMessage != null && prev?.successMessage != next.successMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.successMessage!),
            duration: const Duration(seconds: 2),
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
      body: SafeArea(
        child: Column(
          children: [
            ClassSectionHeader(
              title: tos?.title ?? 'TOS Detail',
              showBackButton: true,
            ),
            Expanded(
              child: state.isLoading && tos == null
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.accentCharcoal,
                        strokeWidth: 2.5,
                      ),
                    )
                  : tos == null
                      ? const Center(child: Text('TOS not found'))
                      : RefreshIndicator(
                          onRefresh: () => ref
                              .read(tosProvider.notifier)
                              .loadTosDetail(widget.tosId),
                          color: AppColors.accentCharcoal,
                          child: SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Actions row
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    _ActionChip(
                                      icon: Icons.edit_outlined,
                                      label: 'Edit',
                                      onTap: () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => EditTosPage(tos: tos),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    _ActionChip(
                                      icon: Icons.print_outlined,
                                      label: 'Print',
                                      onTap: () => TosPrintService.printTos(
                                        context,
                                        tos,
                                        competencies,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    _ActionChip(
                                      icon: Icons.delete_outline_rounded,
                                      label: 'Delete',
                                      color: AppColors.semanticError,
                                      onTap: _handleDelete,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                // Settings card
                                TosSettingsCard(
                                  tos: tos,
                                  competencyCount: competencies.length,
                                  totalDays: competencies.fold<int>(
                                      0, (s, c) => s + c.timeUnitsTaught),
                                ),
                                const SizedBox(height: 20),
                                // Grid table
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
                                      border: Border.all(
                                          color: AppColors.borderLight),
                                    ),
                                    child: const Center(
                                      child: Text(
                                        'No competencies yet. Add competencies to see the grid.',
                                        style: TextStyle(
                                          color: AppColors.foregroundTertiary,
                                          fontSize: 13,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  )
                                else ...[
                                  TosGridTable(
                                    competencies: competencies,
                                    tos: tos,
                                    onCellTap: _handleCellTap,
                                  ),
                                  const SizedBox(height: 12),
                                  TosSummaryRow(
                                    competencies: competencies,
                                    totalItems: tos.totalItems,
                                    timeUnit: tos.timeUnit,
                                  ),
                                ],
                                const SizedBox(height: 24),
                                // Competencies list
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
                                ...competencies.map((c) {
                                  final totalDays = competencies.fold<int>(
                                      0, (s, comp) => s + comp.timeUnitsTaught);
                                  return TosCompetencyRow(
                                    competency: c,
                                    totalDays: totalDays,
                                    timeUnit: tos.timeUnit,
                                    onEdit: () => _handleEditCompetency(c, tos.timeUnit),
                                    onDelete: () {
                                      AppDialogs.showDestructive(
                                        context: context,
                                        title: 'Delete Competency',
                                        body: 'Remove this competency?',
                                        confirmLabel: 'Delete',
                                        onConfirm: () => ref
                                            .read(tosProvider.notifier)
                                            .deleteCompetency(c.id),
                                      );
                                    },
                                  );
                                }),
                                const SizedBox(height: 16),
                                // Add buttons
                                _OutlinedButton(
                                  icon: Icons.add,
                                  label: 'Add Competency',
                                  onTap: () => _handleAddCompetency(tos.timeUnit),
                                ),
                                const SizedBox(height: 8),
                                _OutlinedButton(
                                  icon: Icons.search,
                                  label: 'Import from MELCs',
                                  onTap: () =>
                                      MelcsSearchSheet.show(context, widget.tosId),
                                ),
                                const SizedBox(height: 8),
                                _OutlinedButton(
                                  icon: Icons.paste,
                                  label: 'Bulk Paste',
                                  onTap: () =>
                                      BulkPasteSheet.show(context, widget.tosId),
                                ),
                                const SizedBox(height: 32),
                              ],
                            ),
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  final VoidCallback onTap;

  const _ActionChip({
    required this.icon,
    required this.label,
    this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.accentCharcoal;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: c.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: c.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: c),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: c,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OutlinedButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _OutlinedButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 44,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.accentCharcoal,
          side: const BorderSide(color: AppColors.borderLight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }
}
