import 'package:flutter/material.dart';

class EmptyGradesState extends StatelessWidget {
  const EmptyGradesState({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.school_outlined,
            size: 64,
            color: Color(0xFFCCCCCC),
          ),
          SizedBox(height: 16),
          Text(
            'No classes yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2B2B2B),
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Check back later',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF7A7A7A),
            ),
          ),
        ],
      ),
    );
  }
}
