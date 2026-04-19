import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/presentation/pages/desktop/core/desktop_page_scaffold.dart';
import 'package:likha/presentation/pages/desktop/teacher/tos/create_tos_desktop.dart';
import 'package:likha/presentation/pages/desktop/teacher/tos/tos_detail_desktop.dart';
import 'package:likha/presentation/providers/tos_provider.dart';
import 'package:likha/presentation/utils/formatters.dart';

class TosListDesktop extends ConsumerStatefulWidget {
  final String classId;

  const TosListDesktop({super.key, required this.classId});

  @override
  ConsumerState<TosListDesktop> createState() => _TosListDesktopState();
}

class _TosListDesktopState extends ConsumerState<TosListDesktop> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(tosProvider.notifier).loadTosList(widget.classId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(tosProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundSecondary,
      body: DesktopPageScaffold(
        title: 'Table of Specifications',
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
          tooltip: 'Back',
        ),
        actions: [
          FilledButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CreateTosDesktop(classId: widget.classId),
              ),
            ),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Create TOS'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.foregroundPrimary,
            ),
          ),
        ],
        body: state.isLoading && state.tosList.isEmpty
            ? const Center(
                child: CircularProgressIndicator(
                  color: AppColors.foregroundPrimary,
                  strokeWidth: 2.5,
                ),
              )
            : state.tosList.isEmpty
                ? _buildEmptyState()
                : Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.borderLight),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: DataTable(
                        headingRowColor: WidgetStateProperty.all(
                          AppColors.backgroundTertiary,
                        ),
                        columns: const [
                          DataColumn(label: Text('Title')),
                          DataColumn(label: Text('Quarter')),
                          DataColumn(label: Text('Mode')),
                          DataColumn(label: Text('Total Items'), numeric: true),
                          DataColumn(label: Text('Created')),
                        ],
                        rows: state.tosList.map((tos) {
                          final modeLabel = tos.classificationMode == 'blooms'
                              ? "Bloom's Taxonomy"
                              : 'Difficulty';
                          final createdLabel = Formatters.formatDateTimeFull(tos.createdAt);

                          return DataRow(
                            onSelectChanged: (_) => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => TosDetailDesktop(
                                  tosId: tos.id,
                                  classId: widget.classId,
                                ),
                              ),
                            ),
                            cells: [
                              DataCell(Text(
                                tos.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.foregroundPrimary,
                                ),
                              )),
                              DataCell(Text('Q${tos.gradingPeriodNumber}')),
                              DataCell(Text(modeLabel)),
                              DataCell(Text('${tos.totalItems}')),
                              DataCell(Text(
                                createdLabel,
                                style: const TextStyle(
                                  color: AppColors.foregroundSecondary,
                                  fontSize: 13,
                                ),
                              )),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.table_chart_outlined,
            size: 64,
            color: AppColors.foregroundSecondary.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 16),
          const Text(
            'No TOS created yet',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.foregroundPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Create your first Table of Specifications',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.foregroundSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
