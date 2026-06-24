import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/presentation/controllers/teacher/assessment/assessment_detail_controller.dart';
import 'package:likha/presentation/providers/assessment/assessment_detail_notifier.dart';
import 'package:likha/presentation/widgets/mobile/teacher/assessment/assessment_detail_delete_section.dart';
import 'package:likha/presentation/widgets/mobile/teacher/assessment/assessment_detail_grading_section.dart';
import 'package:likha/presentation/widgets/mobile/teacher/assessment/assessment_detail_info_section.dart';
import 'package:likha/presentation/widgets/mobile/teacher/assessment/assessment_detail_questions_section.dart';
import 'package:likha/presentation/widgets/shared/feedback/provider_message_listener.dart';
import 'package:likha/presentation/widgets/shared/forms/form_message.dart';

class AssessmentDetailPage extends ConsumerStatefulWidget {
  final String assessmentId;

  const AssessmentDetailPage({super.key, required this.assessmentId});

  @override
  ConsumerState<AssessmentDetailPage> createState() =>
      _AssessmentDetailPageState();
}

class _AssessmentDetailPageState extends ConsumerState<AssessmentDetailPage>
    with TickerProviderStateMixin {
  late final AssessmentDetailController _controller;
  late AnimationController _questionAnimController;

  @override
  void initState() {
    super.initState();
    _controller = AssessmentDetailController(
      assessmentId: widget.assessmentId,
      notifier: ref.read(assessmentDetailProvider.notifier),
    );
    _questionAnimController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(assessmentDetailProvider.notifier)
          .loadAssessmentDetail(widget.assessmentId);
    });
  }

  @override
  void dispose() {
    _questionAnimController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final assessmentState = ref.watch(assessmentDetailProvider);
    final assessment = assessmentState.currentAssessment;
    final questions = assessmentState.questions;

    return ProviderMessageListener<AssessmentDetailState>(
      provider: assessmentDetailProvider,
      successMessage: (s) => s.successMessage,
      errorMessage: (s) => s.error,
      onClear: () =>
          ref.read(assessmentDetailProvider.notifier).clearMessages(),
      intercept: (prev, next) {
        if (next.successMessage == 'Assessment deleted') {
          Navigator.pop(context, true);
          return true;
        }
        return false;
      },
      child: Scaffold(
        backgroundColor: AppColors.backgroundSecondary,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: const IconThemeData(color: AppColors.foregroundPrimary),
          title: Text(
            assessment?.title ?? 'Assessment Detail',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.foregroundPrimary,
              letterSpacing: -0.4,
            ),
          ),
          actions: const [],
        ),
        body: assessmentState.isLoading && assessment == null
            ? const Center(
                child: CircularProgressIndicator(
                  color: AppColors.accentCharcoal,
                  strokeWidth: 2.5,
                ),
              )
            : assessment == null
                ? const Center(
                    child: Text(
                      'Assessment not found',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.foregroundTertiary,
                      ),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: () => ref
                        .read(assessmentDetailProvider.notifier)
                        .loadAssessmentDetail(widget.assessmentId),
                    color: AppColors.accentCharcoal,
                    child: ListenableBuilder(
                      listenable: _controller,
                      builder: (context, _) {
                        return SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              FormMessage(
                                message: _controller.formError,
                                severity: MessageSeverity.error,
                              ),
                              if (_controller.formError != null)
                                const SizedBox(height: 12),
                              AssessmentDetailInfoSection(
                                assessment: assessment,
                                assessmentId: widget.assessmentId,
                              ),
                              const SizedBox(height: 16),
                              AssessmentDetailGradingSection(
                                assessment: assessment,
                                controller: _controller,
                              ),
                              const SizedBox(height: 16),
                              AssessmentDetailQuestionsSection(
                                assessment: assessment,
                                questions: questions,
                                controller: _controller,
                                questionAnimController: _questionAnimController,
                                assessmentId: widget.assessmentId,
                              ),
                              const SizedBox(height: 24),
                              AssessmentDetailDeleteSection(
                                assessment: assessment,
                                assessmentId: widget.assessmentId,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
      ),
    );
  }
}
