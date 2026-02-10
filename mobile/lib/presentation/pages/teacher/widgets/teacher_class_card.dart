import 'package:flutter/material.dart';

class TeacherClassCard extends StatelessWidget {
  final String title;
  final int studentCount;
  final VoidCallback onTap;

  const TeacherClassCard({
    super.key,
    required this.title,
    required this.studentCount,
    required this.onTap,
  });

  IconData _getSubjectIcon(String title) {
    final t = title.toLowerCase();
    if (t.contains('math')) return Icons.functions_rounded;
    if (t.contains('science')) return Icons.science_outlined;
    if (t.contains('art')) return Icons.palette_outlined;
    if (t.contains('english') || t.contains('literature')) {
      return Icons.menu_book_rounded;
    }
    if (t.contains('history')) return Icons.history_edu_rounded;
    if (t.contains('music')) return Icons.music_note_rounded;
    return Icons.class_outlined;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFE0E0E0),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          margin: const EdgeInsets.fromLTRB(1, 1, 1, 3.5),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Row(
            children: [
              _buildIcon(),
              const SizedBox(width: 16),
              Expanded(child: _buildContent()),
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

  Widget _buildIcon() {
    return Container(
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
    );
  }

  Widget _buildContent() {
    return Column(
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
          '$studentCount student${studentCount != 1 ? 's' : ''}',
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Color(0xFF999999),
          ),
        ),
      ],
    );
  }
}