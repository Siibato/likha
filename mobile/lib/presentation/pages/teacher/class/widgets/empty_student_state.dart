import 'package:flutter/material.dart';

class EmptyStudentState extends StatelessWidget {
  const EmptyStudentState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FA),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.people_outline_rounded,
                size: 48,
                color: Color(0xFFCCCCCC),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'No students enrolled yet',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Color(0xFF999999),
              ),
            ),
          ],
        ),
      ),
    );
  }
}