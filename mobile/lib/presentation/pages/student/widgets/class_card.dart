import 'package:flutter/material.dart';

class ClassCard extends StatelessWidget {
  final String title;
  final String teacher;
  final VoidCallback onTap;

  static const _borderColor = Color(0xFFE0E0E0);

  const ClassCard({
    super.key,
    required this.title,
    required this.teacher,
    required this.onTap,
  });

  IconData _getSubjectIcon(String title) {
    final t = title.toLowerCase();
    if (t.contains('math')) return Icons.functions_rounded;
    if (t.contains('science')) return Icons.science_outlined;
    if (t.contains('art')) return Icons.palette_outlined;
    return Icons.class_outlined;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        // This outer container creates the "thick" bottom border effect
        decoration: BoxDecoration(
          color: _borderColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          // Adjust the 3.5 value to control the "thickness" of the bottom edge
          margin: const EdgeInsets.fromLTRB(1, 1, 1, 3.5),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Row(
            children: [
              // 1. Left Icon (Subject based)
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FA),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getSubjectIcon(title),
                  color: const Color(0xFF404040),
                  size: 22,
                ),
              ),
              const SizedBox(width: 16),
              
              // 2. Center Text content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF202020),
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      teacher,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF999999),
                      ),
                    ),
                  ],
                ),
              ),
              
              // 3. Right Chevron
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFFCCCCCC),
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}