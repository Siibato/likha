import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/domain/classes/entities/class_entity.dart';
import 'package:likha/presentation/pages/admin/account/widgets/search_bar.dart';
import 'package:likha/presentation/pages/teacher/class_detail_page.dart';
import 'package:likha/presentation/pages/teacher/widgets/empty_class_state.dart';
import 'package:likha/presentation/pages/teacher/widgets/empty_search_result_state.dart';
import 'package:likha/presentation/pages/shared/widgets/cards/class_card.dart';
import 'package:likha/presentation/pages/shared/class_section_header.dart';
import 'package:likha/presentation/providers/class_provider.dart';

class TeacherClassesPage extends ConsumerStatefulWidget {
  const TeacherClassesPage({super.key});

  @override
  ConsumerState<TeacherClassesPage> createState() => _TeacherClassesPageState();
}

class _TeacherClassesPageState extends ConsumerState<TeacherClassesPage> {
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(classProvider.notifier).loadClasses();
    });
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
    final classState = ref.watch(classProvider);

    return SafeArea(
      child: classState.isLoading && classState.classes.isEmpty
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF2B2B2B),
                strokeWidth: 2.5,
              ),
            )
          : RefreshIndicator(
              onRefresh: () => ref.read(classProvider.notifier).loadClasses(),
              color: const Color(0xFF2B2B2B),
              child: CustomScrollView(
                slivers: [
                  const SliverToBoxAdapter(
                    child: ClassSectionHeader(title: 'My Classes'),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: AdminSearchBar(
                        hintText: 'Search classes...',
                        onChanged: (q) => setState(() => _searchQuery = q),
                      ),
                    ),
                  ),
                  classState.classes.isEmpty
                      ? const SliverFillRemaining(
                          child: EmptyClassState(),
                        )
                      : Builder(
                          builder: (context) {
                            final filteredClasses = _getFilteredAndSortedClasses(classState.classes);
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
                                        ref.read(classProvider.notifier).loadClasses()),
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
