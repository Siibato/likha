import 'package:flutter/material.dart';

class AssignmentSubmittedBanner extends StatelessWidget {
  const AssignmentSubmittedBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFE0E0E0),
        ),
      ),
      child: const Row(
        children: [
          Icon(
            Icons.check_circle_rounded,
            color: Color(0xFF666666),
            size: 22,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Assignment submitted. Waiting for teacher to grade.',
              style: TextStyle(
                color: Color(0xFF2B2B2B),
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}