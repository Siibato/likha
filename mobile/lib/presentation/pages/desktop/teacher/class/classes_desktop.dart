import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/presentation/pages/desktop/core/desktop_page_scaffold.dart';
import 'package:likha/presentation/pages/desktop/teacher/class/class_detail_desktop.dart';
import 'package:likha/presentation/pages/desktop/teacher/class/widgets/teacher_class_data_table.dart';
import 'package:likha/presentation/providers/class_provider.dart';

class TeacherClassesDesktop extends ConsumerStatefulWidget {
  const TeacherClassesDesktop({super.key});

  @override
  ConsumerState<TeacherClassesDesktop> createState() =>
      _TeacherClassesDesktopState();
}

class _TeacherClassesDesktopState extends ConsumerState<TeacherClassesDesktop> {
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(classProvider.notifier).loadClasses();
    });
  }

  @override
  Widget build(BuildContext context) {
    final classState = ref.watch(classProvider);

    final filteredClasses = classState.classes.where((c) {
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
          if (classState.isLoading && classState.classes.isEmpty)
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
                      TeacherClassDetailDesktop(classId: cls.id),
                ),
              ).then(
                  (_) => ref.read(classProvider.notifier).loadClasses()),
            ),
        ],
      ),
    );
  }
}
