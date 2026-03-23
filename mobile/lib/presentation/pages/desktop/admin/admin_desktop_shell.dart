import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/presentation/pages/desktop/admin/account_management_desktop.dart';
import 'package:likha/presentation/pages/desktop/admin/admin_classes_desktop.dart';
import 'package:likha/presentation/pages/desktop/admin/admin_dashboard_desktop.dart';
import 'package:likha/presentation/pages/desktop/admin/admin_school_settings_desktop.dart';
import 'package:likha/presentation/pages/desktop/core/desktop_navigation_rail.dart';
import 'package:likha/presentation/utils/logout_helper.dart';

class AdminDesktopShell extends ConsumerStatefulWidget {
  const AdminDesktopShell({super.key});

  @override
  ConsumerState<AdminDesktopShell> createState() => _AdminDesktopShellState();
}

class _AdminDesktopShellState extends ConsumerState<AdminDesktopShell> {
  int _currentIndex = 0;

  void _navigateToIndex(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                icon: Icons.people_outline_rounded,
                selectedIcon: Icons.people_rounded,
                label: 'Accounts',
              ),
              DesktopNavDestination(
                icon: Icons.school_outlined,
                selectedIcon: Icons.school_rounded,
                label: 'Classes',
              ),
              DesktopNavDestination(
                icon: Icons.settings_outlined,
                selectedIcon: Icons.settings_rounded,
                label: 'Settings',
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
                AdminDashboardDesktop(onNavigate: _navigateToIndex),
                const AccountManagementDesktop(),
                const AdminClassesDesktop(),
                const AdminSchoolSettingsDesktop(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
