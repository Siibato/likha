import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/presentation/controllers/teacher/tos/tos_detail_controller.dart';
import 'package:likha/presentation/layouts/desktop/desktop_page_scaffold.dart';
import 'package:likha/presentation/providers/tos_provider.dart';
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
            if (tos != null)
              TosDetailActions(
                tos: tos,
                competencies: competencies,
                tosId: widget.tosId,
              ),
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
                          tosId: widget.tosId,
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
}
