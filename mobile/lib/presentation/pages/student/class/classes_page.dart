import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/presentation/pages/student/class/class_detail_page.dart';
import 'package:likha/presentation/pages/shared/class_section_header.dart';
import 'package:likha/presentation/widgets/mobile/student/class/class_list_section.dart';
import 'package:likha/presentation/widgets/mobile/student/class/empty_state.dart';
import 'package:likha/presentation/providers/class_provider.dart';
import 'package:likha/presentation/widgets/shared/skeletons/skeleton_pulse.dart';
import 'package:likha/presentation/widgets/shared/skeletons/class_card_skeleton.dart';

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
          ? SkeletonPulse(
              child: ListView.builder(
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                itemCount: 6,
                itemBuilder: (_, __) => const ClassCardSkeleton(),
              ),
            )
          : RefreshIndicator(
              onRefresh: () =>
                  ref.read(classProvider.notifier).loadClasses(),
              color: AppColors.accentCharcoal,
              child: CustomScrollView(
                slivers: [
                  const SliverToBoxAdapter(
                    child: ClassSectionHeader(title: 'Classes'),
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
