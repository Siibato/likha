import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/presentation/pages/shared/class_section_header.dart';
import 'package:likha/presentation/pages/student/widgets/task_card.dart';
import 'package:likha/presentation/providers/student_tasks_provider.dart';

class StudentTasksPage extends ConsumerStatefulWidget {
  const StudentTasksPage({super.key});

  @override
  ConsumerState<StudentTasksPage> createState() => _StudentTasksPageState();
}

class _StudentTasksPageState extends ConsumerState<StudentTasksPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(studentTasksProvider.notifier).loadAllTasks(skipBackgroundRefresh: true);
    });
  }

  String _dayLabel(DateTime dueAt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dueDay = DateTime(dueAt.year, dueAt.month, dueAt.day);
    final diff = dueDay.difference(today).inDays;

    if (diff == 0) return 'Today';
    if (diff == 1) return 'Tomorrow';
    if (diff == -1) return 'Yesterday';
    if (diff > 1) return 'in $diff days';
    return '${diff.abs()} days ago';
  }

  String _formatDateHeader(DateTime date) {
    const monthNames = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    const dayNames = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

    final dayName = dayNames[date.weekday - 1];
    final monthName = monthNames[date.month - 1];
    return '$monthName ${date.day}, ${date.year} ($dayName)';
  }

  Map<String, List<TaskItem>> _groupTasksByDate(List<TaskItem> tasks) {
    final grouped = <String, List<TaskItem>>{};
    for (final task in tasks) {
      final dateKey = '${task.dueAt.year}-${task.dueAt.month.toString().padLeft(2, '0')}-${task.dueAt.day.toString().padLeft(2, '0')}';
      grouped.putIfAbsent(dateKey, () => []).add(task);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final taskState = ref.watch(studentTasksProvider);

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ClassSectionHeader(title: 'Tasks'),
          Expanded(
            child: taskState.isLoading && taskState.tasks.isEmpty
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF2B2B2B),
                      strokeWidth: 2.5,
                    ),
                  )
                : taskState.tasks.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(
                              Icons.assignment_outlined,
                              size: 64,
                              color: Color(0xFFCCCCCC),
                            ),
                            SizedBox(height: 16),
                            Text(
                              'No tasks yet',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF2B2B2B),
                              ),
                            ),
                            SizedBox(height: 6),
                            Text(
                              'Check back later',
                              style: TextStyle(
                                fontSize: 14,
                                color: Color(0xFF7A7A7A),
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () =>
                            ref.read(studentTasksProvider.notifier).loadAllTasks(),
                        color: const Color(0xFF2B2B2B),
                        child: CustomScrollView(
                          slivers: [
                            ..._buildDateGroupedTasks(taskState.tasks),
                            const SliverToBoxAdapter(
                              child: SizedBox(height: 24),
                            ),
                          ],
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildDateGroupedTasks(List<TaskItem> tasks) {
    if (tasks.isEmpty) return [];

    final grouped = _groupTasksByDate(tasks);
    final sortedDates = grouped.keys.toList()..sort();

    final widgets = <Widget>[];

    for (final dateKey in sortedDates) {
      final date = DateTime.parse(dateKey);
      final tasksForDate = grouped[dateKey]!;

      // Date header
      widgets.add(
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
            child: Text(
              '${_formatDateHeader(date)} · ${_dayLabel(date)}',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF999999),
                letterSpacing: 0.2,
              ),
            ),
          ),
        ),
      );

      // Tasks for this date
      widgets.add(
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          sliver: SliverList.builder(
            itemCount: tasksForDate.length,
            itemBuilder: (context, index) {
              final task = tasksForDate[index];
              return TaskCard(
                title: task.title,
                className: task.className,
                dueAt: task.dueAt,
                totalPoints: task.totalPoints,
                status: task.status,
                score: task.score,
                onTap: () {
                  // Can add navigation to task detail here if needed
                },
              );
            },
          ),
        ),
      );
    }

    return widgets;
  }
}
