import 'package:flutter/material.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/presentation/pages/shared/widgets/cards/base_card.dart';

class AssignmentTextInputCard extends StatelessWidget {
  final TextEditingController controller;
  final bool isReadOnly;

  const AssignmentTextInputCard({
    super.key,
    required this.controller,
    required this.isReadOnly,
  });

  @override
  Widget build(BuildContext context) {
    return BaseCard(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your Response',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF202020),
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: controller,
            maxLines: 10,
            readOnly: isReadOnly,
            style: TextStyle(
              fontSize: 15,
              color: isReadOnly
                  ? AppColors.foregroundSecondary
                  : AppColors.foregroundPrimary,
            ),
            decoration: InputDecoration(
              hintText: isReadOnly
                  ? 'No response provided'
                  : 'Type your response here...',
              hintStyle: const TextStyle(
                color: Color(0xFFCCCCCC),
                fontSize: 15,
              ),
              filled: true,
              fillColor: isReadOnly
                  ? AppColors.backgroundDisabled
                  : AppColors.backgroundSecondary,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: AppColors.borderLight,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: AppColors.borderLight,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: isReadOnly
                      ? AppColors.borderLight
                      : AppColors.deprecatedWarningYellow,
                  width: isReadOnly ? 1 : 2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}