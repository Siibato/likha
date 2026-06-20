import 'package:flutter/material.dart';
import 'package:likha/domain/assessments/entities/assessment.dart';
import 'package:likha/presentation/controllers/teacher/assessment/assessment_detail_controller.dart';
import 'package:likha/presentation/widgets/mobile/teacher/assessment/grading_settings_card.dart';

class AssessmentDetailGradingSection extends StatelessWidget {
  final Assessment assessment;
  final AssessmentDetailController controller;

  const AssessmentDetailGradingSection({
    super.key,
    required this.assessment,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return GradingSettingsCard(
      termNumber: assessment.termNumber,
      component: assessment.component,
      isEditing: controller.isEditingGrading,
      editingGradingPeriod: controller.editingGradingPeriod,
      editingComponent: controller.editingComponent,
      onEdit: () => controller.startEditingGrading(assessment),
      onSave: (period, component) => controller.saveGradingSettings(),
      onCancel: controller.cancelEditingGrading,
      onPeriodChanged: controller.setEditingGradingPeriod,
      onComponentChanged: controller.setEditingComponent,
    );
  }
}
