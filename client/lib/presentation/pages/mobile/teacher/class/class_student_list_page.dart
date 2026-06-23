import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/presentation/layouts/mobile/mobile_page_scaffold.dart';
import 'package:likha/domain/classes/entities/class_detail.dart';
import 'package:likha/domain/auth/entities/user.dart';
import 'package:likha/presentation/widgets/mobile/teacher/class/empty_student_state.dart';
import 'package:likha/presentation/pages/mobile/teacher/class/student_detail_page.dart';
import 'package:likha/presentation/providers/class_provider.dart';

class ClassStudentListPage extends ConsumerStatefulWidget {
  final String classId;

  const ClassStudentListPage({super.key, required this.classId});

  @override
  ConsumerState<ClassStudentListPage> createState() => _ClassStudentListPageState();
}

class _ClassStudentListPageState extends ConsumerState<ClassStudentListPage> {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Load class detail to get enrolled students
      ref.read(classDetailProvider.notifier).loadClassDetail(widget.classId);
      // Cache-first + background refresh for participants
      ref.read(classDetailProvider.notifier).loadParticipants(widget.classId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final classDetailState = ref.watch(classDetailProvider);
    final currentClassDetail = classDetailState.currentClassDetail;

    ref.listen<ClassDetailState>(classDetailProvider, (prev, next) {
      // Offline fallback: if no cached detail and error occurred, load from local DB
      if (currentClassDetail == null &&
          next.error != null &&
          prev?.error != next.error) {
        ref.read(classDetailProvider.notifier).loadParticipants(widget.classId);
      }
      // Show error messages
      if (next.error != null && prev?.error != next.error) {
        ref.read(classDetailProvider.notifier).clearMessages();
      }
    });

    // Determine which student list to show
    final rawStudents = currentClassDetail != null
        ? currentClassDetail.students // Online: from API
        : classDetailState.participants; // Offline: from local DB

    // Sort by last name, then first name
    final students = List<dynamic>.from(rawStudents)
      ..sort((a, b) {
        final userA = a is Participant ? a.student : a as User;
        final userB = b is Participant ? b.student : b as User;
        final lastCmp = userA.lastName.toLowerCase().compareTo(
            userB.lastName.toLowerCase());
        if (lastCmp != 0) return lastCmp;
        return userA.firstName.toLowerCase().compareTo(
            userB.firstName.toLowerCase());
      });

    return MobilePageScaffold(
      title: 'Students',
      isLoading: classDetailState.isLoading && students.isEmpty,
      body: students.isEmpty
          ? const EmptyStudentState()
          : ListView.builder(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            itemCount: students.length,
            itemBuilder: (context, index) {
              final item = students[index];
              // Handle both Participant (from API) and User (from offline)
              final user = item is Participant ? item.student : item as User;

              return Container(
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: AppColors.borderLight,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Container(
                  margin: const EdgeInsets.fromLTRB(1, 1, 1, 3.5),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(15),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(15),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => TeacherStudentDetailPage(
                            student: user,
                            classId: widget.classId,
                            classTitle: currentClassDetail?.title ?? 'Class',
                          ),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            // Avatar
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.backgroundTertiary,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                user.fullName.isNotEmpty
                                    ? user.fullName[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.accentCharcoal,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            // Student info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    user.fullName,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.foregroundDark,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '@${user.username}',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: AppColors.foregroundTertiary,
                                    ),
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
            },
          ),
    );
  }
}