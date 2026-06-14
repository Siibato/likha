import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/core/errors/error_messages.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/presentation/controllers/teacher/material/material_detail_controller.dart';
import 'package:likha/presentation/layouts/desktop/desktop_page_scaffold.dart';
import 'package:likha/presentation/providers/learning_material_provider.dart';
import 'package:likha/presentation/widgets/desktop/teacher/material/material_body.dart';
import 'package:likha/presentation/widgets/desktop/teacher/material/material_detail_actions_menu.dart';
import 'package:likha/presentation/widgets/shared/dialogs/app_dialogs.dart';
import 'package:likha/presentation/widgets/shared/feedback/provider_message_listener.dart';

class MaterialDetailPage extends ConsumerStatefulWidget {
  final String materialId;

  const MaterialDetailPage({super.key, required this.materialId});

  @override
  ConsumerState<MaterialDetailPage> createState() =>
      _MaterialDetailPageState();
}

class _MaterialDetailPageState extends ConsumerState<MaterialDetailPage> {
  late final MaterialDetailController _controller;

  @override
  void initState() {
    super.initState();
    _controller = MaterialDetailController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(learningMaterialProvider.notifier).loadMaterialDetail(
            widget.materialId,
          );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(learningMaterialProvider);
    final material = state.currentMaterial;

    return ProviderMessageListener<LearningMaterialState>(
      provider: learningMaterialProvider,
      successMessage: (s) => s.successMessage,
      errorMessage: (s) =>
          AppErrorMapper.toUserMessage(s.error) ?? 'An error occurred',
      onClear: () => ref.read(learningMaterialProvider.notifier).clearMessages(),
      intercept: (prev, next) {
        if (next.successMessage == 'Material deleted successfully') {
          ref.read(learningMaterialProvider.notifier).clearMessages();
          if (mounted) Navigator.pop(context, true);
          return true;
        }
        return false;
      },
      child: Scaffold(
        backgroundColor: AppColors.backgroundSecondary,
        body: DesktopPageScaffold(
          title: material?.title ?? 'Module Detail',
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => Navigator.of(context).pop(),
            tooltip: 'Back',
          ),
          actions: [
            if (material != null) ...[
              OutlinedButton.icon(
                onPressed: state.isLoading
                    ? null
                    : () => _controller.uploadFile(
                          materialId: widget.materialId,
                          notifier:
                              ref.read(learningMaterialProvider.notifier),
                        ),
                icon: const Icon(Icons.upload_file_rounded, size: 18),
                label: const Text('Upload File'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.foregroundDark,
                  side: const BorderSide(color: AppColors.borderLight),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              MaterialDetailActionsMenu(
                material: material,
                materialId: widget.materialId,
                controller: _controller,
              ),
            ],
          ],
          body: state.isLoading && material == null
              ? const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.foregroundPrimary,
                    strokeWidth: 2.5,
                  ),
                )
              : material == null
                  ? const Center(
                      child: Text(
                        'Module not found',
                        style:
                            TextStyle(color: AppColors.foregroundTertiary),
                      ),
                    )
                  : MaterialBody(
                      material: material,
                      isLoading: state.isLoading,
                      onHandleFile: (file) => _controller.handleFile(
                        file: file,
                        notifier:
                            ref.read(learningMaterialProvider.notifier),
                      ),
                      onDeleteFile: (file) => AppDialogs.showDestructive(
                        context: context,
                        title: 'Delete File',
                        body:
                            'Are you sure you want to delete "${file.fileName}"?',
                        confirmLabel: 'Delete',
                        onConfirm: () => _controller.deleteFile(
                          file: file,
                          materialId: widget.materialId,
                          notifier:
                              ref.read(learningMaterialProvider.notifier),
                        ),
                      ),
                      onUploadFile: () => _controller.uploadFile(
                        materialId: widget.materialId,
                        notifier:
                            ref.read(learningMaterialProvider.notifier),
                      ),
                    ),
        ),
      ),
    );
  }

}
