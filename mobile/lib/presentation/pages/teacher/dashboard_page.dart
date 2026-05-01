import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/presentation/layouts/mobile/mobile_page_scaffold.dart';
import 'package:likha/presentation/pages/teacher/class/class_detail_page.dart';
import 'package:likha/presentation/pages/shared/class_section_header.dart';
import 'package:likha/presentation/widgets/mobile/teacher/dashboard/empty_class_state.dart';
import 'package:likha/presentation/widgets/shared/cards/class_card.dart';
import 'package:likha/presentation/providers/class_provider.dart';
import 'package:likha/presentation/utils/logout_helper.dart';

class TeacherDashboardPage extends ConsumerStatefulWidget {
  const TeacherDashboardPage({super.key});

  @override
  ConsumerState<TeacherDashboardPage> createState() =>
      _TeacherDashboardPageState();
}

class _TeacherDashboardPageState extends ConsumerState<TeacherDashboardPage> {
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

    return MobilePageScaffold(
      title: 'My Classes',
      isLoading: classState.isLoading && classState.classes.isEmpty,
      header: const ClassSectionHeader(title: 'My Classes'),
      actions: [
        IconButton(
          icon: const Icon(Icons.logout_rounded),
          color: AppColors.accentCharcoal,
          onPressed: () => handleLogoutTap(context, ref),
        ),
      ],
      body: classState.classes.isEmpty
          ? const EmptyClassState()
          : RefreshIndicator(
              onRefresh: () => ref.read(classProvider.notifier).loadClasses(),
              color: AppColors.accentCharcoal,
              child: ListView.builder(
                padding: const EdgeInsets.all(24),
                itemCount: classState.classes.length,
                itemBuilder: (context, index) {
                  final cls = classState.classes[index];
                  return ClassCard(
                    title: cls.title,
                    subtitle: '${cls.studentCount} student${cls.studentCount != 1 ? 's' : ''}',
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
    );
  }
}