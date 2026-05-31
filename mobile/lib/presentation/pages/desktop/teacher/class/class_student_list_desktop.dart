import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/presentation/pages/desktop/core/desktop_page_scaffold.dart';
import 'package:likha/presentation/widgets/desktop/teacher/class/student_data_table.dart';
import 'package:likha/presentation/providers/class_provider.dart';

class ClassStudentListDesktop extends ConsumerStatefulWidget {
  final String classId;

  const ClassStudentListDesktop({super.key, required this.classId});

  @override
  ConsumerState<ClassStudentListDesktop> createState() =>
      _ClassStudentListDesktopState();
}

class _ClassStudentListDesktopState
    extends ConsumerState<ClassStudentListDesktop> {
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

    return Scaffold(
      backgroundColor: AppColors.backgroundSecondary,
      body: DesktopPageScaffold(
        title: 'Students',
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
            : StudentDataTable(students: detail.students),
      ),
    );
  }
}
