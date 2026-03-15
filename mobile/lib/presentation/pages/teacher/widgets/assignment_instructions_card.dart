import 'package:flutter/material.dart';
import 'package:likha/presentation/pages/shared/widgets/cards/markdown_display.dart';

class AssignmentInstructionsCard extends StatelessWidget {
  final String instructions;

  const AssignmentInstructionsCard({
    super.key,
    required this.instructions,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFE0E0E0),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Instructions',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF202020),
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 12),
          MarkdownDisplay(
            content: instructions,
          ),
        ],
      ),
    );
  }
}