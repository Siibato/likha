import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/core/errors/error_messages.dart';
import 'package:likha/core/logging/page_logger.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/presentation/controllers/teacher/material/material_detail_controller.dart';
import 'package:likha/presentation/providers/learning_material_provider.dart';
import 'package:likha/presentation/widgets/mobile/teacher/material/material_attachments_card.dart';
import 'package:likha/presentation/widgets/mobile/teacher/material/material_body_card.dart';
import 'package:likha/presentation/widgets/mobile/teacher/material/material_detail_options_sheet.dart';
import 'package:likha/presentation/widgets/mobile/teacher/material/material_info_card.dart';
import 'package:likha/presentation/widgets/mobile/teacher/material/material_upload_progress_card.dart';
import 'package:likha/presentation/widgets/shared/dialogs/app_dialogs.dart';
import 'package:likha/presentation/widgets/shared/feedback/content_state_builder.dart';
import 'package:likha/presentation/widgets/shared/feedback/provider_message_listener.dart';
import 'package:likha/presentation/widgets/shared/primitives/class_section_header.dart';

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
    PageLogger.instance.log(
        'MaterialDetailPage initState - materialId: ${widget.materialId}');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      PageLogger.instance.log('Now calling loadMaterialDetail()');
      ref
          .read(learningMaterialProvider.notifier)
          .loadMaterialDetail(widget.materialId);
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
      errorMessage: (s) => AppErrorMapper.toUserMessage(s.error),
      onClear: () =>
          ref.read(learningMaterialProvider.notifier).clearMessages(),
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
        body: SafeArea(
          child: ContentStateBuilder(
            isLoading: state.isLoading && material == null,
            error: state.error,
            isEmpty: false,
            onRetry: () => ref
                .read(learningMaterialProvider.notifier)
                .loadMaterialDetail(widget.materialId),
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Stack(
                    children: [
                      ClassSectionHeader(
                        title: material?.title ?? 'Module Details',
                        showBackButton: true,
                      ),
                      Positioned(
                        right: 24,
                        top: 24,
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.backgroundTertiary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: IconButton(
                            icon: const Icon(
                              Icons.more_vert_rounded,
                              color: AppColors.foregroundDark,
                              size: 24,
                            ),
                            onPressed: () {
                              showModalBottomSheet(
                                context: context,
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(24),
                                    topRight: Radius.circular(24),
                                  ),
                                ),
                                builder: (_) => MaterialDetailOptionsSheet(
                                  material: material,
                                  materialId: widget.materialId,
                                  controller: _controller,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.all(24),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      MaterialInfoCard(
                        title: material!.title,
                        description: material.description,
                        fileCount: material.files.length,
                        updatedAt: material.updatedAt,
                        syncStatus: material.syncStatus,
                      ),
                      const SizedBox(height: 16),
                      if (material.contentText != null &&
                          material.contentText!.isNotEmpty) ...[
                        MaterialBodyCard(contentText: material.contentText),
                        const SizedBox(height: 16),
                      ],
                      if (state.isLoading &&
                          state.currentUploadFileName != null) ...[
                        MaterialUploadProgressCard(
                          fileName: state.currentUploadFileName!,
                          progress: state.uploadProgress,
                        ),
                        const SizedBox(height: 16),
                      ],
                      if (material.files.isNotEmpty)
                        MaterialAttachmentsCard(
                          files: material.files,
                          isTeacher: true,
                          isLoading: state.isLoading,
                          allCached: false,
                          uncachedCount: 0,
                          onUploadFile: () => _controller.uploadFile(
                            materialId: widget.materialId,
                            notifier: ref.read(
                                learningMaterialProvider.notifier),
                          ),
                          onOpenFile: (file) => _controller.handleFile(
                            file: file,
                            notifier: ref.read(
                                learningMaterialProvider.notifier),
                          ),
                          onSaveFile: (file) => _controller.handleFile(
                            file: file,
                            notifier: ref.read(
                                learningMaterialProvider.notifier),
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
                              notifier: ref.read(
                                  learningMaterialProvider.notifier),
                            ),
                          ),
                        ),
                      const SizedBox(height: 40),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
