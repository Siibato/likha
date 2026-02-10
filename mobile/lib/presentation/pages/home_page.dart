import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/presentation/pages/admin/admin_dashboard_page.dart';
import 'package:likha/presentation/pages/student/student_shell_page.dart';
import 'package:likha/presentation/pages/teacher/teacher_dashboard_page.dart';
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
        return const AdminDashboardPage();
      case 'teacher':
        return const TeacherDashboardPage();
      case 'student':
        return const StudentShellPage();
      default:
        return const Scaffold(
          body: Center(child: Text('Unknown role')),
        );
    }
  }
}
