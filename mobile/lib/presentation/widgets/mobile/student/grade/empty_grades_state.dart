import 'package:flutter/material.dart';
import 'package:likha/presentation/widgets/shared/feedback/app_empty_state.dart';

class EmptyGradesState extends StatelessWidget {
  const EmptyGradesState({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppEmptyState.grades();
  }
}
