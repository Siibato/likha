import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/presentation/layouts/desktop/desktop_page_scaffold.dart';
import 'package:likha/presentation/pages/desktop/teacher/class/class_detail_page.dart';
import 'package:likha/presentation/widgets/desktop/teacher/class/teacher_class_data_table.dart';
import 'package:likha/presentation/providers/class_provider.dart';

class TeacherClassesPage extends ConsumerStatefulWidget {
  const TeacherClassesPage({super.key});

  @override
  ConsumerState<TeacherClassesPage> createState() =>
      _TeacherClassesPageState();
}

class _TeacherClassesPageState extends ConsumerState<TeacherClassesPage> {
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    // Data is loaded by TeacherDashboardPage (tab 0) via the shared classListProvider.
    // No need to trigger another background fetch here.
  }

  @override
  Widget build(BuildContext context) {
    final classListState = ref.watch(classListProvider);

    final filteredClasses = classListState.classes.where((c) {
      if (_searchQuery.isEmpty) return true;
      return c.title.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return DesktopPageScaffold(
      title: 'My Classes',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: TextField(
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: const InputDecoration(
                hintText: 'Search classes...',
                hintStyle: TextStyle(
                  color: AppColors.foregroundTertiary,
                  fontSize: 14,
                ),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: AppColors.foregroundTertiary,
                  size: 20,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 14),
              ),
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.foregroundPrimary,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Table
          if (classListState.isLoading && classListState.classes.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(48),
                child: CircularProgressIndicator(
                  color: AppColors.foregroundPrimary,
                  strokeWidth: 2.5,
                ),
              ),
            )
          else
            TeacherClassDataTable(
              classes: filteredClasses,
              onTap: (cls) => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      TeacherClassDetailPage(classId: cls.id),
                ),
              ).then(
                  (_) => ref.read(classListProvider.notifier).loadClasses()),
            ),
        ],
      ),
    );
  }
}
