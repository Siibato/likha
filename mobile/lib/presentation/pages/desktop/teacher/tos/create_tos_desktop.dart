import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/presentation/pages/desktop/core/desktop_page_scaffold.dart';
import 'package:likha/presentation/pages/desktop/teacher/tos/tos_detail_desktop.dart';
import 'package:likha/presentation/widgets/shared/forms/form_message.dart';
import 'package:likha/presentation/widgets/mobile/teacher/tos/blooms_ratio_section.dart';
import 'package:likha/presentation/widgets/mobile/teacher/tos/classification_mode_toggle.dart';
import 'package:likha/presentation/widgets/mobile/teacher/tos/difficulty_ratio_section.dart';
import 'package:likha/presentation/widgets/mobile/teacher/assessment/time_unit_toggle.dart';
import 'package:likha/presentation/providers/tos_provider.dart';

class CreateTosDesktop extends ConsumerStatefulWidget {
  final String classId;

  const CreateTosDesktop({super.key, required this.classId});

  @override
  ConsumerState<CreateTosDesktop> createState() => _CreateTosDesktopState();
}

class _CreateTosDesktopState extends ConsumerState<CreateTosDesktop> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _totalItemsController = TextEditingController(text: '50');
  final _easyPctController = TextEditingController(text: '50');
  final _mediumPctController = TextEditingController(text: '30');
  final _hardPctController = TextEditingController(text: '20');
  final _rememberingPctController = TextEditingController(text: '16.67');
  final _understandingPctController = TextEditingController(text: '16.67');
  final _applyingPctController = TextEditingController(text: '16.67');
  final _analyzingPctController = TextEditingController(text: '16.67');
  final _evaluatingPctController = TextEditingController(text: '16.67');
  final _creatingPctController = TextEditingController(text: '16.67');
  int? _selectedQuarter;
  String _classificationMode = 'blooms';
  String _timeUnit = 'days';
  String? _pctError;

  @override
  void dispose() {
    _titleController.dispose();
    _totalItemsController.dispose();
    _easyPctController.dispose();
    _mediumPctController.dispose();
    _hardPctController.dispose();
    _rememberingPctController.dispose();
    _understandingPctController.dispose();
    _applyingPctController.dispose();
    _analyzingPctController.dispose();
    _evaluatingPctController.dispose();
    _creatingPctController.dispose();
    super.dispose();
  }

  String? _validatePercentages() {
    if (_classificationMode == 'blooms') {
      final total = [
        _rememberingPctController,
        _understandingPctController,
        _applyingPctController,
        _analyzingPctController,
        _evaluatingPctController,
        _creatingPctController,
      ].fold(0.0, (sum, c) => sum + (double.tryParse(c.text.trim()) ?? 0));
      if ((total - 100).abs() > 0.5) {
        return "Bloom's percentages must add up to 100% (currently ${total.toStringAsFixed(1)}%)";
      }
    } else {
      final total = [
        _easyPctController,
        _mediumPctController,
        _hardPctController,
      ].fold(0.0, (sum, c) => sum + (double.tryParse(c.text.trim()) ?? 0));
      if ((total - 100).abs() > 0.5) {
        return 'Difficulty percentages must add up to 100% (currently ${total.toStringAsFixed(1)}%)';
      }
    }
    return null;
  }

  Future<void> _handleCreate() async {
    final pctError = _validatePercentages();
    if (pctError != null) {
      setState(() => _pctError = pctError);
      return;
    }
    setState(() => _pctError = null);
    if (!_formKey.currentState!.validate()) return;
    if (_selectedQuarter == null) return;

    final tos = await ref.read(tosProvider.notifier).createTos(
      widget.classId,
      {
        'title': _titleController.text.trim(),
        'grading_period_number': _selectedQuarter!,
        'classification_mode': _classificationMode,
        'total_items': int.tryParse(_totalItemsController.text.trim()) ?? 50,
        'time_unit': _timeUnit,
        'easy_percentage': double.tryParse(_easyPctController.text.trim()) ?? 50.0,
        'medium_percentage': double.tryParse(_mediumPctController.text.trim()) ?? 30.0,
        'hard_percentage': double.tryParse(_hardPctController.text.trim()) ?? 20.0,
        'remembering_percentage': double.tryParse(_rememberingPctController.text.trim()) ?? 16.67,
        'understanding_percentage': double.tryParse(_understandingPctController.text.trim()) ?? 16.67,
        'applying_percentage': double.tryParse(_applyingPctController.text.trim()) ?? 16.67,
        'analyzing_percentage': double.tryParse(_analyzingPctController.text.trim()) ?? 16.67,
        'evaluating_percentage': double.tryParse(_evaluatingPctController.text.trim()) ?? 16.67,
        'creating_percentage': double.tryParse(_creatingPctController.text.trim()) ?? 16.67,
      },
    );

    if (mounted && tos != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => TosDetailDesktop(
            tosId: tos.id,
            classId: widget.classId,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(tosProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundSecondary,
      body: DesktopPageScaffold(
        title: 'Create TOS',
        maxWidth: 600,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
          tooltip: 'Back',
        ),
        body: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (state.error != null)
                  FormMessage(
                    message: state.error,
                    severity: MessageSeverity.error,
                  ),
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'TOS Title',
                    hintText: 'e.g., Q1 Periodical Exam',
                    prefixIcon: Icon(Icons.description_outlined,
                        color: AppColors.foregroundSecondary, size: 20),
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Title is required' : null,
                  style: const TextStyle(
                    fontSize: 15,
                    color: AppColors.foregroundPrimary,
                  ),
                ),
                const SizedBox(height: 20),
                DropdownButtonFormField<int>(
                  initialValue: _selectedQuarter,
                  decoration: const InputDecoration(
                    labelText: 'Quarter',
                    prefixIcon: Icon(Icons.calendar_month_outlined,
                        color: AppColors.foregroundSecondary, size: 20),
                    border: OutlineInputBorder(),
                  ),
                  items: [1, 2, 3, 4]
                      .map((q) => DropdownMenuItem(
                            value: q,
                            child: Text('Quarter $q'),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedQuarter = v),
                  validator: (v) => v == null ? 'Select a quarter' : null,
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _totalItemsController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Total Items',
                    hintText: '50',
                    prefixIcon: Icon(Icons.tag_outlined,
                        color: AppColors.foregroundSecondary, size: 20),
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Required';
                    if (int.tryParse(v.trim()) == null) return 'Enter a number';
                    return null;
                  },
                  style: const TextStyle(
                    fontSize: 15,
                    color: AppColors.foregroundPrimary,
                  ),
                ),
                const SizedBox(height: 24),
                ClassificationModeToggle(
                  value: _classificationMode,
                  onChanged: (v) =>
                      setState(() => _classificationMode = v),
                ),
                const SizedBox(height: 24),
                TimeUnitToggle(
                  value: _timeUnit,
                  onChanged: (v) => setState(() => _timeUnit = v),
                ),
                const SizedBox(height: 24),
                if (_pctError != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: FormMessage(
                      message: _pctError,
                      severity: MessageSeverity.error,
                    ),
                  ),
                if (_classificationMode == 'blooms')
                  BloomsRatioSection(
                    rememberingController: _rememberingPctController,
                    understandingController: _understandingPctController,
                    applyingController: _applyingPctController,
                    analyzingController: _analyzingPctController,
                    evaluatingController: _evaluatingPctController,
                    creatingController: _creatingPctController,
                  )
                else
                  DifficultyRatioSection(
                    easyController: _easyPctController,
                    mediumController: _mediumPctController,
                    hardController: _hardPctController,
                  ),
                const SizedBox(height: 32),
                SizedBox(
                  height: 48,
                  child: FilledButton(
                    onPressed: state.isLoading ? null : _handleCreate,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.foregroundPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: state.isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Create TOS',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
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
