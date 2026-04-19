import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/presentation/pages/desktop/core/desktop_page_scaffold.dart';
import 'package:likha/presentation/pages/desktop/teacher/class/class_detail_desktop.dart';
import 'package:likha/presentation/pages/desktop/teacher/widgets/teacher_stats_row.dart';
import 'package:likha/presentation/pages/shared/widgets/cards/navigation_card.dart';
import 'package:likha/presentation/providers/class_provider.dart';

class TeacherDashboardDesktop extends ConsumerStatefulWidget {
  final ValueChanged<int>? onNavigate;

  const TeacherDashboardDesktop({super.key, this.onNavigate});

  @override
  ConsumerState<TeacherDashboardDesktop> createState() =>
      _TeacherDashboardDesktopState();
}

class _TeacherDashboardDesktopState
    extends ConsumerState<TeacherDashboardDesktop> {
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
    final classes = classState.classes;

    return DesktopPageScaffold(
      title: 'Dashboard',
      subtitle: 'Welcome',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stats row
          TeacherStatsRow(classes: classes),
          const SizedBox(height: 32),

          // Classes section
          const Text(
            'My Classes',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF202020),
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 16),

          if (classState.isLoading && classes.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(48),
                child: CircularProgressIndicator(
                  color: AppColors.foregroundPrimary,
                  strokeWidth: 2.5,
                ),
              ),
            )
          else if (classes.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(48),
                child: Column(
                  children: [
                    Icon(Icons.school_outlined,
                        size: 48, color: AppColors.borderLight),
                    SizedBox(height: 12),
                    Text(
                      'No classes assigned yet',
                      style: TextStyle(
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
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: classes.map((cls) {
                final subtitle = cls.isAdvisory
                    ? '${cls.studentCount} student${cls.studentCount != 1 ? 's' : ''} · Advisory'
                    : '${cls.studentCount} student${cls.studentCount != 1 ? 's' : ''}';
                return SizedBox(
                  width: 380,
                  child: NavigationCard(
                    icon: Icons.school_outlined,
                    title: cls.title,
                    subtitle: subtitle,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            TeacherClassDetailDesktop(classId: cls.id),
                      ),
                    ).then(
                        (_) => ref.read(classProvider.notifier).loadClasses()),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}
