import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/presentation/pages/teacher/add_student_page.dart';
import 'package:likha/presentation/providers/class_provider.dart';

class AdminClassDetailPage extends ConsumerStatefulWidget {
  final String classId;

  const AdminClassDetailPage({super.key, required this.classId});

  @override
  ConsumerState<AdminClassDetailPage> createState() => _AdminClassDetailPageState();
}

class _AdminClassDetailPageState extends ConsumerState<AdminClassDetailPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(classProvider.notifier).loadClassDetail(widget.classId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final classState = ref.watch(classProvider);
    final detail = classState.currentClassDetail;

    ref.listen<ClassState>(classProvider, (prev, next) {
      if (next.successMessage != null && prev?.successMessage != next.successMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.successMessage!),
            backgroundColor: const Color(0xFF4CAF50),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
        ref.read(classProvider.notifier).clearMessages();
      }
    });

    // Get class and teacher name from classState
    final classInfo = classState.classes.cast<dynamic?>().firstWhere(
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
                  // Class Info Card
                  Card(
                    margin: const EdgeInsets.all(24),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: Color(0xFFE0E0E0)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            detail.title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF2B2B2B),
                            ),
                          ),
                          if (detail.description != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              detail.description!,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF666666),
                              ),
                            ),
                          ],
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5F5F5),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Teacher: $teacherName',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Students Section
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Students Enrolled',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2B2B2B),
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AddStudentPage(classId: widget.classId),
                            ),
                          ).then((_) => ref.read(classProvider.notifier).loadClassDetail(widget.classId)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2B2B2B),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          icon: const Icon(Icons.person_add_rounded, size: 16),
                          label: const Text(
                            'Add/Remove',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Students List
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: detail.students.isEmpty
                        ? Container(
                            padding: const EdgeInsets.symmetric(vertical: 32),
                            child: Center(
                              child: Column(
                                children: const [
                                  Icon(
                                    Icons.person_outline_rounded,
                                    size: 48,
                                    color: Color(0xFFCCCCCC),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'No students enrolled',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF999999),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: detail.students.length,
                            itemBuilder: (context, index) {
                              final enrollment = detail.students[index];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  side: const BorderSide(color: Color(0xFFE0E0E0)),
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  leading: const Icon(
                                    Icons.person_outline_rounded,
                                    color: Color(0xFF2B2B2B),
                                  ),
                                  title: Text(
                                    enrollment.student.fullName,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  subtitle: Text(
                                    '@${enrollment.student.username}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF999999),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }
}
