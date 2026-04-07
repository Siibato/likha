import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/presentation/pages/admin/admin_dashboard_page.dart';
import 'package:likha/presentation/pages/desktop/admin/admin_desktop_shell.dart';
import 'package:likha/presentation/pages/desktop/core/platform_detector.dart';
import 'package:likha/presentation/pages/desktop/teacher/teacher_desktop_shell.dart';
import 'package:likha/presentation/pages/student/student_shell_page.dart';
import 'package:likha/presentation/pages/teacher/teacher_shell_page.dart';
import 'package:likha/presentation/providers/auth_provider.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;

    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    switch (user.role) {
      case 'admin':
        return PlatformDetector.isDesktop
            ? const AdminDesktopShell()
            : const AdminDashboardPage();
      case 'teacher':
        return PlatformDetector.isDesktop
            ? const TeacherDesktopShell()
            : const TeacherShellPage();
      case 'student':
        return const StudentShellPage();
      default:
        return const Scaffold(
          body: Center(child: Text('Unknown role')),
        );
    }
  }
}
