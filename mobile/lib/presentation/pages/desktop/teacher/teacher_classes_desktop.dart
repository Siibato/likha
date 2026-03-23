import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/presentation/pages/desktop/core/desktop_page_scaffold.dart';
import 'package:likha/presentation/pages/desktop/teacher/teacher_class_detail_desktop.dart';
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
    }).toList()
      ..sort(
          (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));

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
          else if (filteredClasses.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(48),
                child: Column(
                  children: [
                    const Icon(Icons.school_outlined,
                        size: 48, color: AppColors.borderLight),
                    const SizedBox(height: 12),
                    Text(
                      _searchQuery.isEmpty
                          ? 'No classes assigned'
                          : 'No classes match "$_searchQuery"',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: AppColors.foregroundTertiary,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: DataTable(
                  headingRowColor:
                      WidgetStateProperty.all(AppColors.backgroundTertiary),
                  dataRowMaxHeight: 56,
                  horizontalMargin: 20,
                  columnSpacing: 24,
                  showCheckboxColumn: false,
                  columns: const [
                    DataColumn(
                        label: Text('Class Title', style: _headerStyle)),
                    DataColumn(
                      label: Text('Students', style: _headerStyle),
                      numeric: true,
                    ),
                    DataColumn(
                        label: Text('Advisory', style: _headerStyle)),
                    DataColumn(
                        label: Text('Created', style: _headerStyle)),
                  ],
                  rows: filteredClasses.map((cls) {
                    return DataRow(
                      onSelectChanged: (_) => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              TeacherClassDetailDesktop(classId: cls.id),
                        ),
                      ).then((_) =>
                          ref.read(classProvider.notifier).loadClasses()),
                      cells: [
                        DataCell(Text(
                          cls.title,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.foregroundDark,
                          ),
                        )),
                        DataCell(Text(
                          '${cls.studentCount}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.foregroundSecondary,
                          ),
                        )),
                        DataCell(
                          cls.isAdvisory
                              ? const Icon(Icons.star_rounded,
                                  size: 18, color: Color(0xFF4CAF50))
                              : const SizedBox.shrink(),
                        ),
                        DataCell(Text(
                          _formatDate(cls.createdAt),
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.foregroundTertiary,
                          ),
                        )),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  static const _headerStyle = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w700,
    color: AppColors.foregroundSecondary,
  );
}
