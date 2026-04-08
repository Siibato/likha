import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/domain/classes/entities/class_entity.dart';
import 'package:likha/presentation/pages/admin/admin_class_detail_page.dart';
import 'package:likha/presentation/pages/admin/admin_create_class_page.dart';
import 'package:likha/presentation/pages/admin/widgets/search_bar.dart';
import 'package:likha/presentation/pages/shared/widgets/cards/class_card.dart';
import 'package:likha/presentation/providers/class_provider.dart';

class AdminClassesPage extends ConsumerStatefulWidget {
  const AdminClassesPage({super.key});

  @override
  ConsumerState<AdminClassesPage> createState() => _AdminClassesPageState();
}

class _AdminClassesPageState extends ConsumerState<AdminClassesPage> {
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(classProvider.notifier).loadAllClasses();
    });
  }

  List<ClassEntity> _getFilteredAndSortedClasses(List<ClassEntity> classes) {
    final query = _searchQuery.trim().toLowerCase();
    final filtered = query.isEmpty
        ? classes
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
    final classState = ref.watch(classProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Class Management',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Color(0xFF2B2B2B),
            letterSpacing: -0.4,
          ),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF2B2B2B)),
      ),
      body: classState.isLoading && classState.classes.isEmpty
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF2B2B2B),
                strokeWidth: 2.5,
              ),
            )
          : classState.classes.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.class_outlined, size: 64, color: Color(0xFFCCCCCC)),
                      SizedBox(height: 16),
                      Text(
                        'No classes yet',
                        style: TextStyle(fontSize: 16, color: Color(0xFF999999)),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    AdminSearchBar(
                      hintText: 'Search classes...',
                      onChanged: (q) => setState(() => _searchQuery = q),
                    ),
                    Expanded(
                      child: Builder(
                        builder: (context) {
                          final filteredClasses = _getFilteredAndSortedClasses(classState.classes);
                          if (filteredClasses.isEmpty) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.search_off_rounded, size: 64, color: Color(0xFFCCCCCC)),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No classes match "$_searchQuery"',
                                    style: const TextStyle(fontSize: 16, color: Color(0xFF999999)),
                                  ),
                                ],
                              ),
                            );
                          }
                          return RefreshIndicator(
                            onRefresh: () => ref.read(classProvider.notifier).loadAllClasses(),
                            color: const Color(0xFF2B2B2B),
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
                                  ).then((_) => ref.read(classProvider.notifier).loadAllClasses()),
                                );
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AdminCreateClassPage()),
        ),
        backgroundColor: const Color(0xFF2B2B2B),
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
    );
  }
}
