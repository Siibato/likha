import 'package:flutter/material.dart';
import 'base_card.dart';
import '../primitives/card_icon_slot.dart';
import '../primitives/chevron_trailing.dart';
import '../tokens/app_dimensions.dart';
import '../tokens/app_text_styles.dart';

/// A large navigation card used on dashboards and overview pages.
///
/// Merges [DashboardCard] and [ClassNavigationCard] into a single, reusable widget.
/// Uses larger icon slot and padding compared to standard [BaseCard].
class NavigationCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const NavigationCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BaseCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppDimensions.kCardPadXl),
      margin: EdgeInsets.zero, // No margin - callers handle spacing in grid/detail layouts
      child: Row(
        children: [
          CardIconSlot.lg(icon: icon),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: AppTextStyles.cardTitleMd,
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: AppTextStyles.cardSubtitleMd,
                ),
              ],
            ),
          ),
          ChevronTrailing.large(),
        ],
      ),
    );
  }
}
