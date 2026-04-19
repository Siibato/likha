import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/presentation/pages/desktop/core/desktop_navigation_rail.dart';
import 'package:likha/presentation/pages/desktop/teacher/teacher_classes_desktop.dart';
import 'package:likha/presentation/pages/desktop/teacher/teacher_dashboard_desktop.dart';
import 'package:likha/presentation/pages/desktop/teacher/grade/grades_desktop.dart';
import 'package:likha/presentation/utils/logout_helper.dart';

class TeacherDesktopShell extends ConsumerStatefulWidget {
  const TeacherDesktopShell({super.key});

  @override
  ConsumerState<TeacherDesktopShell> createState() =>
      _TeacherDesktopShellState();
}

class _TeacherDesktopShellState extends ConsumerState<TeacherDesktopShell> {
  int _currentIndex = 0;

  void _navigateToIndex(int index) {
    setState(() => _currentIndex = index);
  }

  bool get _isMacOS {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.macOS;
  }

  @override
  Widget build(BuildContext context) {

    return CallbackShortcuts(
      bindings: {
        SingleActivator(LogicalKeyboardKey.digit1, meta: _isMacOS, control: !_isMacOS):
            () => _navigateToIndex(0),
        SingleActivator(LogicalKeyboardKey.digit2, meta: _isMacOS, control: !_isMacOS):
            () => _navigateToIndex(1),
        SingleActivator(LogicalKeyboardKey.digit3, meta: _isMacOS, control: !_isMacOS):
            () => _navigateToIndex(2),
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
      backgroundColor: AppColors.backgroundSecondary,
      body: Row(
        children: [
          DesktopNavigationRail(
            selectedIndex: _currentIndex,
            destinations: const [
              DesktopNavDestination(
                icon: Icons.dashboard_outlined,
                selectedIcon: Icons.dashboard_rounded,
                label: 'Dashboard',
              ),
              DesktopNavDestination(
                icon: Icons.school_outlined,
                selectedIcon: Icons.school_rounded,
                label: 'Classes',
              ),
              DesktopNavDestination(
                icon: Icons.grading_outlined,
                selectedIcon: Icons.grading,
                label: 'Grades',
              ),
            ],
            onDestinationSelected: _navigateToIndex,
            onLogout: () => handleLogoutTap(context, ref),
          ),
          const VerticalDivider(
            thickness: 1,
            width: 1,
            color: AppColors.borderLight,
          ),
          Expanded(
            child: IndexedStack(
              index: _currentIndex,
              children: [
                TeacherDashboardDesktop(onNavigate: _navigateToIndex),
                const TeacherClassesDesktop(),
                const TeacherGradesDesktop(),
              ],
            ),
          ),
        ],
      ),
    )),
    );
  }
}
