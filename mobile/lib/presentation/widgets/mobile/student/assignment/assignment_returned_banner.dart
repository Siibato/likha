import 'package:flutter/material.dart';
import 'package:likha/presentation/widgets/shared/banners/base_status_banner.dart';

class AssignmentReturnedBanner extends StatelessWidget {
  final String feedback;

  const AssignmentReturnedBanner({
    super.key,
    required this.feedback,
  });

  @override
  Widget build(BuildContext context) {
    return BaseStatusBanner(
      title: 'Returned for Revision',
      message: feedback,
      icon: Icons.replay_rounded,
      variant: BaseStatusBannerVariant.warning,
    );
  }
}