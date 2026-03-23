import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/presentation/pages/desktop/core/desktop_page_scaffold.dart';
import 'package:likha/presentation/pages/shared/widgets/cards/navigation_card.dart';
import 'package:likha/presentation/pages/teacher/class_record_page.dart';
import 'package:likha/presentation/providers/class_provider.dart';

class TeacherGradesDesktop extends ConsumerStatefulWidget {
  const TeacherGradesDesktop({super.key});

  @override
  ConsumerState<TeacherGradesDesktop> createState() =>
      _TeacherGradesDesktopState();
}

class _TeacherGradesDesktopState extends ConsumerState<TeacherGradesDesktop> {
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

    return DesktopPageScaffold(
      title: 'Grades',
      subtitle: 'Select a class to manage grades',
      body: classState.isLoading && classState.classes.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(48),
                child: CircularProgressIndicator(
                  color: AppColors.foregroundPrimary,
                  strokeWidth: 2.5,
                ),
              ),
            )
          : classState.classes.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.school_outlined,
                          size: 48, color: AppColors.borderLight),
                      SizedBox(height: 12),
                      Text(
                        'No classes yet',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: AppColors.foregroundTertiary,
                        ),
                      ),
                    ],
                  ),
                )
              : Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: classState.classes.map((cls) {
                    return SizedBox(
                      width: 380,
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
                        ).then((_) =>
                            ref.read(classProvider.notifier).loadClasses()),
                      ),
                    );
                  }).toList(),
                ),
    );
  }
}
