import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/presentation/layouts/desktop/desktop_page_scaffold.dart';
import 'package:likha/presentation/widgets/desktop/admin/class/enrollment_section.dart';

class AdminManageEnrollmentPage extends ConsumerStatefulWidget {
  final String classId;
  final String classTitle;

  const AdminManageEnrollmentPage({
    super.key,
    required this.classId,
    required this.classTitle,
  });

  @override
  ConsumerState<AdminManageEnrollmentPage> createState() =>
      _AdminManageEnrollmentPageState();
}

class _AdminManageEnrollmentPageState
    extends ConsumerState<AdminManageEnrollmentPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundSecondary,
      body: DesktopPageScaffold(
        title: 'Manage Enrollment',
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          color: AppColors.foregroundPrimary,
          onPressed: () => Navigator.pop(context),
        ),
        body: EnrollmentSection(
          classId: widget.classId,
          classTitle: widget.classTitle,
        ),
      ),
    );
  }
}
