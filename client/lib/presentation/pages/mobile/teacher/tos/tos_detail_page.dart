import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/presentation/controllers/teacher/tos/tos_detail_controller.dart';
import 'package:likha/presentation/providers/tos_provider.dart';
import 'package:likha/presentation/widgets/mobile/teacher/tos/tos_competencies_list_section.dart';
import 'package:likha/presentation/widgets/mobile/teacher/tos/tos_detail_action_chips.dart';
import 'package:likha/presentation/widgets/mobile/teacher/tos/tos_settings_card.dart';
import 'package:likha/presentation/widgets/mobile/teacher/tos/tos_specification_grid_section.dart';
import 'package:likha/presentation/widgets/shared/feedback/provider_message_listener.dart';
import 'package:likha/presentation/widgets/shared/primitives/class_section_header.dart';

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
        body: SafeArea(
          child: Column(
            children: [
              ClassSectionHeader(
                title: tos?.title ?? 'TOS Detail',
                showBackButton: true,
              ),
              Expanded(
                child: state.isLoading && tos == null
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.accentCharcoal,
                          strokeWidth: 2.5,
                        ),
                      )
                    : tos == null
                        ? const Center(child: Text('TOS not found'))
                        : RefreshIndicator(
                            onRefresh: () => ref
                                .read(tosProvider.notifier)
                                .loadTosDetail(widget.tosId),
                            color: AppColors.accentCharcoal,
                            child: SingleChildScrollView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  TosDetailActionChips(
                                    tos: tos,
                                    competencies: competencies,
                                    tosId: widget.tosId,
                                  ),
                                  const SizedBox(height: 16),
                                  TosSettingsCard(
                                    tos: tos,
                                    competencyCount: competencies.length,
                                    totalDays: competencies.fold<int>(
                                        0, (s, c) => s + c.timeUnitsTaught),
                                  ),
                                  const SizedBox(height: 20),
                                  TosSpecificationGridSection(
                                    tos: tos,
                                    competencies: competencies,
                                    controller: _controller,
                                  ),
                                  const SizedBox(height: 24),
                                  TosCompetenciesListSection(
                                    tos: tos,
                                    competencies: competencies,
                                    controller: _controller,
                                    tosId: widget.tosId,
                                  ),
                                  const SizedBox(height: 32),
                                ],
                              ),
                            ),
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
