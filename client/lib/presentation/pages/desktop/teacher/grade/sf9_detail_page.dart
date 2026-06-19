import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/presentation/layouts/desktop/desktop_page_scaffold.dart';
import 'package:likha/presentation/widgets/shared/cards/info_panel.dart';
import 'package:likha/presentation/widgets/shared/primitives/info_row.dart';
import 'package:likha/domain/grading/entities/sf9.dart';
import 'package:likha/presentation/widgets/mobile/teacher/grade/sf9_grade_table.dart';
import 'package:likha/presentation/providers/sf9_provider.dart';
import 'package:likha/core/network/server_reachability_service.dart';
import 'package:likha/injection_container.dart';
import 'package:likha/presentation/providers/document_export_provider.dart';
import 'package:likha/presentation/widgets/desktop/teacher/grade/sf9_core_values_table.dart';

class Sf9DetailPage extends ConsumerStatefulWidget {
  final String classId;
  final String studentId;
  final String studentName;

  const Sf9DetailPage({
    super.key,
    required this.classId,
    required this.studentId,
    required this.studentName,
  });

  @override
  ConsumerState<Sf9DetailPage> createState() => _Sf9DetailPageState();
}

class _Sf9DetailPageState extends ConsumerState<Sf9DetailPage> {
  bool _isDownloading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(sf9DetailProvider.notifier)
          .loadSf9(widget.classId, widget.studentId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(sf9DetailProvider);
    final sf9 = state.currentSf9;
    final displaySf9 = sf9 != null && sf9.studentName == 'Unknown Student'
        ? Sf9Response(
            studentId: sf9.studentId,
            studentName: widget.studentName,
            gradeLevel: sf9.gradeLevel,
            schoolYear: sf9.schoolYear,
            section: sf9.section,
            lrn: sf9.lrn,
            age: sf9.age,
            sex: sf9.sex,
            trackStrand: sf9.trackStrand,
            curriculum: sf9.curriculum,
            subjects: sf9.subjects,
            generalAverage: sf9.generalAverage,
          )
        : sf9;

    return Scaffold(
      backgroundColor: AppColors.backgroundSecondary,
      body: DesktopPageScaffold(
        title: 'SF9: ${widget.studentName}',
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          color: AppColors.foregroundPrimary,
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (displaySf9 != null)
            TextButton.icon(
              onPressed: _isDownloading ? null : () => _downloadSf9(displaySf9),
              icon: _isDownloading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.download_rounded, size: 18),
              label: Text(_isDownloading ? 'Generating...' : 'Download SF9'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: AppColors.accentCharcoal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
        ],
        body: _buildBody(state, displaySf9),
      ),
    );
  }

  Widget _buildBody(Sf9DetailState state, Sf9Response? displaySf9) {
    if (state.isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppColors.foregroundPrimary,
          strokeWidth: 2.5,
        ),
      );
    }

    if (state.error != null) {
      return Center(
        child: Text(
          state.error!,
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.semanticError,
          ),
        ),
      );
    }

    if (displaySf9 == null) {
      return const Center(
        child: Text(
          'No SF9 data available.',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.foregroundSecondary,
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Student info card
          InfoPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                InfoRow(label: 'Name', value: displaySf9.studentName),
                if (displaySf9.lrn != null) ...[
                  const SizedBox(height: 12),
                  InfoRow(label: 'LRN', value: displaySf9.lrn!),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: InfoRow(label: 'Age', value: displaySf9.age?.toString() ?? '—'),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: InfoRow(label: 'Sex', value: displaySf9.sex ?? '—'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: InfoRow(label: 'Grade Level', value: displaySf9.gradeLevel ?? '—'),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: InfoRow(label: 'Section', value: displaySf9.section ?? '—'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: InfoRow(label: 'School Year', value: displaySf9.schoolYear ?? '—'),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: InfoRow(label: 'Curriculum', value: displaySf9.curriculum ?? '—'),
                    ),
                  ],
                ),
                if (displaySf9.trackStrand != null) ...[
                  const SizedBox(height: 12),
                  InfoRow(label: 'Track/Strand', value: displaySf9.trackStrand!),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Grade table
          const Text(
            'Report on Learning Progress and Achievement',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.foregroundPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Sf9GradeTable(
            subjects: displaySf9.subjects,
            generalAverage: displaySf9.generalAverage,
          ),
          const SizedBox(height: 24),
          // Core values table
          const Sf9CoreValuesTable(),
        ],
      ),
    );
  }

  Future<void> _downloadSf9(Sf9Response displaySf9) async {
    final reachability = sl<ServerReachabilityService>();
    if (!reachability.isServerReachable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Only available when connected to Likha server'),
          backgroundColor: AppColors.semanticError,
        ),
      );
      return;
    }

    setState(() => _isDownloading = true);

    await ref.read(documentExportProvider.notifier).exportSf9(
      classId: widget.classId,
      studentId: widget.studentId,
      studentName: widget.studentName,
    );

    if (!mounted) return;

    final exportState = ref.read(documentExportProvider);

    if (exportState.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(exportState.error!),
          backgroundColor: AppColors.semanticError,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('SF9 PDF downloaded successfully'),
          backgroundColor: AppColors.semanticSuccess,
        ),
      );
    }

    setState(() => _isDownloading = false);
  }
}
