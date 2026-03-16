import 'package:fleather/fleather.dart';
import 'package:flutter/material.dart';
import 'package:likha/presentation/pages/shared/widgets/forms/rich_text_field.dart';

class AssignmentTextInputCard extends StatelessWidget {
  final FleatherController controller;
  final bool isReadOnly;

  const AssignmentTextInputCard({
    super.key,
    required this.controller,
    required this.isReadOnly,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
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
          const SizedBox(height: 8),
          RichTextField(
            controller: controller,
            label: 'Your Response',
            icon: Icons.edit_note_rounded,
            enabled: !isReadOnly,
            minHeight: 160,
            hintText: isReadOnly
                ? 'No response provided'
                : 'Type your response here...',
          ),
        ],
      ),
    );
  }
}