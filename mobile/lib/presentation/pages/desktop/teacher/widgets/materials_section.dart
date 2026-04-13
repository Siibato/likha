import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/presentation/pages/desktop/core/desktop_page_scaffold.dart';
import 'package:likha/presentation/pages/desktop/teacher/create_material_desktop.dart';
import 'package:likha/presentation/pages/desktop/teacher/material_detail_desktop.dart';
import 'package:likha/presentation/pages/desktop/teacher/widgets/material_data_table.dart';
import 'package:likha/presentation/providers/learning_material_provider.dart';

/// Materials section widget for TeacherClassDetailDesktop
/// Displays a list of learning materials with create and navigation functionality
class MaterialsSection extends ConsumerWidget {
  final String classId;

  const MaterialsSection({
    super.key,
    required this.classId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(learningMaterialProvider);

    return DesktopPageScaffold(
      title: 'Materials',
      actions: [
        FilledButton.icon(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CreateMaterialDesktop(classId: classId),
            ),
          ).then((result) {
            if (result == true) {
              ref
                  .read(learningMaterialProvider.notifier)
                  .loadMaterials(classId);
            }
          }),
          icon: const Icon(Icons.add_rounded, size: 18),
          label: const Text('Create Module'),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.foregroundDark,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
        ),
      ],
      body: state.isLoading && state.materials.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(
                  color: AppColors.foregroundPrimary,
                  strokeWidth: 2.5,
                ),
              ),
            )
          : MaterialDataTable(
              materials: state.materials,
              onTap: (material) => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      MaterialDetailDesktop(materialId: material.id),
                ),
              ).then((_) => ref
                  .read(learningMaterialProvider.notifier)
                  .loadMaterials(classId)),
            ),
    );
  }
}
