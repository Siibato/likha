import 'package:flutter/material.dart';
import 'package:likha/presentation/providers/student_tasks_provider.dart';

class TaskCard extends StatelessWidget {
  final String title;
  final String className;
  final DateTime dueAt;
  final int totalPoints;
  final TaskStatus status;
  final int? score;
  final VoidCallback? onTap;
  final TaskType type;
  final DateTime? openAt;
  final DateTime? closeAt;

  // 5-color palette
  static const _kBlack = Color(0xFF1A1A1A);
  static const _kWhite = Colors.white;
  static const _kBlue = Color(0xFF4A90D9);
  static const _kGreen = Color(0xFF4CAF50);
  static const _kRed = Color(0xFFE57373);

  const TaskCard({
    super.key,
    required this.title,
    required this.className,
    required this.dueAt,
    required this.totalPoints,
    required this.status,
    this.score,
    this.onTap,
    this.type = TaskType.assignment,
    this.openAt,
    this.closeAt,
  });

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour > 12 ? dateTime.hour - 12 : (dateTime.hour == 0 ? 12 : dateTime.hour);
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = dateTime.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  String _formatDate(DateTime dateTime) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[dateTime.month - 1]} ${dateTime.day}';
  }

  Color _getStatusColor() {
    switch (status) {
      case TaskStatus.pending:
        return _kBlack;
      case TaskStatus.submitted:
        return _kBlue;
      case TaskStatus.graded:
        return _kGreen;
      case TaskStatus.missing:
        return _kRed;
    }
  }

  String _getStatusLabel() {
    switch (status) {
      case TaskStatus.pending:
        return 'Pending';
      case TaskStatus.submitted:
        return 'Submitted';
      case TaskStatus.graded:
        return 'Graded';
      case TaskStatus.missing:
        return 'Missing';
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor();
    final dueTime = _formatTime(dueAt);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: _kBlack.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        margin: const EdgeInsets.fromLTRB(1, 1, 1, 3.5),
        decoration: BoxDecoration(
          color: _kWhite,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(15),
          child: InkWell(
            borderRadius: BorderRadius.circular(15),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left color bar
                  Container(
                    width: 4,
                    height: 80,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  // Main content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title + Points + Type Chip
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                title,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: _kBlack,
                                  letterSpacing: -0.3,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: _kBlack.withOpacity(0.06),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '${totalPoints}pts',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: _kBlack.withOpacity(0.5),
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: _kBlue.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                type == TaskType.assignment ? 'Assignment' : 'Quiz',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: _kBlue,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        // Class name + Due/Opens time
                        Row(
                          children: [
                            Flexible(
                              fit: FlexFit.loose,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: _kBlack.withOpacity(0.06),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  className,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: _kBlack.withOpacity(0.5),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (type == TaskType.assignment)
                              Expanded(
                                child: Text(
                                  'Due: $dueTime',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: _kBlack.withOpacity(0.4),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              )
                            else
                              Expanded(
                                child: Text(
                                  'Opens: ${_formatDate(openAt!)} · Closes: ${_formatDate(closeAt!)}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: _kBlack.withOpacity(0.4),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Status badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (status == TaskStatus.graded && score != null)
                          Text(
                            '$score/$totalPoints',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: _kWhite,
                              height: 1,
                            ),
                            textAlign: TextAlign.center,
                          )
                        else
                          Text(
                            _getStatusLabel(),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: _kWhite,
                              height: 1,
                            ),
                            textAlign: TextAlign.center,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
