import 'package:flutter/material.dart';

class StudentListItem extends StatelessWidget {
  final String studentId;
  final String fullName;
  final String username;
  final VoidCallback onRemove;

  const StudentListItem({
    super.key,
    required this.studentId,
    required this.fullName,
    required this.username,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFE0E0E0),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        margin: const EdgeInsets.fromLTRB(1, 1, 1, 2.5),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(11),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 4,
          ),
          leading: CircleAvatar(
            backgroundColor: const Color(0xFFF8F9FA),
            child: Text(
              fullName[0].toUpperCase(),
              style: const TextStyle(
                color: Color(0xFF404040),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          title: Text(
            fullName,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Color(0xFF202020),
              letterSpacing: -0.2,
            ),
          ),
          subtitle: Text(
            username,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF999999),
            ),
          ),
          trailing: IconButton(
            icon: const Icon(
              Icons.remove_circle_outline_rounded,
              color: Color(0xFFEF5350),
            ),
            onPressed: onRemove,
          ),
        ),
      ),
    );
  }
}