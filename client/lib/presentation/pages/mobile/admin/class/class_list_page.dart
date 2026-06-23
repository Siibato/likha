import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/domain/classes/entities/class_entity.dart';
import 'package:likha/presentation/pages/mobile/admin/class/class_detail_page.dart';
import 'package:likha/presentation/pages/mobile/admin/class/class_create_page.dart';
import 'package:likha/presentation/widgets/mobile/admin/class/empty_classes_state.dart';
import 'package:likha/presentation/widgets/mobile/admin/class/empty_search_classes_state.dart';
import 'package:likha/presentation/widgets/shared/search/app_search_bar.dart';
import 'package:likha/presentation/widgets/shared/cards/class_card.dart';
import 'package:likha/presentation/widgets/shared/feedback/content_state_builder.dart';
import 'package:likha/presentation/providers/class_provider.dart';

class AdminClassListPage extends ConsumerStatefulWidget {
  const AdminClassListPage({super.key});

  @override
  ConsumerState<AdminClassListPage> createState() => _AdminClassListPageState();
}

class _AdminClassListPageState extends ConsumerState<AdminClassListPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(classListProvider.notifier).loadAllClasses();
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
        ? classes.toList()
        : classes
            .where((c) =>
                c.title.toLowerCase().contains(query) ||
                c.teacherFullName.toLowerCase().contains(query) ||
                c.teacherUsername.toLowerCase().contains(query))
            .toList();

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

    final filteredClasses = _getFilteredAndSortedClasses(classListState.classes);

    return Scaffold(
      backgroundColor: AppColors.backgroundSecondary,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Class Management',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.accentCharcoal,
            letterSpacing: -0.4,
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.accentCharcoal),
      ),
      body: Column(
        children: [
          AppSearchBar(
            controller: _searchController,
            hint: 'Search classes...',
            onChanged: (q) => setState(() => _searchQuery = q),
            onClear: () {
              _searchController.clear();
              setState(() => _searchQuery = '');
            },
          ),
          Expanded(
            child: ContentStateBuilder(
              isLoading: classListState.isLoading && classListState.classes.isEmpty,
              isEmpty: filteredClasses.isEmpty,
              onRefresh: () => ref.read(classListProvider.notifier).loadAllClasses(),
              onRetry: () => ref.read(classListProvider.notifier).loadAllClasses(),
              emptyState: _searchQuery.isEmpty
                  ? const EmptyClassesState()
                  : EmptySearchClassesState(searchQuery: _searchQuery),
              child: ListView.builder(
                padding: const EdgeInsets.all(24),
                itemCount: filteredClasses.length,
                itemBuilder: (context, index) {
                  final cls = filteredClasses[index];
                  final teacherLabel = cls.teacherFullName.isEmpty
                      ? cls.teacherUsername
                      : cls.teacherFullName;
                  return ClassCard(
                    title: cls.title,
                    subtitle: cls.isArchived ? '$teacherLabel · Archived' : teacherLabel,
                    isAdvisory: cls.isAdvisory,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AdminClassDetailPage(classId: cls.id),
                      ),
                    ).then((_) => ref.read(classListProvider.notifier).loadAllClasses()),
                  );
                },
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AdminCreateClassPage()),
        ),
        backgroundColor: AppColors.accentCharcoal,
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
    );
  }
}
