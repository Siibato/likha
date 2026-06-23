import 'package:flutter/material.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/domain/classes/entities/class_entity.dart';
import 'package:likha/presentation/widgets/shared/search/app_search_bar.dart';
import 'package:likha/presentation/pages/mobile/teacher/class/class_detail_page.dart';
import 'package:likha/presentation/widgets/mobile/teacher/dashboard/empty_class_state.dart';
import 'package:likha/presentation/widgets/mobile/teacher/class/empty_search_result_state.dart';
import 'package:likha/presentation/widgets/shared/cards/class_card.dart';
import 'package:likha/presentation/widgets/shared/primitives/class_section_header.dart';
import 'package:likha/presentation/providers/class_provider.dart';

class TeacherClassListPage extends ConsumerStatefulWidget {
  const TeacherClassListPage({super.key});

  @override
  ConsumerState<TeacherClassListPage> createState() => _TeacherClassListPageState();
}

class _TeacherClassListPageState extends ConsumerState<TeacherClassListPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(classListProvider.notifier).loadClasses();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<ClassEntity> _getFilteredAndSortedClasses(List<ClassEntity> classes) {
    final query = _searchQuery.trim().toLowerCase();
    final filtered = query.isEmpty
        ? classes
        : classes.where((c) => c.title.toLowerCase().contains(query)).toList();

    filtered.sort((a, b) {
      final titleCmp = a.title.toLowerCase().compareTo(b.title.toLowerCase());
      if (titleCmp != 0) return titleCmp;
      return a.createdAt.compareTo(b.createdAt);
    });

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final classListState = ref.watch(classListProvider);

    return SafeArea(
      child: classListState.isLoading && classListState.classes.isEmpty
          ? const Center(
              child: CircularProgressIndicator(
                color: AppColors.accentCharcoal,
                strokeWidth: 2.5,
              ),
            )
          : RefreshIndicator(
              onRefresh: () => ref.read(classListProvider.notifier).loadClasses(),
              color: AppColors.accentCharcoal,
              child: CustomScrollView(
                slivers: [
                  const SliverToBoxAdapter(
                    child: ClassSectionHeader(title: 'My Classes'),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: AppSearchBar(
                        controller: _searchController,
                        hint: 'Search classes...',
                        onChanged: (q) => setState(() => _searchQuery = q),
                        onClear: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      ),
                    ),
                  ),
                  classListState.classes.isEmpty
                      ? const SliverFillRemaining(
                          child: EmptyClassState(),
                        )
                      : Builder(
                          builder: (context) {
                            final filteredClasses = _getFilteredAndSortedClasses(classListState.classes);
                            if (filteredClasses.isEmpty) {
                              return SliverFillRemaining(
                                child: EmptySearchResultState(searchQuery: _searchQuery),
                              );
                            }
                            return SliverPadding(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                              sliver: SliverList.builder(
                                itemCount: filteredClasses.length,
                                itemBuilder: (context, index) {
                                  final cls = filteredClasses[index];
                                  return ClassCard(
                                    title: cls.title,
                                    subtitle: cls.isAdvisory
                                        ? '${cls.studentCount} student${cls.studentCount != 1 ? 's' : ''} | Advisory'
                                        : '${cls.studentCount} student${cls.studentCount != 1 ? 's' : ''}',
                                    onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => ClassDetailPage(classId: cls.id),
                                      ),
                                    ).then((_) =>
                                        ref.read(classListProvider.notifier).loadClasses()),
                                  );
                                },
                              ),
                            );
                          },
                        ),
                  const SliverToBoxAdapter(
                    child: SizedBox(height: 40),
                  ),
                ],
              ),
            ),
    );
  }
}
