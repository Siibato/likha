import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/presentation/pages/mobile/student/class/class_detail_page.dart';
import 'package:likha/presentation/widgets/shared/primitives/class_section_header.dart';
import 'package:likha/presentation/widgets/mobile/student/class/class_list_section.dart';
import 'package:likha/presentation/widgets/mobile/student/class/empty_state.dart';
import 'package:likha/presentation/providers/class_provider.dart';
import 'package:likha/presentation/providers/auth_provider.dart';
import 'package:likha/presentation/utils/logout_helper.dart';
import 'package:likha/presentation/widgets/shared/skeletons/skeleton_pulse.dart';
import 'package:likha/presentation/widgets/shared/skeletons/class_card_skeleton.dart';

class StudentClassListPage extends ConsumerStatefulWidget {
  const StudentClassListPage({super.key});

  @override
  ConsumerState<StudentClassListPage> createState() =>
      _StudentClassListPageState();
}

class _StudentClassListPageState extends ConsumerState<StudentClassListPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(classListProvider.notifier).loadClasses();
    });
  }

  @override
  Widget build(BuildContext context) {
    final classListState = ref.watch(classListProvider);
    ref.watch(authProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundSecondary,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: classListState.isLoading && classListState.classes.isEmpty
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
                          ref.read(classListProvider.notifier).loadClasses(),
                      color: AppColors.accentCharcoal,
                      child: CustomScrollView(
                        slivers: [
                          const SliverToBoxAdapter(
                            child: ClassSectionHeader(title: 'Classes'),
                          ),
                          classListState.classes.isEmpty
                              ? const SliverFillRemaining(
                                  child: EmptyState(),
                                )
                              : ClassListSection(
                                  classes: classListState.classes,
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
                            child: SizedBox(height: 16),
                          ),
                        ],
                      ),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
              child: _LogoutButton(
                  onTap: () => handleLogoutTap(context, ref)),
            ),
          ],
        ),
      ),
    );
  }
}

class _LogoutButton extends StatelessWidget {
  final VoidCallback onTap;

  const _LogoutButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Container(
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
              onTap: onTap,
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.logout_rounded,
                        color: AppColors.foregroundDark, size: 20),
                    SizedBox(width: 10),
                    Text(
                      'Log out',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.foregroundDark,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
