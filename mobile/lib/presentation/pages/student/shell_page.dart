import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/core/theme/app_colors.dart';
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
    return Scaffold(
      backgroundColor: AppColors.backgroundTertiary,
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: AppColors.accentCharcoal,
        unselectedItemColor: AppColors.foregroundTertiary,
        backgroundColor: Colors.white,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedFontSize: 12,
        unselectedFontSize: 12,
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
      ),
    );
  }
}
