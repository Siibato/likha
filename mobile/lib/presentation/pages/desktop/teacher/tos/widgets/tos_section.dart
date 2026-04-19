import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/presentation/pages/desktop/core/desktop_page_scaffold.dart';
import 'package:likha/presentation/pages/desktop/teacher/tos/create_tos_desktop.dart';
import 'package:likha/presentation/pages/desktop/teacher/tos/tos_detail_desktop.dart';
import 'package:likha/presentation/pages/desktop/teacher/widgets/base_data_table.dart';
import 'package:likha/presentation/pages/desktop/teacher/widgets/empty_state.dart';
import 'package:likha/presentation/providers/tos_provider.dart';

/// TOS (Table of Specifications) section widget for TeacherClassDetailDesktop
/// Displays a list of TOS with create and navigation functionality
class TosSection extends ConsumerWidget {
  final String classId;

  const TosSection({
    super.key,
    required this.classId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(tosProvider);

    return DesktopPageScaffold(
      title: 'Table of Specifications',
      actions: [
        FilledButton.icon(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CreateTosDesktop(classId: classId),
            ),
          ).then((result) {
            if (result == true) {
              ref.read(tosProvider.notifier).loadTosList(classId);
            }
          }),
          icon: const Icon(Icons.add_rounded, size: 18),
          label: const Text('Create TOS'),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.foregroundDark,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
        ),
      ],
      body: state.isLoading && state.tosList.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(
                  color: AppColors.foregroundPrimary,
                  strokeWidth: 2.5,
                ),
              ),
            )
          : state.tosList.isEmpty
              ? const EmptyState.tos()
              : BaseDataTable(
                  items: state.tosList,
                  columnFlexes: const [3, 1, 1, 1],
                  columns: const [
                    DataColumn(
                        label: Text('Title', style: dataTableHeaderStyle)),
                    DataColumn(
                        label: Text('Quarter', style: dataTableHeaderStyle)),
                    DataColumn(
                        label: Text('Mode', style: dataTableHeaderStyle)),
                    DataColumn(
                        label: Text('Items', style: dataTableHeaderStyle),
                        numeric: true),
                  ],
                  rowBuilder: (context, tos, index) {
                    return IntrinsicHeight(
                      child: Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Text(
                              tos.title,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.foregroundDark,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: Text(
                              'Q${tos.gradingPeriodNumber}',
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppColors.foregroundSecondary,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: Text(
                              tos.classificationMode == 'blooms'
                                  ? "Bloom's"
                                  : 'Difficulty',
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.foregroundTertiary,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: Text(
                              '${tos.totalItems}',
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppColors.foregroundSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  onTap: (tos) => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TosDetailDesktop(
                        tosId: tos.id,
                        classId: classId,
                      ),
                    ),
                  ).then((_) => ref
                      .read(tosProvider.notifier)
                      .loadTosList(classId)),
                ),
    );
  }
}
