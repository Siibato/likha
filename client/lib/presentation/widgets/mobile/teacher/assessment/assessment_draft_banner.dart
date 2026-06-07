import 'package:flutter/material.dart';
import 'package:likha/presentation/widgets/shared/banners/base_status_banner.dart';
import 'package:likha/presentation/widgets/shared/forms/styled_button.dart';

/// Inline banner shown when a saved draft is being resumed.
///
/// Displays a "Resuming draft" label and a "Discard" action.
class AssessmentDraftBanner extends StatelessWidget {
  final VoidCallback onDiscard;

  const AssessmentDraftBanner({super.key, required this.onDiscard});

  @override
  Widget build(BuildContext context) {
    return BaseStatusBanner(
      title: 'Resuming draft',
      message: null,
      icon: Icons.restore_rounded,
      variant: BaseStatusBannerVariant.neutral,
      action: StyledButton(
        text: 'Discard',
        variant: StyledButtonVariant.destructive,
        isLoading: false,
        onPressed: onDiscard,
        fullWidth: false,
      ),
      margin: const EdgeInsets.only(bottom: 16),
    );
  }
}
