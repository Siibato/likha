import 'package:flutter/material.dart';

class AdminHeader extends StatelessWidget {
  final String fullName;

  const AdminHeader({
    super.key,
    required this.fullName,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Welcome back',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Color(0xFF999999),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          fullName,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: Color(0xFF202020),
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }
}