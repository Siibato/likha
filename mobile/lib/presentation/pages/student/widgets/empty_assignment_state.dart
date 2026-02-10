import 'package:flutter/material.dart';

class EmptyAssignmentState extends StatelessWidget {
  const EmptyAssignmentState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(
              Icons.assignment_outlined,
              size: 64,
              color: Color(0xFFCCCCCC),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No assignments yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF666666),
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Assignments will appear here when available',
            style: TextStyle(
              color: Color(0xFF999999),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}