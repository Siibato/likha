import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/presentation/pages/admin/admin_edit_class_page.dart';
import 'package:likha/presentation/pages/admin/widgets/student_action_card.dart';
import 'package:likha/presentation/pages/shared/widgets/cards/info_panel.dart';
import 'package:likha/presentation/pages/shared/widgets/primitives/info_row.dart';
import 'package:likha/presentation/pages/shared/widgets/tokens/app_text_styles.dart';
import 'package:likha/presentation/providers/class_provider.dart';

class AdminClassDetailPage extends ConsumerStatefulWidget {
  final String classId;

  const AdminClassDetailPage({super.key, required this.classId});

  @override
  ConsumerState<AdminClassDetailPage> createState() => _AdminClassDetailPageState();
}

class _AdminClassDetailPageState extends ConsumerState<AdminClassDetailPage> {
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

    // Add search listener with debounce
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      final query = _searchController.text.trim();
      setState(() {
        _searchQuery = query;
      });

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
      // Success snackbar
      if (next.successMessage != null && prev?.successMessage != next.successMessage) {
        ref.read(classProvider.notifier).clearMessages();
      }

      // Error snackbar
      if (next.error != null && prev?.error != next.error) {
        ref.read(classProvider.notifier).clearMessages();
      }
    });

    // Get class and teacher name from classState
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
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF2B2B2B)),
        title: Text(
          detail?.title ?? 'Class Detail',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Color(0xFF2B2B2B),
            letterSpacing: -0.4,
          ),
        ),
        actions: [
          if (classInfo != null)
            IconButton(
              icon: const Icon(Icons.edit_rounded),
              tooltip: 'Edit Class',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AdminEditClassPage(classEntity: classInfo),
                ),
              ).then((_) {
                ref.read(classProvider.notifier).loadAllClasses();
                ref.read(classProvider.notifier).loadClassDetail(widget.classId);
              }),
            ),
        ],
      ),
      body: detail == null
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF2B2B2B),
                strokeWidth: 2.5,
              ),
            )
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Class Info Panel
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: InfoPanel(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            detail.title,
                            style: AppTextStyles.cardTitleLg,
                          ),
                          if (detail.description != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              detail.description!,
                              style: AppTextStyles.cardSubtitleMd,
                            ),
                          ],
                          const SizedBox(height: 16),
                          InfoRow(
                            label: 'Teacher',
                            value: teacherName,
                          ),
                          if (classInfo != null && classInfo.teacherUsername.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            InfoRow(
                              label: 'Username',
                              value: classInfo.teacherUsername,
                            ),
                          ],
                          if (detail.isAdvisory) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF4CAF50).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFF4CAF50).withValues(alpha: 0.3)),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.star_rounded, size: 16, color: Color(0xFF4CAF50)),
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
                  ),

                  // Search Bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE0E0E0)),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.search_rounded,
                              color: Color(0xFF999999),
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: _searchController,
                                decoration: const InputDecoration(
                                  hintText: 'Search students...',
                                  hintStyle: TextStyle(
                                    color: Color(0xFF999999),
                                    fontSize: 14,
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(vertical: 12),
                                ),
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF2B2B2B),
                                ),
                              ),
                            ),
                            if (_searchQuery.isNotEmpty)
                              GestureDetector(
                                onTap: () {
                                  _searchController.clear();
                                  _searchQuery = '';
                                  ref.read(classProvider.notifier).clearSearch();
                                },
                                child: const Icon(
                                  Icons.clear_rounded,
                                  color: Color(0xFF999999),
                                  size: 20,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Students Section - Show all students from search (loaded on init)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                    child: Text(
                      _searchQuery.isEmpty
                          ? 'All Students (${classState.searchResults.length})'
                          : 'Search Results (${classState.searchResults.length})',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2B2B2B),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: () {
                      if (classState.isLoading && classState.searchResults.isEmpty) {
                        return Container(
                          padding: const EdgeInsets.symmetric(vertical: 32),
                          child: const Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFF2B2B2B),
                              strokeWidth: 2.5,
                            ),
                          ),
                        );
                      }

                      if (classState.searchResults.isEmpty) {
                        return Container(
                          padding: const EdgeInsets.symmetric(vertical: 32),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(
                                  _searchQuery.isEmpty
                                      ? Icons.person_outline_rounded
                                      : Icons.person_search_rounded,
                                  size: 48,
                                  color: const Color(0xFFCCCCCC),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _searchQuery.isEmpty
                                      ? 'No students available'
                                      : 'No students found',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF999999),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: classState.searchResults.length,
                        itemBuilder: (context, index) {
                          final student = classState.searchResults[index];
                          final isParticipant = classState.participantIds.contains(student.id);
                          final isLoading = classState.loadingStudentIds.contains(student.id);

                          return StudentActionCard(
                            student: student,
                            isParticipant: isParticipant,
                            isLoading: isLoading,
                            onAdd: isParticipant
                                ? null
                                : () {
                                    ref.read(classProvider.notifier).addStudent(
                                          classId: widget.classId,
                                          studentId: student.id,
                                        );
                                  },
                            onRemove: isParticipant
                                ? () {
                                    ref.read(classProvider.notifier).removeStudent(
                                          classId: widget.classId,
                                          studentId: student.id,
                                        );
                                  }
                                : null,
                          );
                        },
                      );
                    }(),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }
}
