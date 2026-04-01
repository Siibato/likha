import 'package:flutter/material.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'desktop_breakpoints.dart';

class DesktopNavigationRail extends StatelessWidget {
  final int selectedIndex;
  final List<DesktopNavDestination> destinations;
  final ValueChanged<int> onDestinationSelected;
  final VoidCallback? onLogout;
  final Widget? header;

  const DesktopNavigationRail({
    super.key,
    required this.selectedIndex,
    required this.destinations,
    required this.onDestinationSelected,
    this.onLogout,
    this.header,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = DesktopBreakpoints.isCompact(
          MediaQuery.of(context).size.width,
        );
        final railWidth = isCompact ? 72.0 : 220.0;

        return Container(
          width: railWidth,
          color: Colors.white,
          child: Column(
            children: [
              // Header
              if (header != null)
                header!
              else
                Padding(
                  padding: EdgeInsets.symmetric(
                    vertical: 24,
                    horizontal: isCompact ? 16 : 24,
                  ),
                  child: Image.asset(
                    'assets/images/likha-logo.png',
                    height: isCompact ? 32 : 40,
                  ),
                ),
              const Divider(height: 1, color: AppColors.borderLight),
              const SizedBox(height: 8),

              // Navigation destinations
              ...List.generate(destinations.length, (index) {
                final dest = destinations[index];
                final isSelected = index == selectedIndex;

                return _NavItem(
                  icon: dest.icon,
                  selectedIcon: dest.selectedIcon ?? dest.icon,
                  label: dest.label,
                  isSelected: isSelected,
                  isCompact: isCompact,
                  onTap: () => onDestinationSelected(index),
                );
              }),

              const Spacer(),

              // Logout button (optional)
              if (onLogout != null) ...[
                const Divider(height: 1, color: AppColors.borderLight),
                _NavItem(
                  icon: Icons.logout_rounded,
                  selectedIcon: Icons.logout_rounded,
                  label: 'Log out',
                  isSelected: false,
                  isCompact: isCompact,
                  onTap: onLogout!,
                ),
                const SizedBox(height: 16),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool isSelected;
  final bool isCompact;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.isSelected,
    required this.isCompact,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isSelected
        ? AppColors.foregroundDark
        : AppColors.foregroundTertiary;
    final bgColor = isSelected
        ? AppColors.backgroundTertiary
        : Colors.transparent;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 8 : 12,
        vertical: 2,
      ),
      child: Material(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.symmetric(
              vertical: 12,
              horizontal: isCompact ? 0 : 16,
            ),
            child: isCompact
                ? Center(
                    child: Icon(
                      isSelected ? selectedIcon : icon,
                      color: color,
                      size: 22,
                    ),
                  )
                : Row(
                    children: [
                      Icon(
                        isSelected ? selectedIcon : icon,
                        color: color,
                        size: 22,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          label,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight:
                                isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: color,
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class DesktopNavDestination {
  final IconData icon;
  final IconData? selectedIcon;
  final String label;

  const DesktopNavDestination({
    required this.icon,
    this.selectedIcon,
    required this.label,
  });
}
