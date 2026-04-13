import 'package:flutter/material.dart';

class ViewTosChip extends StatelessWidget {
  final VoidCallback onTap;

  const ViewTosChip({
    super.key,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFE8F0FE),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFBBD0FB)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.table_chart_outlined, size: 16, color: Color(0xFF2B6CB0)),
            SizedBox(width: 6),
            Text(
              'View Linked TOS',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2B6CB0),
              ),
            ),
            SizedBox(width: 4),
            Icon(Icons.open_in_new_rounded, size: 14, color: Color(0xFF2B6CB0)),
          ],
        ),
      ),
    );
  }
}
