import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/presentation/layouts/desktop/desktop_navigation_rail.dart';
import 'package:likha/presentation/pages/desktop/teacher/dashboard_page.dart';
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
                ExcludeFocus(
                  excluding: _currentIndex != 0,
                  child: TeacherDashboardPage(onNavigate: _navigateToIndex),
                ),
              ],
            ),
          ),
        ],
      ),
    )),
    );
  }
}
