import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/core/network/server_reachability_service.dart';
import 'package:likha/injection_container.dart';
import 'package:likha/presentation/controllers/teacher/tos/tos_detail_controller.dart';
import 'package:likha/presentation/layouts/desktop/desktop_page_scaffold.dart';
import 'package:likha/presentation/providers/tos_provider.dart';
import 'package:likha/presentation/providers/document_export_provider.dart';
import 'package:likha/presentation/widgets/desktop/teacher/tos/tos_competencies_section.dart';
import 'package:likha/presentation/widgets/desktop/teacher/tos/tos_detail_actions.dart';
import 'package:likha/presentation/widgets/desktop/teacher/tos/tos_specification_section.dart';
import 'package:likha/presentation/widgets/shared/feedback/provider_message_listener.dart';

class TosDetailPage extends ConsumerStatefulWidget {
  final String tosId;
  final String classId;

  const TosDetailPage({
    super.key,
    required this.tosId,
    required this.classId,
  });

  @override
  ConsumerState<TosDetailPage> createState() => _TosDetailPageState();
}

class _TosDetailPageState extends ConsumerState<TosDetailPage> {
  late final TosDetailController _controller;
  bool _isDownloading = false;

  @override
  void initState() {
    super.initState();
    _controller = TosDetailController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(tosProvider.notifier).loadTosDetail(widget.tosId);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(tosProvider);
    final tos = state.currentTos;
    final competencies = state.competencies;

    return ProviderMessageListener<TosState>(
      provider: tosProvider,
      successMessage: (s) => s.successMessage,
      errorMessage: (s) => s.error,
      onClear: () => ref.read(tosProvider.notifier).clearMessages(),
      child: Scaffold(
        backgroundColor: AppColors.backgroundSecondary,
        body: DesktopPageScaffold(
          title: tos?.title ?? 'TOS Detail',
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => Navigator.pop(context),
            tooltip: 'Back',
          ),
          actions: [
            if (tos != null) ...[
              TextButton.icon(
                onPressed: _isDownloading ? null : () => _downloadTos(tos),
                icon: _isDownloading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.download_rounded, size: 18),
                label: Text(_isDownloading ? 'Generating...' : 'Download TOS'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: AppColors.accentCharcoal,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              TosDetailActions(
                tos: tos,
                competencies: competencies,
              ),
            ],
          ],
          body: state.isLoading && tos == null
              ? const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.foregroundPrimary,
                    strokeWidth: 2.5,
                  ),
                )
              : tos == null
                  ? const Center(child: Text('TOS not found'))
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                        flex: 2,
                        child: TosCompetenciesSection(
                          tos: tos,
                          competencies: competencies,
                          controller: _controller,
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        flex: 3,
                        child: TosSpecificationSection(
                          tos: tos,
                          competencies: competencies,
                        ),
                      ),
                      ],
                    ),
        ),
      ),
    );
  }

  Future<void> _downloadTos(dynamic tos) async {
    final reachability = sl<ServerReachabilityService>();
    if (!reachability.isServerReachable) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Only available when connected to Likha server'),
          backgroundColor: AppColors.semanticError,
        ),
      );
      return;
    }

    setState(() => _isDownloading = true);

    await ref.read(documentExportProvider.notifier).exportTos(
      tosId: widget.tosId,
      tosTitle: tos.title,
    );

    if (!mounted) return;

    final exportState = ref.read(documentExportProvider);

    if (exportState.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(exportState.error!),
          backgroundColor: AppColors.semanticError,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('TOS Excel downloaded successfully'),
          backgroundColor: AppColors.semanticSuccess,
        ),
      );
    }

    setState(() => _isDownloading = false);
  }
}
