import 'package:flutter/material.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/presentation/controllers/student/assignment/assignment_detail_controller.dart';
import 'package:likha/presentation/providers/assignment_provider.dart';
import 'package:likha/presentation/widgets/mobile/student/assignment/assignment_detail_body.dart';
import 'package:likha/presentation/widgets/shared/dialogs/app_dialogs.dart';

class AssignmentDetailPage extends ConsumerStatefulWidget {
  final String assignmentId;
  final String assignmentTitle;
  final String instructions;
  final bool allowsTextSubmission;
  final bool allowsFileSubmission;
  final int totalPoints;
  final String? allowedFileTypes;
  final int? maxFileSizeMb;
  final String? submissionId;
  final int? score;
  final String? submissionStatus;
  final DateTime dueAt;
  final bool isNewAttempt;

  const AssignmentDetailPage({
    super.key,
    required this.assignmentId,
    required this.assignmentTitle,
    required this.instructions,
    required this.allowsTextSubmission,
    required this.allowsFileSubmission,
    required this.totalPoints,
    this.allowedFileTypes,
    this.maxFileSizeMb,
    this.submissionId,
    this.score,
    this.submissionStatus,
    required this.dueAt,
    this.isNewAttempt = false,
  });

  @override
  ConsumerState<AssignmentDetailPage> createState() =>
      _AssignmentDetailPageState();
}

class _AssignmentDetailPageState extends ConsumerState<AssignmentDetailPage> {
  late final AssignmentDetailController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AssignmentDetailController(
      assignmentId: widget.assignmentId,
      allowsTextSubmission: widget.allowsTextSubmission,
      allowsFileSubmission: widget.allowsFileSubmission,
      allowedFileTypes: widget.allowedFileTypes,
      maxFileSizeMb: widget.maxFileSizeMb,
      initialSubmissionId: widget.submissionId,
      initialSubmissionStatus: widget.submissionStatus,
      isNewAttempt: widget.isNewAttempt,
      notifier: ref.read(assignmentProvider.notifier),
    );
    _controller.init();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<bool> _confirmDiscard() async {
    if (!_controller.hasUnsavedContent) return true;
    bool shouldDiscard = false;
    await AppDialogs.showConfirmation(
      context: context,
      title: 'Discard new attempt?',
      body: 'Your changes will not be saved.',
      confirmLabel: 'Discard',
      onConfirm: () => shouldDiscard = true,
    );
    return shouldDiscard;
  }

  void _openNewAttempt() {
    Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AssignmentDetailPage(
          assignmentId: widget.assignmentId,
          assignmentTitle: widget.assignmentTitle,
          instructions: widget.instructions,
          allowsTextSubmission: widget.allowsTextSubmission,
          allowsFileSubmission: widget.allowsFileSubmission,
          totalPoints: widget.totalPoints,
          allowedFileTypes: widget.allowedFileTypes,
          maxFileSizeMb: widget.maxFileSizeMb,
          submissionId: null,
          score: null,
          submissionStatus: null,
          dueAt: widget.dueAt,
          isNewAttempt: true,
        ),
      ),
    ).then((submitted) {
      if (submitted == true && mounted) {
        Navigator.pop(context, true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !widget.isNewAttempt,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final nav = Navigator.of(context);
        final ok = await _confirmDiscard();
        if (ok) nav.pop(false);
      },
      child: Scaffold(
        backgroundColor: AppColors.backgroundSecondary,
        body: SafeArea(
          child: AssignmentDetailBody(
            controller: _controller,
            assignmentId: widget.assignmentId,
            assignmentTitle: widget.assignmentTitle,
            instructions: widget.instructions,
            totalPoints: widget.totalPoints,
            dueAt: widget.dueAt,
            isNewAttempt: widget.isNewAttempt,
            submissionStatus: widget.submissionStatus,
            score: widget.score,
            onNewAttempt: _openNewAttempt,
          ),
        ),
      ),
    );
  }
}
