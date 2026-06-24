import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/domain/assessments/entities/assessment.dart';
import 'package:likha/presentation/controllers/teacher/assessment/assessment_edit_controller.dart';
import 'package:likha/presentation/layouts/desktop/desktop_page_scaffold.dart';
import 'package:likha/presentation/providers/assessment/assessment_detail_notifier.dart';
import 'package:likha/presentation/widgets/desktop/teacher/assessment/assessment_edit_form.dart';

class EditAssessmentPage extends ConsumerStatefulWidget {
  final Assessment assessment;

  const EditAssessmentPage({super.key, required this.assessment});

  @override
  ConsumerState<EditAssessmentPage> createState() =>
      _EditAssessmentPageState();
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

    return Scaffold(
      backgroundColor: AppColors.backgroundSecondary,
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          return DesktopPageScaffold(
            title: 'Edit Assessment',
            maxWidth: 600,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded,
                  color: AppColors.foregroundPrimary),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              FilledButton.icon(
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
                icon: state.isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.save_rounded, size: 18),
                label: const Text('Save'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.foregroundPrimary,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              ),
            ],
            body: AssessmentEditForm(
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
          );
        },
      ),
    );
  }
}
