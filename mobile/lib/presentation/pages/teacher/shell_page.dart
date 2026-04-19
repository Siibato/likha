import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: const Color(0xFF2B2B2B),
        unselectedItemColor: const Color(0xFF9E9E9E),
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
      ),
    );
  }
}
