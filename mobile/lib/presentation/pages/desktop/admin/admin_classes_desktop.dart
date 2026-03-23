import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/presentation/pages/desktop/admin/admin_class_detail_desktop.dart';
import 'package:likha/presentation/pages/desktop/admin/admin_create_class_desktop.dart';
import 'package:likha/presentation/pages/desktop/admin/widgets/class_data_table.dart';
import 'package:likha/presentation/pages/desktop/core/desktop_page_scaffold.dart';
import 'package:likha/presentation/providers/class_provider.dart';

class AdminClassesDesktop extends ConsumerStatefulWidget {
  const AdminClassesDesktop({super.key});

  @override
  ConsumerState<AdminClassesDesktop> createState() =>
      _AdminClassesDesktopState();
}

class _AdminClassesDesktopState extends ConsumerState<AdminClassesDesktop> {
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(classProvider.notifier).loadAllClasses();
    });
  }

  @override
  Widget build(BuildContext context) {
    final classState = ref.watch(classProvider);

    final filteredClasses = classState.classes.where((c) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return c.title.toLowerCase().contains(q) ||
          c.teacherFullName.toLowerCase().contains(q) ||
          c.teacherUsername.toLowerCase().contains(q);
    }).toList()
      ..sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));

    return DesktopPageScaffold(
      title: 'Class Management',
      actions: [
        FilledButton.icon(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const AdminCreateClassDesktop(),
            ),
          ).then((_) => ref.read(classProvider.notifier).loadAllClasses()),
          icon: const Icon(Icons.add_rounded, size: 18),
          label: const Text('Create Class'),
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
            ClassDataTable(
              classes: filteredClasses,
              onTap: (cls) => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      AdminClassDetailDesktop(classId: cls.id),
                ),
              ).then(
                  (_) => ref.read(classProvider.notifier).loadAllClasses()),
            ),
        ],
      ),
    );
  }
}
