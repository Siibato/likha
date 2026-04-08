import 'package:flutter/material.dart';

class DifficultyRatioSection extends StatelessWidget {
  final TextEditingController easyController;
  final TextEditingController mediumController;
  final TextEditingController hardController;

  const DifficultyRatioSection({
    super.key,
    required this.easyController,
    required this.mediumController,
    required this.hardController,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Default Difficulty Distribution (%)',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF666666),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Sets default % of items per difficulty level. Each competency can override these.',
            style: TextStyle(fontSize: 11, color: Color(0xFF999999)),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _PctField(
                  controller: easyController,
                  label: 'Easy',
                  color: const Color(0xFF4CAF50),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _PctField(
                  controller: mediumController,
                  label: 'Medium',
                  color: const Color(0xFFFF9800),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _PctField(
                  controller: hardController,
                  label: 'Hard',
                  color: const Color(0xFFF44336),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PctField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final Color color;

  const _PctField({
    required this.controller,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 4),
            Text(label,
                style: const TextStyle(fontSize: 11, color: Color(0xFF666666))),
          ],
        ),
        const SizedBox(height: 4),
        TextFormField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Color(0xFF2B2B2B),
          ),
          decoration: InputDecoration(
            suffixText: '%',
            suffixStyle: const TextStyle(fontSize: 12, color: Color(0xFF999999)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: color),
            ),
          ),
          validator: (v) {
            if (v == null || v.trim().isEmpty) return 'Required';
            final n = double.tryParse(v.trim());
            if (n == null || n < 0 || n > 100) return 'Invalid';
            return null;
          },
        ),
      ],
    );
  }
}
