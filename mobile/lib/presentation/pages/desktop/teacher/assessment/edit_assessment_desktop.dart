import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/core/errors/error_messages.dart';
import 'package:likha/domain/assessments/entities/assessment.dart';
import 'package:likha/domain/assessments/usecases/update_assessment.dart';
import 'package:likha/presentation/pages/desktop/core/desktop_page_scaffold.dart';
import 'package:likha/presentation/widgets/shared/forms/form_message.dart';
import 'package:likha/presentation/providers/teacher_assessment_provider.dart';

class EditAssessmentDesktop extends ConsumerStatefulWidget {
  final Assessment assessment;

  const EditAssessmentDesktop({super.key, required this.assessment});

  @override
  ConsumerState<EditAssessmentDesktop> createState() =>
      _EditAssessmentDesktopState();
}

class _EditAssessmentDesktopState extends ConsumerState<EditAssessmentDesktop> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _timeLimitController;
  late DateTime _openAt;
  late DateTime _closeAt;
  late bool _showResultsImmediately;
  String? _formError;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.assessment.title);
    _descriptionController =
        TextEditingController(text: widget.assessment.description ?? '');
    _timeLimitController = TextEditingController(
        text: widget.assessment.timeLimitMinutes.toString());
    _openAt = widget.assessment.openAt;
    _closeAt = widget.assessment.closeAt;
    _showResultsImmediately = widget.assessment.showResultsImmediately;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _timeLimitController.dispose();
    super.dispose();
  }

  String _formatDateTimeForApi(DateTime dt) {
    final utc = dt.toUtc();
    return '${utc.year.toString().padLeft(4, '0')}-'
        '${utc.month.toString().padLeft(2, '0')}-'
        '${utc.day.toString().padLeft(2, '0')}T'
        '${utc.hour.toString().padLeft(2, '0')}:'
        '${utc.minute.toString().padLeft(2, '0')}:'
        '${utc.second.toString().padLeft(2, '0')}';
  }

  String _formatDateTime(DateTime dt) {
    final month = dt.month.toString().padLeft(2, '0');
    final day = dt.day.toString().padLeft(2, '0');
    final hour = dt.hour > 12
        ? dt.hour - 12
        : dt.hour == 0
            ? 12
            : dt.hour;
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '$month/$day/${dt.year} $hour:$minute $period';
  }

  Future<void> _pickDateTime({
    required DateTime initial,
    required ValueChanged<DateTime> onPicked,
  }) async {
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null || !mounted) return;

    onPicked(
        DateTime(date.year, date.month, date.day, time.hour, time.minute));
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    final timeLimit = int.tryParse(_timeLimitController.text.trim());
    if (timeLimit == null || timeLimit <= 0) {
      setState(() => _formError = 'Please enter a valid time limit');
      return;
    }

    if (_closeAt.isBefore(_openAt)) {
      setState(() => _formError = 'Close date must be after open date');
      return;
    }

    await ref.read(teacherAssessmentProvider.notifier).updateAssessment(
          UpdateAssessmentParams(
            assessmentId: widget.assessment.id,
            title: _titleController.text.trim(),
            description: _descriptionController.text.trim().isEmpty
                ? null
                : _descriptionController.text.trim(),
            timeLimitMinutes: timeLimit,
            openAt: _formatDateTimeForApi(_openAt),
            closeAt: _formatDateTimeForApi(_closeAt),
            showResultsImmediately: _showResultsImmediately,
          ),
        );

    if (!mounted) return;
    final state = ref.read(teacherAssessmentProvider);
    if (state.error == null) {
      Navigator.pop(context, true);
    } else {
      setState(() => _formError = AppErrorMapper.toUserMessage(state.error));
      ref.read(teacherAssessmentProvider.notifier).clearMessages();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(teacherAssessmentProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundSecondary,
      body: DesktopPageScaffold(
        title: 'Edit Assessment',
        maxWidth: 600,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded,
              color: AppColors.foregroundPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          FilledButton.icon(
            onPressed: state.isLoading ? null : _handleSave,
            icon: state.isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.save_rounded, size: 18),
            label: const Text('Save'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.foregroundPrimary,
              foregroundColor: Colors.white,
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
        ],
        body: Form(
          key: _formKey,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderLight, width: 1),
            ),
            padding: const EdgeInsets.all(32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FormMessage(
                  message: _formError,
                  severity: MessageSeverity.error,
                ),
                // Title
                TextFormField(
                  controller: _titleController,
                  decoration: _inputDecoration('Title'),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Title is required';
                    }
                    return null;
                  },
                  enabled: !state.isLoading,
                  onChanged: (_) => setState(() => _formError = null),
                ),
                const SizedBox(height: 20),

                // Description
                TextFormField(
                  controller: _descriptionController,
                  decoration: _inputDecoration('Description (optional)'),
                  maxLines: 3,
                  enabled: !state.isLoading,
                  onChanged: (_) => setState(() => _formError = null),
                ),
                const SizedBox(height: 20),

                // Time Limit
                TextFormField(
                  controller: _timeLimitController,
                  decoration: _inputDecoration('Time Limit (minutes)'),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Time limit is required';
                    }
                    final parsed = int.tryParse(value.trim());
                    if (parsed == null || parsed <= 0) {
                      return 'Enter a valid number of minutes';
                    }
                    return null;
                  },
                  enabled: !state.isLoading,
                  onChanged: (_) => setState(() => _formError = null),
                ),
                const SizedBox(height: 20),

                // Open Date
                _buildDateTimeField(
                  label: 'Open Date',
                  value: _openAt,
                  enabled: !state.isLoading,
                  onTap: () => _pickDateTime(
                    initial: _openAt,
                    onPicked: (dt) => setState(() => _openAt = dt),
                  ),
                ),
                const SizedBox(height: 20),

                // Close Date
                _buildDateTimeField(
                  label: 'Close Date',
                  value: _closeAt,
                  enabled: !state.isLoading,
                  onTap: () => _pickDateTime(
                    initial: _closeAt,
                    onPicked: (dt) => setState(() => _closeAt = dt),
                  ),
                ),
                const SizedBox(height: 24),

                // Show Results Immediately
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.backgroundSecondary,
                    borderRadius: BorderRadius.circular(12),
                    border:
                        Border.all(color: AppColors.borderLight, width: 1),
                  ),
                  child: SwitchListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    title: const Text(
                      'Show results immediately',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: AppColors.foregroundPrimary,
                      ),
                    ),
                    subtitle: const Text(
                      'Students can see results right after submission',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.foregroundTertiary,
                      ),
                    ),
                    value: _showResultsImmediately,
                    activeThumbColor: AppColors.foregroundPrimary,
                    onChanged: state.isLoading
                        ? null
                        : (value) =>
                            setState(() => _showResultsImmediately = value),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDateTimeField({
    required String label,
    required DateTime value,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: _inputDecoration(label),
        child: Row(
          children: [
            Expanded(
              child: Text(
                _formatDateTime(value),
                style: TextStyle(
                  fontSize: 15,
                  color: enabled
                      ? AppColors.foregroundPrimary
                      : AppColors.foregroundTertiary,
                ),
              ),
            ),
            Icon(
              Icons.calendar_today_rounded,
              size: 18,
              color: enabled
                  ? AppColors.foregroundSecondary
                  : AppColors.foregroundTertiary,
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(
        color: AppColors.foregroundSecondary,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.borderLight),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.borderLight),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide:
            const BorderSide(color: AppColors.foregroundPrimary, width: 1.5),
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}
