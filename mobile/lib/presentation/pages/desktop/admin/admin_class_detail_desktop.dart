import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/presentation/pages/desktop/core/desktop_page_scaffold.dart';
import 'package:likha/presentation/pages/shared/widgets/cards/info_panel.dart';
import 'package:likha/presentation/pages/shared/widgets/primitives/info_row.dart';
import 'package:likha/presentation/pages/shared/widgets/tokens/app_text_styles.dart';
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
  late TextEditingController _searchController;
  String _searchQuery = '';
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(classProvider.notifier).loadClassDetail(widget.classId);
      ref.read(classProvider.notifier).searchStudents(query: null);
    });

    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      final query = _searchController.text.trim();
      setState(() => _searchQuery = query);

      if (query.isNotEmpty) {
        ref.read(classProvider.notifier).searchStudents(query: query);
      } else {
        ref.read(classProvider.notifier).clearSearch();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final classState = ref.watch(classProvider);
    final detail = classState.currentClassDetail;

    ref.listen<ClassState>(classProvider, (prev, next) {
      if (next.successMessage != null &&
          prev?.successMessage != next.successMessage) {
        ref.read(classProvider.notifier).clearMessages();
      }
      if (next.error != null && prev?.error != next.error) {
        ref.read(classProvider.notifier).clearMessages();
      }
    });

    final classInfo = classState.classes.cast<dynamic>().firstWhere(
          (c) => c?.id == widget.classId,
          orElse: () => null,
        );
    final teacherName = classInfo != null
        ? (classInfo.teacherFullName.isNotEmpty
            ? classInfo.teacherFullName
            : classInfo.teacherUsername)
        : 'Unknown';

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
                  InfoPanel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(detail.title, style: AppTextStyles.cardTitleLg),
                        if (detail.description != null) ...[
                          const SizedBox(height: 8),
                          Text(detail.description!,
                              style: AppTextStyles.cardSubtitleMd),
                        ],
                        const SizedBox(height: 16),
                        InfoRow(label: 'Teacher', value: teacherName),
                        if (classInfo != null &&
                            classInfo.teacherUsername.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          InfoRow(
                            label: 'Username',
                            value: classInfo.teacherUsername,
                          ),
                        ],
                        if (classInfo != null && classInfo.isAdvisory) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF4CAF50)
                                  .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: const Color(0xFF4CAF50)
                                    .withValues(alpha: 0.3),
                              ),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.star_rounded,
                                    size: 16, color: Color(0xFF4CAF50)),
                                SizedBox(width: 4),
                                Text(
                                  'Advisory Class',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF4CAF50),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Student enrollment section
                  const Text(
                    'Student Enrollment',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.foregroundDark,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Search bar
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.borderLight),
                    ),
                    child: Row(
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(left: 12),
                          child: Icon(
                            Icons.search_rounded,
                            color: AppColors.foregroundTertiary,
                            size: 20,
                          ),
                        ),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            decoration: const InputDecoration(
                              hintText: 'Search students...',
                              hintStyle: TextStyle(
                                color: AppColors.foregroundTertiary,
                                fontSize: 14,
                              ),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 14),
                            ),
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.foregroundPrimary,
                            ),
                          ),
                        ),
                        if (_searchQuery.isNotEmpty)
                          IconButton(
                            icon: const Icon(Icons.clear_rounded,
                                size: 20, color: AppColors.foregroundTertiary),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                              ref
                                  .read(classProvider.notifier)
                                  .clearSearch();
                            },
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Students count
                  Text(
                    _searchQuery.isEmpty
                        ? 'All Students (${classState.searchResults.length})'
                        : 'Search Results (${classState.searchResults.length})',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.foregroundSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Student list
                  if (classState.isLoading &&
                      classState.searchResults.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: CircularProgressIndicator(
                          color: AppColors.foregroundPrimary,
                          strokeWidth: 2.5,
                        ),
                      ),
                    )
                  else if (classState.searchResults.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          children: [
                            Icon(
                              _searchQuery.isEmpty
                                  ? Icons.person_outline_rounded
                                  : Icons.person_search_rounded,
                              size: 48,
                              color: AppColors.borderLight,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _searchQuery.isEmpty
                                  ? 'No students available'
                                  : 'No students found',
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppColors.foregroundTertiary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.borderLight),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: DataTable(
                          headingRowColor: WidgetStateProperty.all(
                              AppColors.backgroundTertiary),
                          dataRowMaxHeight: 56,
                          horizontalMargin: 20,
                          columnSpacing: 24,
                          columns: const [
                            DataColumn(
                              label: Text('Student',
                                  style: _headerStyle),
                            ),
                            DataColumn(
                              label: Text('Username',
                                  style: _headerStyle),
                            ),
                            DataColumn(
                              label:
                                  Text('Status', style: _headerStyle),
                            ),
                            DataColumn(
                              label:
                                  Text('Action', style: _headerStyle),
                            ),
                          ],
                          rows: classState.searchResults.map((student) {
                            final isParticipant = classState.participantIds
                                .contains(student.id);
                            final isStudentLoading = classState
                                .loadingStudentIds
                                .contains(student.id);

                            return DataRow(cells: [
                              DataCell(
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 32,
                                      height: 32,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: AppColors.backgroundTertiary,
                                        borderRadius:
                                            BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        student.fullName.isNotEmpty
                                            ? student.fullName[0]
                                                .toUpperCase()
                                            : '?',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color:
                                              AppColors.foregroundPrimary,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      student.fullName,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.foregroundDark,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              DataCell(Text(
                                student.username,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: AppColors.foregroundSecondary,
                                ),
                              )),
                              DataCell(
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isParticipant
                                        ? const Color(0xFF28A745)
                                            .withValues(alpha: 0.12)
                                        : AppColors.foregroundTertiary
                                            .withValues(alpha: 0.12),
                                    borderRadius:
                                        BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    isParticipant
                                        ? 'Enrolled'
                                        : 'Not enrolled',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: isParticipant
                                          ? const Color(0xFF28A745)
                                          : AppColors.foregroundTertiary,
                                    ),
                                  ),
                                ),
                              ),
                              DataCell(
                                isStudentLoading
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child:
                                            CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color:
                                              AppColors.foregroundPrimary,
                                        ),
                                      )
                                    : isParticipant
                                        ? IconButton(
                                            icon: const Icon(
                                              Icons
                                                  .remove_circle_outline_rounded,
                                              color: Color(0xFFDC3545),
                                              size: 20,
                                            ),
                                            tooltip: 'Remove student',
                                            onPressed: () {
                                              ref
                                                  .read(classProvider
                                                      .notifier)
                                                  .removeStudent(
                                                    classId:
                                                        widget.classId,
                                                    studentId:
                                                        student.id,
                                                  );
                                            },
                                          )
                                        : IconButton(
                                            icon: const Icon(
                                              Icons
                                                  .add_circle_outline_rounded,
                                              color: Color(0xFF28A745),
                                              size: 20,
                                            ),
                                            tooltip: 'Add student',
                                            onPressed: () {
                                              ref
                                                  .read(classProvider
                                                      .notifier)
                                                  .addStudent(
                                                    classId:
                                                        widget.classId,
                                                    studentId:
                                                        student.id,
                                                  );
                                            },
                                          ),
                              ),
                            ]);
                          }).toList(),
                        ),
                      ),
                    ),
                ],
              ),
      ),
    );
  }

  static const _headerStyle = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w700,
    color: AppColors.foregroundSecondary,
  );
}
