import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/presentation/layouts/mobile/mobile_shell_scaffold.dart';
import 'package:likha/presentation/pages/teacher/class/classes_page.dart';
import 'package:likha/presentation/pages/teacher/grade/grades_page.dart';
import 'package:likha/presentation/pages/teacher/profile_page.dart';

class TeacherShellPage extends ConsumerStatefulWidget {
  const TeacherShellPage({super.key});

  @override
  ConsumerState<TeacherShellPage> createState() => _TeacherShellPageState();
}

class _TeacherShellPageState extends ConsumerState<TeacherShellPage> {
  int _currentIndex = 0;

  final _pages = const [
    TeacherClassesPage(),
    TeacherGradesPage(),
    TeacherProfilePage(),
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
          icon: Icon(Icons.grading_outlined),
          activeIcon: Icon(Icons.grading),
          label: 'Grades',
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
