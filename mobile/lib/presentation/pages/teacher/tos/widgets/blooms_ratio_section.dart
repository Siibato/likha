import 'package:flutter/material.dart';
import 'package:likha/core/theme/app_colors.dart';

class BloomsRatioSection extends StatefulWidget {
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
  State<BloomsRatioSection> createState() => _BloomsRatioSectionState();
}

class _BloomsRatioSectionState extends State<BloomsRatioSection> {
  double _total = 0;

  List<TextEditingController> get _controllers => [
        widget.rememberingController,
        widget.understandingController,
        widget.applyingController,
        widget.analyzingController,
        widget.evaluatingController,
        widget.creatingController,
      ];

  @override
  void initState() {
    super.initState();
    _computeTotal();
    for (final c in _controllers) {
      c.addListener(_computeTotal);
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.removeListener(_computeTotal);
    }
    super.dispose();
  }

  void _computeTotal() {
    final total = _controllers.fold(
        0.0, (sum, c) => sum + (double.tryParse(c.text.trim()) ?? 0));
    if (mounted) setState(() => _total = total);
  }

  @override
  Widget build(BuildContext context) {
    final isValid = (_total - 100).abs() <= 0.5;
    final totalColor = isValid ? AppColors.semanticSuccess : AppColors.semanticErrorDark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  "Bloom's Level Distribution (%)",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.foregroundSecondary,
                  ),
                ),
              ),
              Text(
                isValid
                    ? 'Total: ${_total.toStringAsFixed(1)}% ✓'
                    : 'Total: ${_total.toStringAsFixed(1)}% ⚠',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: totalColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const SizedBox(height: 4),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _PctField(
                  controller: widget.rememberingController,
                  label: 'R',
                  color: AppColors.accentCharcoal,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _PctField(
                  controller: widget.understandingController,
                  label: 'U',
                  color: AppColors.accentCharcoal,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _PctField(
                  controller: widget.applyingController,
                  label: 'Ap',
                  color: AppColors.semanticSuccess,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _PctField(
                  controller: widget.analyzingController,
                  label: 'An',
                  color: AppColors.accentAmber,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _PctField(
                  controller: widget.evaluatingController,
                  label: 'E',
                  color: AppColors.accentAmberBorder,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _PctField(
                  controller: widget.creatingController,
                  label: 'C',
                  color: AppColors.semanticErrorDark,
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
                style: const TextStyle(fontSize: 11, color: AppColors.foregroundSecondary)),
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
            color: AppColors.accentCharcoal,
          ),
          decoration: InputDecoration(
            suffixText: '%',
            suffixStyle: const TextStyle(fontSize: 12, color: AppColors.foregroundTertiary),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.borderLight),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.borderLight),
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
