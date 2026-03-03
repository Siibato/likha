import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/presentation/pages/teacher/class_detail_page.dart';
import 'package:likha/presentation/pages/teacher/widgets/empty_class_state.dart';
import 'package:likha/presentation/pages/teacher/widgets/teacher_class_card.dart';
import 'package:likha/presentation/pages/shared/class_section_header.dart';
import 'package:likha/presentation/providers/class_provider.dart';

class TeacherClassesPage extends ConsumerStatefulWidget {
  const TeacherClassesPage({super.key});

  @override
  ConsumerState<TeacherClassesPage> createState() => _TeacherClassesPageState();
}

class _TeacherClassesPageState extends ConsumerState<TeacherClassesPage> {
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
              onRefresh: () => ref.read(classProvider.notifier).loadClasses(),
              color: const Color(0xFF2B2B2B),
              child: CustomScrollView(
                slivers: [
                  const SliverToBoxAdapter(
                    child: ClassSectionHeader(title: 'My Classes'),
                  ),
                  classState.classes.isEmpty
                      ? const SliverFillRemaining(
                          child: EmptyClassState(),
                        )
                      : SliverPadding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          sliver: SliverList.builder(
                            itemCount: classState.classes.length,
                            itemBuilder: (context, index) {
                              final cls = classState.classes[index];
                              return TeacherClassCard(
                                title: cls.title,
                                studentCount: cls.studentCount,
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ClassDetailPage(classId: cls.id),
                                  ),
                                ).then((_) =>
                                    ref.read(classProvider.notifier).loadClasses()),
                              );
                            },
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
