import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/presentation/pages/desktop/core/desktop_page_scaffold.dart';
import 'package:likha/presentation/providers/class_provider.dart';

class AdminManageEnrollmentDesktop extends ConsumerStatefulWidget {
  final String classId;
  final String classTitle;

  const AdminManageEnrollmentDesktop({
    super.key,
    required this.classId,
    required this.classTitle,
  });

  @override
  ConsumerState<AdminManageEnrollmentDesktop> createState() =>
      _AdminManageEnrollmentDesktopState();
}

class _AdminManageEnrollmentDesktopState
    extends ConsumerState<AdminManageEnrollmentDesktop> {
  late TextEditingController _searchController;
  String _searchQuery = '';
  Timer? _debounce;
  int _currentPage = 0;
  static const int _pageSize = 10;

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
      setState(() {
        _searchQuery = query;
        _currentPage = 0;
      });

      if (query.isNotEmpty) {
        ref.read(classProvider.notifier).searchStudents(query: query);
      } else {
        ref.read(classProvider.notifier).searchStudents(query: null);
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

    ref.listen<ClassState>(classProvider, (prev, next) {
      if (next.successMessage != null &&
          prev?.successMessage != next.successMessage) {
        ref.read(classProvider.notifier).clearMessages();
      }
      if (next.error != null && prev?.error != next.error) {
        ref.read(classProvider.notifier).clearMessages();
      }
    });

    return Scaffold(
      backgroundColor: AppColors.backgroundSecondary,
      body: DesktopPageScaffold(
        title: 'Manage Enrollment',
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          color: AppColors.foregroundPrimary,
          onPressed: () => Navigator.pop(context),
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Class name context
            Text(
              widget.classTitle,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.foregroundSecondary,
              ),
            ),
            const SizedBox(height: 20),

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
                            .searchStudents(query: null);
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
            if (classState.isLoading && classState.searchResults.isEmpty)
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
              ..._buildPaginatedTable(classState),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildPaginatedTable(ClassState classState) {
    final allResults = classState.searchResults;
    final totalPages = (allResults.length / _pageSize).ceil();
    if (_currentPage >= totalPages && totalPages > 0) {
      _currentPage = totalPages - 1;
    }
    final start = _currentPage * _pageSize;
    final end = (start + _pageSize).clamp(0, allResults.length);
    final pageResults = allResults.sublist(start, end);

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
                        child: Text('Status', style: _headerStyle)),
                    SizedBox(
                      width: 80,
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Text('Action', style: _headerStyle),
                      ),
                    ),
                  ],
                ),
              ),
              // Data rows
              ...pageResults.asMap().entries.map((entry) {
                final index = entry.key;
                final student = entry.value;
                final isParticipant =
                    classState.participantIds.contains(student.id);
                final isStudentLoading =
                    classState.loadingStudentIds.contains(student.id);

                return Column(
                  children: [
                    if (index > 0)
                      const Divider(height: 1, color: AppColors.borderLight),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      child: Row(
                        children: [
                          // Student (expanded)
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
                          // Status (fixed)
                          SizedBox(
                            width: 120,
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Container(
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
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  isParticipant ? 'Enrolled' : 'Not enrolled',
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
                          ),
                          // Action (fixed, right-aligned)
                          SizedBox(
                            width: 80,
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: isStudentLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppColors.foregroundPrimary,
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
                                                .read(classProvider.notifier)
                                                .removeStudent(
                                                  classId: widget.classId,
                                                  studentId: student.id,
                                                );
                                          },
                                        )
                                      : IconButton(
                                          icon: const Icon(
                                            Icons.add_circle_outline_rounded,
                                            color: Color(0xFF28A745),
                                            size: 20,
                                          ),
                                          tooltip: 'Add student',
                                          onPressed: () {
                                            ref
                                                .read(classProvider.notifier)
                                                .addStudent(
                                                  classId: widget.classId,
                                                  studentId: student.id,
                                                );
                                          },
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
              'Showing ${start + 1}-$end of ${allResults.length} students',
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
