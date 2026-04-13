import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/presentation/providers/class_provider.dart';
import 'search_filter_bar.dart';
import 'empty_state.dart';
import '../utils/date_utils.dart';

/// A reusable enrollment management section widget
/// that handles student search, display, and enrollment actions.
class EnrollmentSection extends ConsumerStatefulWidget {
  final String classId;
  final String classTitle;
  final ValueChanged<String>? onStudentSelected;
  final VoidCallback? onRefresh;

  const EnrollmentSection({
    super.key,
    required this.classId,
    required this.classTitle,
    this.onStudentSelected,
    this.onRefresh,
  });

  @override
  ConsumerState<EnrollmentSection> createState() => _EnrollmentSectionState();
}

class _EnrollmentSectionState extends ConsumerState<EnrollmentSection> {
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

  void _handleEnrollToggle(String studentId, bool isEnrolled) {
    if (isEnrolled) {
      ref.read(classProvider.notifier).removeStudent(classId: widget.classId, studentId: studentId);
    } else {
      ref.read(classProvider.notifier).addStudent(classId: widget.classId, studentId: studentId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final classState = ref.watch(classProvider);

    ref.listen<ClassState>(classProvider, (prev, next) {
      if (next.successMessage != null && prev?.successMessage != next.successMessage) {
        ref.read(classProvider.notifier).clearMessages();
      }
      if (next.error != null && prev?.error != next.error) {
        ref.read(classProvider.notifier).clearMessages();
      }
    });

    return Column(
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
        CompactSearchBar(
          controller: _searchController,
          hint: 'Search students...',
          onChanged: (value) {
            // Handled by listener
          },
          onClear: () {
            _searchController.clear();
            setState(() => _searchQuery = '');
            ref.read(classProvider.notifier).searchStudents(query: null);
          },
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
          const LoadingState(message: 'Loading students...')
        else if (classState.searchResults.isEmpty)
          EmptyState.generic(
            title: _searchQuery.isEmpty ? 'No students available' : 'No students found',
            subtitle: _searchQuery.isEmpty 
                ? 'There are no students in the system' 
                : 'Try adjusting your search terms',
            icon: _searchQuery.isEmpty 
                ? Icons.people_outline_rounded 
                : Icons.person_search_rounded,
          )
        else
          _buildStudentTable(classState),
      ],
    );
  }

  Widget _buildStudentTable(ClassState classState) {
    final allResults = classState.searchResults;
    final totalPages = (allResults.length / _pageSize).ceil();
    if (_currentPage >= totalPages && totalPages > 0) {
      _currentPage = totalPages - 1;
    }
    final start = _currentPage * _pageSize;
    final end = (start + _pageSize).clamp(0, allResults.length);
    final pageResults = allResults.sublist(start, end);

    return Column(
      children: [
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
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  child: const Row(
                    children: [
                      Expanded(child: Text('Student', style: _headerStyle)),
                      SizedBox(width: 150, child: Text('Username', style: _headerStyle)),
                      SizedBox(width: 120, child: Text('Status', style: _headerStyle)),
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
                  final isParticipant = classState.participantIds.contains(student.id);
                  final isStudentLoading = classState.loadingStudentIds.contains(student.id);

                  return Column(
                    children: [
                      if (index > 0)
                        const Divider(height: 1, color: AppColors.borderLight),
                      _StudentRow(
                        student: student,
                        isParticipant: isParticipant,
                        isLoading: isStudentLoading,
                        onTap: () => widget.onStudentSelected?.call(student.id),
                        onEnrollToggle: () => _handleEnrollToggle(student.id, isParticipant),
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
          _buildPagination(totalPages),
        ],
      ],
    );
  }

  Widget _buildPagination(int totalPages) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Page ${_currentPage + 1} of $totalPages',
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.foregroundTertiary,
          ),
        ),
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left_rounded, size: 20),
              onPressed: _currentPage > 0
                  ? () => setState(() => _currentPage--)
                  : null,
            ),
            ...List.generate(
              totalPages.clamp(0, 5),
              (i) {
                final page = _currentPage < 3 ? i : _currentPage + i - 2;
                if (page >= totalPages) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => setState(() => _currentPage = page),
                    child: Container(
                      width: 32,
                      height: 32,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: page == _currentPage
                            ? AppColors.foregroundDark
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${page + 1}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: page == _currentPage
                              ? Colors.white
                              : AppColors.foregroundSecondary,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right_rounded, size: 20),
              onPressed: _currentPage < totalPages - 1
                  ? () => setState(() => _currentPage++)
                  : null,
            ),
          ],
        ),
      ],
    );
  }

  static const _headerStyle = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w700,
    color: AppColors.foregroundSecondary,
  );
}

/// A widget for displaying a single student row in the enrollment table
class _StudentRow extends StatelessWidget {
  final dynamic student;
  final bool isParticipant;
  final bool isLoading;
  final VoidCallback? onTap;
  final VoidCallback? onEnrollToggle;

  const _StudentRow({
    required this.student,
    required this.isParticipant,
    required this.isLoading,
    this.onTap,
    this.onEnrollToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          // Student info
          Expanded(
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(8),
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
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          student.fullName,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.foregroundDark,
                          ),
                        ),
                        if (student.email != null && student.email.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            student.email,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.foregroundTertiary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Username
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
          // Status
          SizedBox(
            width: 120,
            child: isParticipant
                ? Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF28A745).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'Enrolled',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF28A745),
                      ),
                    ),
                  )
                : Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.foregroundTertiary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'Not Enrolled',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.foregroundTertiary,
                      ),
                    ),
                  ),
          ),
          // Action button
          SizedBox(
            width: 80,
            child: Align(
              alignment: Alignment.centerRight,
              child: isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        color: AppColors.foregroundPrimary,
                        strokeWidth: 2,
                      ),
                    )
                  : Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: onEnrollToggle,
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: isParticipant
                                ? const Color(0xFFDC3545)
                                : const Color(0xFF28A745),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            isParticipant ? 'Remove' : 'Enroll',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
