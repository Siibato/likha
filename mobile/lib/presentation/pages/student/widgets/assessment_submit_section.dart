import 'package:flutter/material.dart';
import 'package:likha/presentation/utils/formatters.dart';

class AssessmentSubmitSection extends StatelessWidget {
  final int remainingSeconds;
  final bool isSubmitting;
  final VoidCallback onSubmit;

  const AssessmentSubmitSection({
    super.key,
    required this.remainingSeconds,
    required this.isSubmitting,
    required this.onSubmit,
  });

  Color _timerColor() {
    if (remainingSeconds <= 60) return const Color(0xFFEA4335);
    if (remainingSeconds <= 300) return const Color(0xFFFFBD59);
    return const Color(0xFF666666);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          Container(
            height: 1,
            color: const Color(0xFFE0E0E0),
          ),
          const SizedBox(height: 20),
          Text(
            'Time Remaining: ${Formatters.formatTime(remainingSeconds)}',
            style: TextStyle(
              fontSize: 14,
              color: _timerColor(),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton.icon(
              onPressed: isSubmitting ? null : onSubmit,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF2B2B2B),
                disabledBackgroundColor: const Color(0xFFE0E0E0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: isSubmitting
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Color(0xFF999999),
                      ),
                    )
                  : const Icon(Icons.send_rounded),
              label: Text(
                isSubmitting ? 'Submitting...' : 'Submit Assessment',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}