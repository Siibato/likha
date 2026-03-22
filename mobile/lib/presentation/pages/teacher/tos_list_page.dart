import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/presentation/pages/shared/class_section_header.dart';
import 'package:likha/presentation/pages/shared/widgets/cards/base_card.dart';
import 'package:likha/presentation/pages/shared/widgets/primitives/chevron_trailing.dart';
import 'package:likha/presentation/pages/teacher/create_tos_page.dart';
import 'package:likha/presentation/pages/teacher/tos_detail_page.dart';
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

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: SafeArea(
        child: Column(
          children: [
            const ClassSectionHeader(
              title: 'Table of Specifications',
              showBackButton: true,
            ),
            Expanded(
              child: state.isLoading && state.tosList.isEmpty
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF2B2B2B),
                        strokeWidth: 2.5,
                      ),
                    )
                  : state.tosList.isEmpty
                      ? _buildEmptyState()
                      : RefreshIndicator(
                          onRefresh: () => ref
                              .read(tosProvider.notifier)
                              .loadTosList(widget.classId),
                          color: const Color(0xFF2B2B2B),
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
                                          color: const Color(0xFFF0F0F0),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Center(
                                          child: Text(
                                            'Q${tos.quarter}',
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w700,
                                              color: Color(0xFF2B2B2B),
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
                                                color: Color(0xFF2B2B2B),
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              '$modeLabel | ${tos.totalItems} items',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: Color(0xFF999999),
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
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CreateTosPage(classId: widget.classId),
          ),
        ),
        backgroundColor: const Color(0xFF2B2B2B),
        child: const Icon(Icons.add, color: Colors.white),
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
            color: Color(0xFFCCCCCC),
          ),
          const SizedBox(height: 16),
          const Text(
            'No TOS created yet',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2B2B2B),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Create your first Table of Specifications',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF999999),
            ),
          ),
        ],
      ),
    );
  }
}
