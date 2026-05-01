import 'package:flutter/material.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/presentation/pages/shared/class_section_header.dart';
import 'package:likha/presentation/widgets/shared/cards/navigation_card.dart';
import 'package:likha/presentation/pages/teacher/grade/grades_record_page.dart';
import 'package:likha/presentation/providers/class_provider.dart';

class TeacherGradesPage extends ConsumerStatefulWidget {
  const TeacherGradesPage({super.key});

  @override
  ConsumerState<TeacherGradesPage> createState() => _TeacherGradesPageState();
}

class _TeacherGradesPageState extends ConsumerState<TeacherGradesPage> {
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

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ClassSectionHeader(title: 'Grades'),
          Expanded(
            child: classState.isLoading && classState.classes.isEmpty
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.accentCharcoal,
                      strokeWidth: 2.5,
                    ),
                  )
                : classState.classes.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.school_outlined,
                              size: 64,
                              color: AppColors.foregroundLight,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'No classes yet',
                              style: TextStyle(
                                fontSize: 16,
                                color: AppColors.foregroundTertiary,
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () =>
                            ref.read(classProvider.notifier).loadClasses(),
                        color: AppColors.accentCharcoal,
                        child: ListView(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 16),
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(bottom: 16),
                              child: Text(
                                'Select a class to manage grades',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.foregroundTertiary,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ),
                            ...classState.classes.map(
                              (cls) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: NavigationCard(
                                  icon: Icons.grading_outlined,
                                  title: cls.title,
                                  subtitle: '${cls.studentCount} students',
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          ClassRecordPage(classId: cls.id),
                                    ),
                                  ).then((_) => ref
                                      .read(classProvider.notifier)
                                      .loadClasses()),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
