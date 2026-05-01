import 'package:flutter/material.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/core/utils/transmutation_util.dart';
import 'package:likha/domain/grading/entities/period_grade.dart';

/// Summary card showing initial grade, transmuted grade, and descriptor badge.
class GradeSummarySection extends StatelessWidget {
  final PeriodGrade quarterGrade;

  const GradeSummarySection({super.key, required this.quarterGrade});

  @override
  Widget build(BuildContext context) {
    final transmuted = quarterGrade.transmutedGrade ?? 0;
    final descriptor = TransmutationUtil.getDescriptor(transmuted);
    final descriptorColor = TransmutationUtil.getDescriptorColor(transmuted);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.borderLight,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        margin: const EdgeInsets.fromLTRB(1, 1, 1, 3.5),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.all(Radius.circular(15)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _SummaryRow(
                label: 'Initial Grade',
                value: quarterGrade.initialGrade != null
                    ? quarterGrade.initialGrade!.toStringAsFixed(1)
                    : '--',
              ),
              const SizedBox(height: 8),
              _SummaryRow(label: 'Transmuted Grade', value: '$transmuted', isBold: true),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Descriptor',
                    style: TextStyle(fontSize: 13, color: AppColors.foregroundTertiary),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Color(descriptorColor),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      descriptor,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isBold;

  const _SummaryRow({required this.label, required this.value, this.isBold = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: AppColors.foregroundTertiary),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w600,
            color: AppColors.accentCharcoal,
          ),
        ),
      ],
    );
  }
}
