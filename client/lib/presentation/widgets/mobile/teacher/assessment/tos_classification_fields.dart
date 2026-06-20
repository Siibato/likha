import 'package:flutter/material.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/domain/tos/entities/tos_entity.dart';

/// Competency and cognitive level dropdowns used in question add/edit flows.
class TosClassificationFields extends StatelessWidget {
  final List<TosCompetency> competencies;
  final String classificationMode;
  final String? selectedCompetencyId;
  final String? selectedCognitiveLevel;
  final ValueChanged<String?>? onCompetencyChanged;
  final ValueChanged<String?>? onCognitiveLevelChanged;
  final bool enabled;

  const TosClassificationFields({
    super.key,
    required this.competencies,
    required this.classificationMode,
    this.selectedCompetencyId,
    this.selectedCognitiveLevel,
    this.onCompetencyChanged,
    this.onCognitiveLevelChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildDropdown(
          label: 'Competency (optional)',
          icon: Icons.list_alt_rounded,
          value: selectedCompetencyId,
          items: [
            const DropdownMenuItem(value: null, child: Text('None')),
            ...competencies.map((c) => DropdownMenuItem(
                  value: c.id,
                  child: Text(
                    c.competencyCode != null
                        ? '${c.competencyCode} - ${c.competencyText}'
                        : c.competencyText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                )),
          ],
          onChanged: enabled ? onCompetencyChanged : null,
        ),
        const SizedBox(height: 16),
        _buildDropdown(
          label: 'Cognitive Level (optional)',
          icon: Icons.psychology_outlined,
          value: selectedCognitiveLevel,
          items: [
            const DropdownMenuItem(value: null, child: Text('None')),
            if (classificationMode == 'blooms') ...[
              const DropdownMenuItem(value: 'Remembering', child: Text('Remembering')),
              const DropdownMenuItem(value: 'Understanding', child: Text('Understanding')),
              const DropdownMenuItem(value: 'Applying', child: Text('Applying')),
              const DropdownMenuItem(value: 'Analyzing', child: Text('Analyzing')),
              const DropdownMenuItem(value: 'Evaluating', child: Text('Evaluating')),
              const DropdownMenuItem(value: 'Creating', child: Text('Creating')),
            ] else ...[
              const DropdownMenuItem(value: 'Easy', child: Text('Easy')),
              const DropdownMenuItem(value: 'Average', child: Text('Average')),
              const DropdownMenuItem(value: 'Difficult', child: Text('Difficult')),
            ],
          ],
          onChanged: enabled ? onCognitiveLevelChanged : null,
        ),
      ],
    );
  }

  Widget _buildDropdown({
    required String label,
    required IconData icon,
    required String? value,
    required List<DropdownMenuItem<String?>> items,
    required ValueChanged<String?>? onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: DropdownButtonFormField<String?>(
        initialValue: value,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: AppColors.foregroundTertiary, size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          labelStyle: const TextStyle(fontSize: 14, color: AppColors.foregroundTertiary),
        ),
        items: items,
        onChanged: onChanged,
      ),
    );
  }
}
