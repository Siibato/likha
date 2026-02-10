import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/domain/assessments/entities/assessment.dart';
import 'package:likha/domain/assessments/usecases/update_assessment.dart';
import 'package:likha/presentation/providers/assessment_provider.dart';
import 'package:likha/presentation/pages/teacher/widgets/assessment_field.dart';
import 'package:likha/presentation/pages/teacher/widgets/date_time_picker_field.dart';

class EditAssessmentPage extends ConsumerStatefulWidget {
  final Assessment assessment;

  const EditAssessmentPage({super.key, required this.assessment});

  @override
  ConsumerState<EditAssessmentPage> createState() => _EditAssessmentPageState();
}

class _EditAssessmentPageState extends ConsumerState<EditAssessmentPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _timeLimitController;
  late DateTime _openAt;
  late DateTime _closeAt;
  late bool _showResultsImmediately;

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

    onPicked(DateTime(date.year, date.month, date.day, time.hour, time.minute));
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    final timeLimit = int.tryParse(_timeLimitController.text.trim());
    if (timeLimit == null || timeLimit <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid time limit'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_closeAt.isBefore(_openAt)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Close date must be after open date'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    await ref.read(assessmentProvider.notifier).updateAssessment(
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
    final state = ref.read(assessmentProvider);
    if (state.error == null) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(assessmentProvider);

    ref.listen<AssessmentState>(assessmentProvider, (prev, next) {
      if (next.error != null && prev?.error != next.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.error!), backgroundColor: Colors.red),
        );
        ref.read(assessmentProvider.notifier).clearMessages();
      }
      if (next.successMessage != null &&
          prev?.successMessage != next.successMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.successMessage!),
            backgroundColor: Colors.green,
          ),
        );
        ref.read(assessmentProvider.notifier).clearMessages();
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Color(0xFF2B2B2B)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Edit Assessment',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF2B2B2B),
            letterSpacing: -0.3,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton(
              onPressed: state.isLoading ? null : _handleSave,
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF2B2B2B),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              child: state.isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFF2B2B2B),
                      ),
                    )
                  : const Text(
                      'Save',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AssessmentField(
                label: 'Title',
                controller: _titleController,
                icon: Icons.title_rounded,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Title is required';
                  }
                  return null;
                },
                enabled: !state.isLoading,
              ),
              const SizedBox(height: 16),
              AssessmentField(
                label: 'Description (optional)',
                controller: _descriptionController,
                icon: Icons.description_outlined,
                maxLines: 3,
                enabled: !state.isLoading,
              ),
              const SizedBox(height: 16),
              AssessmentField(
                label: 'Time Limit (minutes)',
                controller: _timeLimitController,
                icon: Icons.timer_outlined,
                keyboardType: TextInputType.number,
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
              ),
              const SizedBox(height: 16),
              DateTimePickerField(
                label: 'Open Date',
                value: _openAt,
                icon: Icons.calendar_today_rounded,
                enabled: !state.isLoading,
                onTap: () => _pickDateTime(
                  initial: _openAt,
                  onPicked: (dt) => setState(() => _openAt = dt),
                ),
              ),
              const SizedBox(height: 16),
              DateTimePickerField(
                label: 'Close Date',
                value: _closeAt,
                icon: Icons.event_rounded,
                enabled: !state.isLoading,
                onTap: () => _pickDateTime(
                  initial: _closeAt,
                  onPicked: (dt) => setState(() => _closeAt = dt),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
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
                      color: Color(0xFF2B2B2B),
                    ),
                  ),
                  subtitle: const Text(
                    'Students can see results right after submission',
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF999999),
                    ),
                  ),
                  value: _showResultsImmediately,
                  activeColor: const Color(0xFF2B2B2B),
                  onChanged: state.isLoading
                      ? null
                      : (value) => setState(() => _showResultsImmediately = value),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}