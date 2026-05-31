import 'package:flutter/material.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/presentation/pages/shared/class_section_header.dart';
import 'package:likha/presentation/widgets/mobile/teacher/tos/tos_competency_row.dart';
import 'package:likha/presentation/widgets/mobile/teacher/tos/tos_grid_table.dart';
import 'package:likha/presentation/widgets/mobile/teacher/tos/tos_settings_card.dart';
import 'package:likha/presentation/widgets/mobile/teacher/tos/tos_summary_row.dart';
import 'package:likha/presentation/providers/tos_provider.dart';

/// Read-only TOS reference page, navigated from assessment detail.
class TosViewPage extends ConsumerStatefulWidget {
  final String tosId;

  const TosViewPage({super.key, required this.tosId});

  @override
  ConsumerState<TosViewPage> createState() => _TosViewPageState();
}

class _TosViewPageState extends ConsumerState<TosViewPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(tosProvider.notifier).loadTosDetail(widget.tosId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(tosProvider);
    final tos = state.currentTos;
    final competencies = state.competencies;

    return Scaffold(
      backgroundColor: AppColors.backgroundSecondary,
      body: SafeArea(
        child: Column(
          children: [
            const ClassSectionHeader(
              title: 'TOS Reference',
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
                                // Read-only badge
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.borderLight,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    'View Only',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.foregroundTertiary,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                TosSettingsCard(
                                  tos: tos,
                                  competencyCount: competencies.length,
                                  totalDays: competencies.fold<int>(
                                      0, (s, c) => s + c.timeUnitsTaught),
                                ),
                                const SizedBox(height: 20),
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
                                        'No competencies in this TOS.',
                                        style: TextStyle(
                                          color: AppColors.foregroundTertiary,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  )
                                else ...[
                                  // Read-only grid — no onCellTap
                                  TosGridTable(
                                    competencies: competencies,
                                    tos: tos,
                                  ),
                                  const SizedBox(height: 12),
                                  TosSummaryRow(
                                    competencies: competencies,
                                    totalItems: tos.totalItems,
                                    timeUnit: tos.timeUnit,
                                  ),
                                ],
                                const SizedBox(height: 24),
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
                                    // no onEdit / onDelete — read-only
                                  );
                                }),
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
