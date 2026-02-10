import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/presentation/pages/student/student_class_detail_page.dart';
import 'package:likha/presentation/pages/student/widgets/student_header.dart';
import 'package:likha/presentation/pages/student/widgets/class_list_section.dart';
import 'package:likha/presentation/pages/student/widgets/empty_state.dart';
import 'package:likha/presentation/providers/class_provider.dart';

class StudentClassesPage extends ConsumerStatefulWidget {
  const StudentClassesPage({super.key});

  @override
  ConsumerState<StudentClassesPage> createState() =>
      _StudentClassesPageState();
}

class _StudentClassesPageState extends ConsumerState<StudentClassesPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(classProvider.notifier).loadClasses();
    });
  }

  @override
  Widget build(BuildContext context) {
    final classState = ref.watch(classProvider);

    return SafeArea(
      child: classState.isLoading && classState.classes.isEmpty
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF2B2B2B),
                strokeWidth: 2.5,
              ),
            )
          : RefreshIndicator(
              onRefresh: () =>
                  ref.read(classProvider.notifier).loadClasses(),
              color: const Color(0xFF2B2B2B),
              child: CustomScrollView(
                slivers: [
                  const SliverToBoxAdapter(
                    child: StudentHeader(title: 'Classes'),
                  ),
                  classState.classes.isEmpty
                      ? const SliverFillRemaining(
                          child: EmptyState(),
                        )
                      : ClassListSection(
                          classes: classState.classes,
                          onClassTap: (cls) => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => StudentClassDetailPage(
                                classId: cls.id,
                                classTitle: cls.title,
                              ),
                            ),
                          ),
                        ),
                  const SliverToBoxAdapter(
                    child: SizedBox(height: 40),
                  ),
                ],
              ),
            ),
    );
  }
}
