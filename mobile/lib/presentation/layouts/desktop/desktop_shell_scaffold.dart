import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'desktop_navigation_rail.dart';

/// Template shell for desktop role screens.
///
/// Provides a [DesktopNavigationRail] on the left and an [IndexedStack] on the
/// right. Keyboard shortcuts (Ctrl/Cmd + 1…n) switch tabs automatically.
class DesktopShellScaffold extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onIndexChanged;
  final List<DesktopNavDestination> destinations;
  final List<Widget> pages;
  final VoidCallback? onLogout;
  final Widget? railHeader;

  const DesktopShellScaffold({
    super.key,
    required this.currentIndex,
    required this.onIndexChanged,
    required this.destinations,
    required this.pages,
    this.onLogout,
    this.railHeader,
  });

  bool get _isMacOS {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.macOS;
  }

  Map<ShortcutActivator, VoidCallback> _buildShortcuts() {
    final Map<ShortcutActivator, VoidCallback> bindings = {};
    for (int i = 0; i < pages.length && i < 9; i++) {
      final index = i;
      bindings[SingleActivator(
        LogicalKeyboardKey(0x00000031 + i), // digit 1..9
        meta: _isMacOS,
        control: !_isMacOS,
      )] = () => onIndexChanged(index);
    }
    return bindings;
  }

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: _buildShortcuts(),
      child: Focus(
        autofocus: true,
        child: Scaffold(
          backgroundColor: AppColors.backgroundSecondary,
          body: Row(
            children: [
              DesktopNavigationRail(
                selectedIndex: currentIndex,
                destinations: destinations,
                onDestinationSelected: onIndexChanged,
                onLogout: onLogout,
                header: railHeader,
              ),
              const VerticalDivider(
                thickness: 1,
                width: 1,
                color: AppColors.borderLight,
              ),
              Expanded(
                child: IndexedStack(
                  index: currentIndex,
                  children: pages,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
