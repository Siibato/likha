import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/presentation/layouts/mobile/mobile_shell_scaffold.dart';
import 'package:likha/presentation/pages/student/class/classes_page.dart';
import 'package:likha/presentation/pages/student/tasks_page.dart';
import 'package:likha/presentation/pages/student/profile_page.dart';

class StudentShellPage extends ConsumerStatefulWidget {
  const StudentShellPage({super.key});

  @override
  ConsumerState<StudentShellPage> createState() => _StudentShellPageState();
}

class _StudentShellPageState extends ConsumerState<StudentShellPage> {
  int _currentIndex = 0;

  final _pages = const [
    StudentClassesPage(),
    StudentTasksPage(),
    StudentProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return MobileShellScaffold(
      currentIndex: _currentIndex,
      onIndexChanged: (index) => setState(() => _currentIndex = index),
      pages: _pages,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.school_outlined),
          activeIcon: Icon(Icons.school),
          label: 'Classes',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.assignment_outlined),
          activeIcon: Icon(Icons.assignment),
          label: 'Tasks',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          activeIcon: Icon(Icons.person),
          label: 'Profile',
        ),
      ],
    );
  }
}
