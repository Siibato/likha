import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/presentation/pages/desktop/core/desktop_page_scaffold.dart';
import 'package:likha/presentation/pages/desktop/admin/widgets/enrollment_section.dart';

class AdminManageEnrollmentDesktop extends ConsumerStatefulWidget {
  final String classId;
  final String classTitle;

  const AdminManageEnrollmentDesktop({
    super.key,
    required this.classId,
    required this.classTitle,
  });

  @override
  ConsumerState<AdminManageEnrollmentDesktop> createState() =>
      _AdminManageEnrollmentDesktopState();
}

class _AdminManageEnrollmentDesktopState
    extends ConsumerState<AdminManageEnrollmentDesktop> {
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
