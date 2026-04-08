import 'package:flutter/material.dart';

class BloomsRatioSection extends StatelessWidget {
  final TextEditingController rememberingController;
  final TextEditingController understandingController;
  final TextEditingController applyingController;
  final TextEditingController analyzingController;
  final TextEditingController evaluatingController;
  final TextEditingController creatingController;

  const BloomsRatioSection({
    super.key,
    required this.rememberingController,
    required this.understandingController,
    required this.applyingController,
    required this.analyzingController,
    required this.evaluatingController,
    required this.creatingController,
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
            "Bloom's Level Distribution (%)",
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF666666),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'R=Remembering, U=Understanding, Ap=Applying, An=Analyzing, E=Evaluating, C=Creating',
            style: TextStyle(fontSize: 11, color: Color(0xFF999999)),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _PctField(
                  controller: rememberingController,
                  label: 'R',
                  color: const Color(0xFF1565C0),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _PctField(
                  controller: understandingController,
                  label: 'U',
                  color: const Color(0xFF283593),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _PctField(
                  controller: applyingController,
                  label: 'Ap',
                  color: const Color(0xFF2E7D32),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _PctField(
                  controller: analyzingController,
                  label: 'An',
                  color: const Color(0xFFF57F17),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _PctField(
                  controller: evaluatingController,
                  label: 'E',
                  color: const Color(0xFFE65100),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _PctField(
                  controller: creatingController,
                  label: 'C',
                  color: const Color(0xFFC62828),
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
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Color(0xFF2B2B2B),
          ),
          decoration: InputDecoration(
            suffixText: '%',
            suffixStyle: const TextStyle(fontSize: 12, color: Color(0xFF999999)),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
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
