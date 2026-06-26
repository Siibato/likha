import 'package:flutter/material.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/domain/tos/entities/tos_entity.dart';
import 'package:likha/presentation/controllers/teacher/assessment/assessment_create_controller.dart';

const Map<String, String> _difficultyLabels = {
  'easy': 'Easy',
  'medium': 'Average',
  'hard': 'Difficult',
};

const Map<String, String> _bloomsLabels = {
  'remembering': 'Remembering',
  'understanding': 'Understanding',
  'applying': 'Applying',
  'analyzing': 'Analyzing',
  'evaluating': 'Evaluating',
  'creating': 'Creating',
};

/// Displays TOS coverage progress on the assessment create page.
///
/// Shows overall level chips and, when competencies are loaded,
/// an expandable per-competency breakdown.
class TosProgressTracker extends StatefulWidget {
  final TableOfSpecifications tos;
  final TosLevelSummary summary;
  final List<TosCompetency> competencies;

  const TosProgressTracker({
    super.key,
    required this.tos,
    required this.summary,
    this.competencies = const [],
  });

  @override
  State<TosProgressTracker> createState() => _TosProgressTrackerState();
}

class _TosProgressTrackerState extends State<TosProgressTracker> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final isBlooms = widget.tos.classificationMode == 'blooms';
    final labels = isBlooms ? _bloomsLabels : _difficultyLabels;
    final levels = widget.summary.required.keys.toList();
    final fulfilledCount =
        levels.where((k) => widget.summary.remaining[k] == 0).length;
    final hasCompetencies = widget.summary.competencyProgress.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: widget.summary.isComplete
              ? AppColors.semanticSuccess
              : AppColors.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header row ──
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(
                  widget.summary.isComplete
                      ? Icons.check_circle_rounded
                      : Icons.assignment_outlined,
                  size: 16,
                  color: widget.summary.isComplete
                      ? AppColors.semanticSuccess
                      : AppColors.foregroundSecondary,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'TOS Coverage — ${widget.tos.title}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.accentCharcoal,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  '$fulfilledCount / ${levels.length} levels met',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: widget.summary.isComplete
                        ? AppColors.semanticSuccess
                        : AppColors.foregroundSecondary,
                  ),
                ),
              ],
            ),
          ),

          // ── Overall level chips ──
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: levels.map((key) {
                return _LevelChip(
                  label: labels[key] ?? key,
                  added: widget.summary.added[key] ?? 0,
                  required: widget.summary.required[key] ?? 0,
                  remaining: widget.summary.remaining[key] ?? 0,
                );
              }).toList(),
            ),
          ),

          // ── Per-competency section ──
          if (hasCompetencies) ...[
            const Divider(height: 1),
            InkWell(
              onTap: () => setState(() => _expanded = !_expanded),
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(12),
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  children: [
                    Text(
                      'By Competency',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.foregroundSecondary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      _expanded
                          ? Icons.expand_less_rounded
                          : Icons.expand_more_rounded,
                      size: 16,
                      color: AppColors.foregroundSecondary,
                    ),
                  ],
                ),
              ),
            ),
            if (_expanded)
              Padding(
                padding:
                    const EdgeInsets.only(left: 16, right: 16, bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: widget.summary.competencyProgress.map((cp) {
                    return _CompetencyRow(
                      progress: cp,
                      labels: labels,
                    );
                  }).toList(),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _CompetencyRow extends StatelessWidget {
  final TosCompetencyProgress progress;
  final Map<String, String> labels;

  const _CompetencyRow({required this.progress, required this.labels});

  @override
  Widget build(BuildContext context) {
    final levels = progress.required.keys.toList();
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                progress.isComplete
                    ? Icons.check_circle_outline_rounded
                    : Icons.radio_button_unchecked_rounded,
                size: 13,
                color: progress.isComplete
                    ? AppColors.semanticSuccess
                    : AppColors.foregroundTertiary,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  progress.label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: progress.isComplete
                        ? AppColors.semanticSuccess
                        : AppColors.foregroundPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: levels.map((key) {
              return _LevelChip(
                label: labels[key] ?? key,
                added: progress.added[key] ?? 0,
                required: progress.required[key] ?? 0,
                remaining: progress.remaining[key] ?? 0,
                compact: true,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _LevelChip extends StatelessWidget {
  final String label;
  final int added;
  final int required;
  final int remaining;
  final bool compact;

  const _LevelChip({
    required this.label,
    required this.added,
    required this.required,
    required this.remaining,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final bool met = remaining == 0;
    final bool partial = !met && added > 0;

    final Color bgColor;
    final Color borderColor;
    final Color textColor;
    final Color countColor;

    if (met) {
      bgColor = AppColors.semanticSuccessBackground;
      borderColor = AppColors.semanticSuccess;
      textColor = AppColors.semanticSuccess;
      countColor = AppColors.semanticSuccess;
    } else if (partial) {
      bgColor = AppColors.accentAmberSurface;
      borderColor = AppColors.accentAmberBorder;
      textColor = AppColors.foregroundPrimary;
      countColor = AppColors.accentAmberBorder;
    } else {
      bgColor = AppColors.backgroundSecondary;
      borderColor = AppColors.borderLight;
      textColor = AppColors.foregroundSecondary;
      countColor = AppColors.foregroundSecondary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (met)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Icon(
                Icons.check_rounded,
                size: 12,
                color: countColor,
              ),
            ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: textColor,
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: met ? AppColors.semanticSuccess : borderColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$added/$required',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
          if (!met) ...[
            const SizedBox(width: 4),
            Text(
              '($remaining left)',
              style: TextStyle(
                fontSize: 11,
                color: countColor,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
