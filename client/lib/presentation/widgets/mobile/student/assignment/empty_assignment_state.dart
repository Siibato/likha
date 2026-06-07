import 'package:flutter/material.dart';
import 'package:likha/presentation/widgets/shared/feedback/app_empty_state.dart';

class EmptyAssignmentState extends StatelessWidget {
  const EmptyAssignmentState({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppEmptyState.assignments();
  }
}