import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/domain/tos/entities/tos_entity.dart';
import 'package:likha/presentation/pages/desktop/core/desktop_page_scaffold.dart';
import 'package:likha/presentation/pages/shared/widgets/forms/form_message.dart';
import 'package:likha/presentation/pages/teacher/widgets/blooms_ratio_section.dart';
import 'package:likha/presentation/pages/teacher/widgets/classification_mode_toggle.dart';
import 'package:likha/presentation/pages/teacher/widgets/difficulty_ratio_section.dart';
import 'package:likha/presentation/pages/teacher/widgets/time_unit_toggle.dart';
import 'package:likha/presentation/providers/tos_provider.dart';

class EditTosDesktop extends ConsumerStatefulWidget {
  final TableOfSpecifications tos;

  const EditTosDesktop({super.key, required this.tos});

  @override
  ConsumerState<EditTosDesktop> createState() => _EditTosDesktopState();
}

class _EditTosDesktopState extends ConsumerState<EditTosDesktop> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _totalItemsController;
  late final TextEditingController _easyPctController;
  late final TextEditingController _mediumPctController;
  late final TextEditingController _hardPctController;
  late final TextEditingController _rememberingPctController;
  late final TextEditingController _understandingPctController;
  late final TextEditingController _applyingPctController;
  late final TextEditingController _analyzingPctController;
  late final TextEditingController _evaluatingPctController;
  late final TextEditingController _creatingPctController;
  late int _selectedQuarter;
  late String _classificationMode;
  late String _timeUnit;
  String? _pctError;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.tos.title);
    _totalItemsController =
        TextEditingController(text: '${widget.tos.totalItems}');
    _easyPctController =
        TextEditingController(text: '${widget.tos.easyPercentage}');
    _mediumPctController =
        TextEditingController(text: '${widget.tos.mediumPercentage}');
    _hardPctController =
        TextEditingController(text: '${widget.tos.hardPercentage}');
    _rememberingPctController =
        TextEditingController(text: '${widget.tos.rememberingPercentage}');
    _understandingPctController =
        TextEditingController(text: '${widget.tos.understandingPercentage}');
    _applyingPctController =
        TextEditingController(text: '${widget.tos.applyingPercentage}');
    _analyzingPctController =
        TextEditingController(text: '${widget.tos.analyzingPercentage}');
    _evaluatingPctController =
        TextEditingController(text: '${widget.tos.evaluatingPercentage}');
    _creatingPctController =
        TextEditingController(text: '${widget.tos.creatingPercentage}');
    _selectedQuarter = widget.tos.gradingPeriodNumber;
    _classificationMode = widget.tos.classificationMode;
    _timeUnit = widget.tos.timeUnit;
  }

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

  Future<void> _handleSave() async {
    final pctError = _validatePercentages();
    if (pctError != null) {
      setState(() => _pctError = pctError);
      return;
    }
    setState(() => _pctError = null);
    if (!_formKey.currentState!.validate()) return;

    await ref.read(tosProvider.notifier).updateTos(
      widget.tos.id,
      {
        'title': _titleController.text.trim(),
        'quarter': _selectedQuarter,
        'classification_mode': _classificationMode,
        'total_items': int.tryParse(_totalItemsController.text.trim()) ?? 50,
        'time_unit': _timeUnit,
        'easy_percentage':
            double.tryParse(_easyPctController.text.trim()) ?? 50.0,
        'medium_percentage':
            double.tryParse(_mediumPctController.text.trim()) ?? 30.0,
        'hard_percentage':
            double.tryParse(_hardPctController.text.trim()) ?? 20.0,
        'remembering_percentage':
            double.tryParse(_rememberingPctController.text.trim()) ?? 16.67,
        'understanding_percentage':
            double.tryParse(_understandingPctController.text.trim()) ?? 16.67,
        'applying_percentage':
            double.tryParse(_applyingPctController.text.trim()) ?? 16.67,
        'analyzing_percentage':
            double.tryParse(_analyzingPctController.text.trim()) ?? 16.67,
        'evaluating_percentage':
            double.tryParse(_evaluatingPctController.text.trim()) ?? 16.67,
        'creating_percentage':
            double.tryParse(_creatingPctController.text.trim()) ?? 16.67,
      },
    );

    if (mounted) {
      final state = ref.read(tosProvider);
      if (state.successMessage != null) {
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(tosProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundSecondary,
      body: DesktopPageScaffold(
        title: 'Edit TOS',
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
                  onChanged: (v) {
                    if (v != null) setState(() => _selectedQuarter = v);
                  },
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _totalItemsController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Total Items',
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
                    onPressed: state.isLoading ? null : _handleSave,
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
                            'Save Changes',
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
