import 'package:flutter/material.dart';

class ClassificationModeToggle extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const ClassificationModeToggle({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Classification Mode',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Color(0xFF666666),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _ModeChip(
                label: "Bloom's Taxonomy",
                icon: Icons.psychology_outlined,
                isSelected: value == 'blooms',
                onTap: () => onChanged('blooms'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _ModeChip(
                label: 'Difficulty',
                icon: Icons.signal_cellular_alt_rounded,
                isSelected: value == 'difficulty',
                onTap: () => onChanged('difficulty'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ModeChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _ModeChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2B2B2B) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? const Color(0xFF2B2B2B) : const Color(0xFFE0E0E0),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : const Color(0xFF666666),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : const Color(0xFF666666),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
