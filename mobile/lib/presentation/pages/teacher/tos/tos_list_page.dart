import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/presentation/layouts/mobile/mobile_page_scaffold.dart';
import 'package:likha/presentation/pages/shared/class_section_header.dart';
import 'package:likha/presentation/widgets/shared/cards/base_card.dart';
import 'package:likha/presentation/widgets/shared/primitives/chevron_trailing.dart';
import 'package:likha/presentation/pages/teacher/tos/create_tos_page.dart';
import 'package:likha/presentation/pages/teacher/tos/tos_detail_page.dart';
import 'package:likha/presentation/providers/tos_provider.dart';

class TosListPage extends ConsumerStatefulWidget {
  final String classId;

  const TosListPage({super.key, required this.classId});

  @override
  ConsumerState<TosListPage> createState() => _TosListPageState();
}

class _TosListPageState extends ConsumerState<TosListPage> {
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

    return MobilePageScaffold(
      title: 'Table of Specifications',
      scrollable: false,
      isLoading: state.isLoading && state.tosList.isEmpty,
      header: const ClassSectionHeader(
        title: 'Table of Specifications',
        showBackButton: true,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CreateTosPage(classId: widget.classId),
          ),
        ),
        backgroundColor: AppColors.accentCharcoal,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: state.tosList.isEmpty
          ? _buildEmptyState()
          : RefreshIndicator(
                          onRefresh: () => ref
                              .read(tosProvider.notifier)
                              .loadTosList(widget.classId),
                          color: AppColors.accentCharcoal,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(24),
                            itemCount: state.tosList.length,
                            itemBuilder: (context, index) {
                              final tos = state.tosList[index];
                              final modeLabel = tos.classificationMode == 'blooms'
                                  ? "Bloom's"
                                  : 'Difficulty';
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: BaseCard(
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          TosDetailPage(tosId: tos.id, classId: widget.classId),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 44,
                                        height: 44,
                                        decoration: BoxDecoration(
                                          color: AppColors.borderLight,
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Center(
                                          child: Text(
                                            'Q${tos.gradingPeriodNumber}',
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.accentCharcoal,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              tos.title,
                                              style: const TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w600,
                                                color: AppColors.accentCharcoal,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              '$modeLabel | ${tos.totalItems} items',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: AppColors.foregroundTertiary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const ChevronTrailing(),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.table_chart_outlined,
            size: 64,
            color: AppColors.foregroundLight,
          ),
          const SizedBox(height: 16),
          const Text(
            'No TOS created yet',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.accentCharcoal,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Create your first Table of Specifications',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.foregroundTertiary,
            ),
          ),
        ],
      ),
    );
  }
}
