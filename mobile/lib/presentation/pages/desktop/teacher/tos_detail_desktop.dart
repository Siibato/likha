import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/domain/tos/entities/tos_entity.dart';
import 'package:likha/presentation/pages/desktop/core/desktop_page_scaffold.dart';
import 'package:likha/presentation/pages/desktop/teacher/edit_tos_desktop.dart';
import 'package:likha/presentation/pages/shared/widgets/cards/info_panel.dart';
import 'package:likha/presentation/pages/shared/widgets/dialogs/app_dialogs.dart';
import 'package:likha/presentation/pages/teacher/widgets/bulk_paste_sheet.dart';
import 'package:likha/presentation/pages/teacher/widgets/melcs_search_sheet.dart';
import 'package:likha/presentation/pages/teacher/widgets/tos_grid_table.dart';
import 'package:likha/presentation/pages/teacher/widgets/tos_print_preview.dart';
import 'package:likha/presentation/pages/teacher/widgets/tos_summary_row.dart';
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

  void _handleAddCompetency() {
    _competencyController.clear();
    AppDialogs.showInput(
      context: context,
      title: 'Add Competency',
      controller: _competencyController,
      labelText: 'Competency description',
      confirmLabel: 'Add',
      onConfirm: () {
        final text = _competencyController.text;
        if (text.trim().isNotEmpty) {
          ref.read(tosProvider.notifier).addCompetency(
            widget.tosId,
            {
              'competency_text': text.trim(),
              'days_taught': 1,
              'order_index': ref.read(tosProvider).competencies.length,
            },
          );
        }
      },
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
                                  (c) => _buildCompetencyTile(c)),

                            const SizedBox(height: 16),

                            // Action buttons
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                OutlinedButton.icon(
                                  onPressed: _handleAddCompetency,
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
                                  onPressed: () => MelcsSearchSheet.show(
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
                                classificationMode: tos.classificationMode,
                                totalItems: tos.totalItems,
                              ),
                              const SizedBox(height: 12),
                              TosSummaryRow(
                                competencies: competencies,
                                totalItems: tos.totalItems,
                              ),
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
        competencies.fold<int>(0, (sum, c) => sum + c.daysTaught);

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
          _settingsRow('Quarter', 'Q${tos.quarter}'),
          _settingsRow('Mode', modeLabel),
          _settingsRow('Total Items', '${tos.totalItems}'),
          _settingsRow('Competencies', '${competencies.length}'),
          _settingsRow('Total Days', '$totalDays'),
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

  Widget _buildCompetencyTile(TosCompetency competency) {
    return Container(
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
                  '${competency.daysTaught} day${competency.daysTaught == 1 ? '' : 's'} taught',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.foregroundSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
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
            icon: const Icon(Icons.close_rounded, size: 18),
            color: AppColors.foregroundSecondary,
            tooltip: 'Delete',
          ),
        ],
      ),
    );
  }
}
