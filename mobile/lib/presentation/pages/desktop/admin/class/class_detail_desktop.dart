import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/domain/classes/entities/class_detail.dart';
import 'package:likha/presentation/pages/desktop/admin/class/edit_class_desktop.dart';
import 'package:likha/presentation/pages/desktop/admin/class/manage_enrollment_desktop.dart';
import 'package:likha/presentation/pages/desktop/admin/class/widgets/class_info_panel.dart';
import 'package:likha/presentation/pages/desktop/core/desktop_page_scaffold.dart';
import 'package:likha/presentation/providers/class_provider.dart';

class AdminClassDetailDesktop extends ConsumerStatefulWidget {
  final String classId;

  const AdminClassDetailDesktop({super.key, required this.classId});

  @override
  ConsumerState<AdminClassDetailDesktop> createState() =>
      _AdminClassDetailDesktopState();
}

class _AdminClassDetailDesktopState
    extends ConsumerState<AdminClassDetailDesktop> {
  int _currentPage = 0;
  static const int _pageSize = 10;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(classProvider.notifier).loadClassDetail(widget.classId);
    });
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final classState = ref.watch(classProvider);
    final detail = classState.currentClassDetail;

    final classInfo = classState.classes.cast<dynamic>().firstWhere(
          (c) => c?.id == widget.classId,
          orElse: () => null,
        );
    final teacherName = classInfo != null
        ? (classInfo.teacherFullName.isNotEmpty
            ? classInfo.teacherFullName
            : classInfo.teacherUsername)
        : 'Unknown';

    final isAdvisory =
        detail?.isAdvisory == true || (classInfo?.isAdvisory == true);

    return Scaffold(
      backgroundColor: AppColors.backgroundSecondary,
      body: DesktopPageScaffold(
        title: detail?.title ?? 'Class Detail',
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          color: AppColors.foregroundPrimary,
          onPressed: () => Navigator.pop(context),
        ),
        body: detail == null
            ? const Center(
                child: CircularProgressIndicator(
                  color: AppColors.foregroundPrimary,
                  strokeWidth: 2.5,
                ),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Class Info Panel
                  ClassInfoPanel.withClassInfo(
                    detail: detail,
                    classInfo: classInfo!,
                    onEdit: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AdminEditClassDesktop(
                          classEntity: classInfo!,
                        ),
                      ),
                    ).then((_) {
                      ref.read(classProvider.notifier).loadAllClasses();
                      ref
                          .read(classProvider.notifier)
                          .loadClassDetail(widget.classId);
                    }),
                  ),

                  const SizedBox(height: 32),

                  // Student list header with Manage Enrollment button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Students (${detail.students.length})',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.foregroundDark,
                          letterSpacing: -0.4,
                        ),
                      ),
                      FilledButton.icon(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AdminManageEnrollmentDesktop(
                              classId: widget.classId,
                              classTitle: detail.title,
                            ),
                          ),
                        ).then((_) {
                          ref
                              .read(classProvider.notifier)
                              .loadClassDetail(widget.classId);
                        }),
                        icon: const Icon(Icons.group_add_rounded, size: 18),
                        label: const Text('Manage Enrollment'),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.foregroundDark,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 12),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Read-only student list
                  if (detail.students.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.person_outline_rounded,
                              size: 48,
                              color: AppColors.borderLight,
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'No students enrolled',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.foregroundTertiary,
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextButton(
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      AdminManageEnrollmentDesktop(
                                    classId: widget.classId,
                                    classTitle: detail.title,
                                  ),
                                ),
                              ).then((_) {
                                ref
                                    .read(classProvider.notifier)
                                    .loadClassDetail(widget.classId);
                              }),
                              child: const Text('Add students'),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ..._buildStudentTable(detail.students),
                ],
              ),
      ),
    );
  }

  List<Widget> _buildStudentTable(List<Participant> students) {
    final totalPages = (students.length / _pageSize).ceil();
    if (_currentPage >= totalPages && totalPages > 0) {
      _currentPage = totalPages - 1;
    }
    final start = _currentPage * _pageSize;
    final end = (start + _pageSize).clamp(0, students.length);
    final pageStudents = students.sublist(start, end);

    return [
      Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Column(
            children: [
              // Header row
              Container(
                color: AppColors.backgroundTertiary,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                child: Row(
                  children: [
                    Expanded(
                        child: Text('Student', style: _headerStyle)),
                    SizedBox(
                        width: 150,
                        child: Text('Username', style: _headerStyle)),
                    SizedBox(
                        width: 120,
                        child: Text('Joined', style: _headerStyle)),
                  ],
                ),
              ),
              // Data rows
              ...pageStudents.asMap().entries.map((entry) {
                final index = entry.key;
                final participant = entry.value;
                final student = participant.student;

                return Column(
                  children: [
                    if (index > 0)
                      const Divider(height: 1, color: AppColors.borderLight),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      child: Row(
                        children: [
                          // Student name (expanded)
                          Expanded(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: AppColors.backgroundTertiary,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    student.fullName.isNotEmpty
                                        ? student.fullName[0].toUpperCase()
                                        : '?',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.foregroundPrimary,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Flexible(
                                  child: Text(
                                    student.fullName,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.foregroundDark,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Username (fixed)
                          SizedBox(
                            width: 150,
                            child: Text(
                              student.username,
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppColors.foregroundSecondary,
                              ),
                            ),
                          ),
                          // Joined date (fixed)
                          SizedBox(
                            width: 120,
                            child: Text(
                              _formatDate(participant.joinedAt),
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppColors.foregroundTertiary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }),
            ],
          ),
        ),
      ),
      if (totalPages > 1) ...[
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Showing ${start + 1}-$end of ${students.length} students',
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.foregroundTertiary,
              ),
            ),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left_rounded, size: 24),
                  color: _currentPage > 0
                      ? AppColors.foregroundPrimary
                      : AppColors.borderLight,
                  onPressed: _currentPage > 0
                      ? () => setState(() => _currentPage--)
                      : null,
                ),
                ...List.generate(totalPages, (index) {
                  final isActive = index == _currentPage;
                  return GestureDetector(
                    onTap: () => setState(() => _currentPage = index),
                    child: Container(
                      width: 32,
                      height: 32,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isActive
                            ? AppColors.foregroundPrimary
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isActive
                              ? Colors.white
                              : AppColors.foregroundSecondary,
                        ),
                      ),
                    ),
                  );
                }),
                IconButton(
                  icon: const Icon(Icons.chevron_right_rounded, size: 24),
                  color: _currentPage < totalPages - 1
                      ? AppColors.foregroundPrimary
                      : AppColors.borderLight,
                  onPressed: _currentPage < totalPages - 1
                      ? () => setState(() => _currentPage++)
                      : null,
                ),
              ],
            ),
          ],
        ),
      ],
    ];
  }

  static const _headerStyle = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w700,
    color: AppColors.foregroundSecondary,
  );
}
