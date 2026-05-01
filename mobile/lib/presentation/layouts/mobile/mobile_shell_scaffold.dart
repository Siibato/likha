import 'package:flutter/material.dart';
import 'package:likha/core/theme/app_colors.dart';

/// Template shell for mobile role screens.
///
/// Provides a [BottomNavigationBar] with an [IndexedStack] for the page body.
/// Consistent styling is enforced across all role shells (teacher, student).
class MobileShellScaffold extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onIndexChanged;
  final List<Widget> pages;
  final List<BottomNavigationBarItem> items;

  const MobileShellScaffold({
    super.key,
    required this.currentIndex,
    required this.onIndexChanged,
    required this.pages,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundSecondary,
      body: IndexedStack(
        index: currentIndex,
        children: pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: onIndexChanged,
        selectedItemColor: AppColors.accentCharcoal,
        unselectedItemColor: AppColors.foregroundLight,
        backgroundColor: Colors.white,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        items: items,
      ),
    );
  }
}
