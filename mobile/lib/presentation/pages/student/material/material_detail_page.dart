import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/core/errors/error_messages.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/domain/learning_materials/entities/material_file.dart';
import 'package:likha/presentation/pages/shared/class_section_header.dart';
import 'package:likha/presentation/widgets/shared/cards/base_card.dart';
import 'package:likha/presentation/widgets/shared/cards/info_panel.dart';
import 'package:likha/presentation/widgets/shared/cards/markdown_display.dart';
import 'package:likha/presentation/widgets/shared/primitives/card_icon_slot.dart';
import 'package:likha/presentation/widgets/shared/primitives/status_badge.dart';
import 'package:likha/presentation/widgets/shared/forms/form_message.dart';
import 'package:flutter/foundation.dart';
import 'package:likha/core/utils/file_opener.dart';
import 'package:likha/presentation/providers/learning_material_provider.dart';

class StudentMaterialDetailPage extends ConsumerStatefulWidget {
  final String materialId;

  const StudentMaterialDetailPage({super.key, required this.materialId});

  @override
  ConsumerState<StudentMaterialDetailPage> createState() => _StudentMaterialDetailPageState();
}

class _StudentMaterialDetailPageState extends ConsumerState<StudentMaterialDetailPage> {
  String? _formError;
  String? _downloadingFileId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(learningMaterialProvider.notifier).loadMaterialDetail(widget.materialId);
    });
  }

  Future<void> _openFile(MaterialFile file) async {
    if (kIsWeb) {
      setState(() => _formError = 'Opening file...');
      final bytes = await ref
          .read(learningMaterialProvider.notifier)
          .downloadFile(file.id);
      if (!mounted) return;
      if (bytes != null) {
        await openFileInBrowser(bytes, file.fileName);
        setState(() => _formError = null);
      } else {
        setState(() => _formError = 'Failed to open file');
      }
      return;
    }

    if (file.localPath == null || file.localPath!.isEmpty) {
      if (!mounted) return;
      setState(() => _formError = 'File not cached. Downloading...');
      await _saveFile(file);
      return;
    }

    try {
      await openLocalFile(file.localPath!);
    } catch (e) {
      if (!mounted) return;
      setState(() => _formError = 'Error opening file: $e');
    }
  }

  Future<void> _saveFile(MaterialFile file) async {
    setState(() => _downloadingFileId = file.id);
    await ref.read(learningMaterialProvider.notifier).downloadFile(file.id);

    if (!mounted) return;
    setState(() => _downloadingFileId = null);

    final providerState = ref.read(learningMaterialProvider);
    if (providerState.error != null) {
      setState(() => _formError = 'Failed to download file');
    } else {
      setState(() => _formError = null);
    }
  }

  Future<void> _downloadAllFiles() async {
    final material = ref.read(learningMaterialProvider).currentMaterial;
    if (material == null || material.files.isEmpty) return;

    final toDownload = material.files.where((f) => !f.isCached).toList();
    if (toDownload.isEmpty) return;

    for (final file in toDownload) {
      await _saveFile(file);
      if (!mounted) return;
    }

    if (!mounted) return;
    setState(() => _formError = null);
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String _formatDate(DateTime dt) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(learningMaterialProvider);
    final material = state.currentMaterial;

    ref.listen<LearningMaterialState>(learningMaterialProvider, (prev, next) {
      if (next.error != null && prev?.error != next.error) {
        setState(() => _formError = AppErrorMapper.toUserMessage(next.error));
        ref.read(learningMaterialProvider.notifier).clearMessages();
      }
      if (next.successMessage != null && prev?.successMessage != next.successMessage) {
        setState(() => _formError = null);
        ref.read(learningMaterialProvider.notifier).clearMessages();
      }
    });

    final allCached = material != null && material.files.isNotEmpty && material.files.every((f) => f.isCached);
    final uncachedFiles = material != null ? material.files.where((f) => !f.isCached).toList() : <MaterialFile>[];

    return Scaffold(
      backgroundColor: AppColors.backgroundSecondary,
      body: SafeArea(
        child: state.isLoading && material == null
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.accentCharcoal, strokeWidth: 2.5),
              )
            : state.error != null && material == null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline_rounded, size: 64, color: AppColors.foregroundLight,),
                        const SizedBox(height: 16),
                        const Text('Failed to load module', style: TextStyle(fontSize: 16, color: AppColors.foregroundDark)),
                        const SizedBox(height: 24),
                        OutlinedButton(
                          onPressed: () => ref.read(learningMaterialProvider.notifier).loadMaterialDetail(widget.materialId),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : CustomScrollView(
                    slivers: [
                      const SliverToBoxAdapter(
                        child: ClassSectionHeader(
                          title: 'Module Details',
                          showBackButton: true,
                        ),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.all(24),
                        sliver: SliverList(
                          delegate: SliverChildListDelegate([
                            // Form Error Display
                            FormMessage(
                              message: _formError,
                              severity: MessageSeverity.error,
                            ),
                            if (_formError != null) const SizedBox(height: 12),

                            // Module Info Header Card
                            _buildInfoCard(material),
                            const SizedBox(height: 16),

                            // Module Content Section
                            if (material!.contentText != null && material.contentText!.isNotEmpty) ...[
                              _buildContentCard(material),
                              const SizedBox(height: 16),
                            ],

                            // Download Status Banner
                            if (allCached && material.files.isNotEmpty) ...[
                              _buildDownloadStatusBanner(),
                              const SizedBox(height: 16),
                            ],

                            // Attachments Section
                            if (material.files.isNotEmpty) ...[
                              _buildAttachmentsCard(material, allCached, uncachedFiles.length),
                            ],

                            const SizedBox(height: 40),
                          ]),
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }

  Widget _buildInfoCard(dynamic material) {
    return BaseCard(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            material.title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AppColors.accentCharcoal,
              letterSpacing: -0.5,
            ),
          ),
          if (material.description != null && material.description!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(height: 1, color: AppColors.borderLight,),
            const SizedBox(height: 12),
            Text(
              material.description!,
              style: const TextStyle(
                fontSize: 15,
                color: AppColors.foregroundDark,
                height: 1.5,
              ),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              _InfoChip(
                icon: Icons.attach_file_rounded,
                label: '${material.files.length} file(s)',
              ),
              const SizedBox(width: 14),
              _InfoChip(
                icon: Icons.schedule_rounded,
                label: 'Updated ${_formatDate(material.updatedAt)}',
              ),
            ],
          ),
          if (material.needsSync) ...[
            const SizedBox(height: 12),
            const StatusBadge(
              label: 'Pending sync',
              color: AppColors.borderLight,
              variant: BadgeVariant.outlined,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildContentCard(dynamic material) {
    return BaseCard(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Content',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.foregroundDark,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          Container(height: 1, color: AppColors.borderLight,),
          const SizedBox(height: 12),
          MarkdownDisplay(content: material.contentText),
        ],
      ),
    );
  }

  Widget _buildDownloadStatusBanner() {
    return const InfoPanel(
      padding: EdgeInsets.all(14),
      child: Row(
        children: [
          Icon(
            Icons.check_circle_rounded,
            color: AppColors.semanticSuccess,
            size: 18,
          ),
          SizedBox(width: 10),
          Text(
            'All files downloaded',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.semanticSuccessAlt,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttachmentsCard(dynamic material, bool allCached, int uncachedCount) {
    return BaseCard(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Attachments',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.foregroundDark,
                  letterSpacing: -0.4,
                ),
              ),
              if (!allCached && !kIsWeb)
                FilledButton(
                  onPressed: _downloadingFileId != null ? null : _downloadAllFiles,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.backgroundPrimary,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: _downloadingFileId != null
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            color: AppColors.accentCharcoal,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          uncachedCount == material.files.length ? 'Download All' : 'Download $uncachedCount remaining',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Container(height: 1, color: AppColors.borderLight,),
          const SizedBox(height: 12),
          ...material.files.asMap().entries.map((entry) {
            final file = entry.value;
            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CardIconSlot.sm(
                icon: Icons.insert_drive_file_rounded,
              ),
              title: Text(
                file.fileName,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.accentCharcoal,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                _formatFileSize(file.fileSize),
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.foregroundTertiary,
                ),
              ),
              trailing: _downloadingFileId == file.id
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: AppColors.accentCharcoal,
                        strokeWidth: 2,
                      ),
                    )
                  : IconButton(
                      icon: kIsWeb
                          ? const Icon(Icons.open_in_browser_rounded, color: AppColors.accentCharcoal)
                          : file.isCached
                              ? const Icon(Icons.folder_open_rounded)
                              : const Icon(Icons.download_rounded, color: AppColors.accentCharcoal),
                      onPressed: _downloadingFileId != null
                          ? null
                          : kIsWeb
                              ? () => _openFile(file)
                              : file.isCached
                                  ? () => _openFile(file)
                                  : () => _saveFile(file),
                    ),
            );
          }),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: AppColors.foregroundSecondary,),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.foregroundSecondary,
            fontWeight: FontWeight.w500,
            letterSpacing: -0.2,
          ),
        ),
      ],
    );
  }
}
