import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/domain/assessments/entities/assessment.dart';
import 'package:likha/presentation/controllers/teacher/assessment/assessment_edit_controller.dart';
import 'package:likha/presentation/providers/assessment/assessment_detail_notifier.dart';
import 'package:likha/presentation/widgets/mobile/teacher/assessment/assessment_edit_form.dart';

class EditAssessmentPage extends ConsumerStatefulWidget {
  final Assessment assessment;

  const EditAssessmentPage({super.key, required this.assessment});

  @override
  ConsumerState<EditAssessmentPage> createState() => _EditAssessmentPageState();
}

class _EditAssessmentPageState extends ConsumerState<EditAssessmentPage> {
  final _formKey = GlobalKey<FormState>();
  late final AssessmentEditController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AssessmentEditController(
      initial: widget.assessment,
      notifier: ref.read(assessmentDetailProvider.notifier),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(assessmentDetailProvider);

    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: AppColors.backgroundSecondary,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.close_rounded, color: AppColors.foregroundPrimary),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text(
              'Edit Assessment',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.foregroundPrimary,
                letterSpacing: -0.3,
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: TextButton(
                  onPressed: state.isLoading
                      ? null
                      : () async {
                          if (!_formKey.currentState!.validate()) return;
                          final success = await _controller.performSave(
                            widget.assessment.id,
                          );
                          if (!mounted || !success) return;
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (!mounted) return;
                            Navigator.pop(context, true);
                          });
                        },
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.accentCharcoal,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  child: state.isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.accentCharcoal,
                          ),
                        )
                      : const Text(
                          'Save',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: AssessmentEditForm(
              formKey: _formKey,
              titleController: _controller.titleController,
              descriptionController: _controller.descriptionController,
              timeLimitController: _controller.timeLimitController,
              openAt: _controller.openAt,
              closeAt: _controller.closeAt,
              showResultsImmediately: _controller.showResultsImmediately,
              isLoading: state.isLoading,
              formError: _controller.formError,
              onOpenAtChanged: _controller.setOpenAt,
              onCloseAtChanged: _controller.setCloseAt,
              onShowResultsChanged: _controller.setShowResultsImmediately,
              onClearFormError: _controller.clearFormError,
            ),
          ),
        );
      },
    );
  }
}