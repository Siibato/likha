import 'package:flutter/material.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/presentation/widgets/shared/cards/base_card.dart';
import 'package:likha/presentation/widgets/shared/primitives/info_chip.dart';
import 'package:likha/presentation/widgets/shared/primitives/status_badge.dart';

/// Summary card showing material title, description, file count,
/// last-updated date, and a pending-sync badge when needed.
class MaterialInfoCard extends StatelessWidget {
  final String title;
  final String? description;
  final int fileCount;
  final DateTime updatedAt;
  final bool needsSync;

  const MaterialInfoCard({
    super.key,
    required this.title,
    this.description,
    required this.fileCount,
    required this.updatedAt,
    this.needsSync = false,
  });

  String _formatDate(DateTime dt) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    return BaseCard(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AppColors.accentCharcoal,
              letterSpacing: -0.5,
            ),
          ),
          if (description != null && description!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(height: 1, color: AppColors.borderLight),
            const SizedBox(height: 12),
            Text(
              description!,
              style: const TextStyle(
                fontSize: 15,
                color: AppColors.accentCharcoal,
                height: 1.5,
              ),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              InfoChip(
                icon: Icons.attach_file_rounded,
                label: '$fileCount file(s)',
              ),
              const SizedBox(width: 14),
              InfoChip(
                icon: Icons.schedule_rounded,
                label: 'Updated ${_formatDate(updatedAt)}',
              ),
            ],
          ),
          if (needsSync) ...[
            const SizedBox(height: 12),
            const StatusBadge(
              label: 'Pending sync',
              color: AppColors.foregroundTertiary,
              variant: BadgeVariant.outlined,
            ),
          ],
        ],
      ),
    );
  }
}
