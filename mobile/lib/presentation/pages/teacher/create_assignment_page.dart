import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/domain/assignments/usecases/create_assignment.dart';
import 'package:likha/presentation/pages/teacher/widgets/assignment_due_date_picker.dart';
import 'package:likha/presentation/pages/teacher/widgets/assignment_instructions_field.dart';
import 'package:likha/presentation/pages/teacher/widgets/assignment_points_field.dart';
import 'package:likha/presentation/pages/teacher/widgets/assignment_title_field.dart';
import 'package:likha/presentation/providers/assignment_provider.dart';

class CreateAssignmentPage extends ConsumerStatefulWidget {
  final String classId;

  const CreateAssignmentPage({super.key, required this.classId});

  @override
  ConsumerState<CreateAssignmentPage> createState() =>
      _CreateAssignmentPageState();
}

class _CreateAssignmentPageState extends ConsumerState<CreateAssignmentPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _instructionsController = TextEditingController();
  final _totalPointsController = TextEditingController(text: '100');
  final _maxFileSizeController = TextEditingController(text: '10');
  final _allowedFileTypesController = TextEditingController();
  String _submissionType = 'text_or_file';
  DateTime _dueAt = DateTime.now().add(const Duration(days: 7));

  @override
  void dispose() {
    _titleController.dispose();
    _instructionsController.dispose();
    _totalPointsController.dispose();
    _maxFileSizeController.dispose();
    _allowedFileTypesController.dispose();
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

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _dueAt,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF2B2B2B),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Color(0xFF2B2B2B),
            ),
          ),
          child: child!,
        );
      },
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_dueAt),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF2B2B2B),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Color(0xFF2B2B2B),
            ),
          ),
          child: child!,
        );
      },
    );
    if (time == null || !mounted) return;

    setState(() {
      _dueAt = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> _handleCreate() async {
    if (!_formKey.currentState!.validate()) return;

    final totalPoints = int.tryParse(_totalPointsController.text.trim());
    if (totalPoints == null || totalPoints <= 0 || totalPoints > 1000) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Total points must be between 1 and 1000'),
          backgroundColor: Color(0xFFEF5350),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    String? allowedFileTypes;
    int? maxFileSizeMb;

    if (_submissionType != 'text') {
      final fileTypes = _allowedFileTypesController.text.trim();
      if (fileTypes.isNotEmpty) {
        allowedFileTypes = fileTypes;
      }
      final maxSize = int.tryParse(_maxFileSizeController.text.trim());
      if (maxSize != null && maxSize > 0) {
        maxFileSizeMb = maxSize;
      }
    }

    await ref.read(assignmentProvider.notifier).createAssignment(
          CreateAssignmentParams(
            classId: widget.classId,
            title: _titleController.text.trim(),
            instructions: _instructionsController.text.trim(),
            totalPoints: totalPoints,
            submissionType: _submissionType,
            allowedFileTypes: allowedFileTypes,
            maxFileSizeMb: maxFileSizeMb,
            dueAt: _formatDateTimeForApi(_dueAt),
          ),
        );

    if (!mounted) return;
    final state = ref.read(assignmentProvider);
    if (state.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.error!),
          backgroundColor: const Color(0xFFEF5350),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
      ref.read(assignmentProvider.notifier).clearMessages();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Assignment created as draft'),
          backgroundColor: Color(0xFF4CAF50),
          behavior: SnackBarBehavior.floating,
        ),
      );
      ref.read(assignmentProvider.notifier).clearMessages();
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final assignState = ref.watch(assignmentProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF2B2B2B)),
        title: const Text(
          'Create Assignment',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Color(0xFF2B2B2B),
            letterSpacing: -0.4,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AssignmentTitleField(
                controller: _titleController,
                enabled: !assignState.isLoading,
              ),
              const SizedBox(height: 16),
              AssignmentInstructionsField(
                controller: _instructionsController,
                enabled: !assignState.isLoading,
              ),
              const SizedBox(height: 16),
              AssignmentPointsField(
                controller: _totalPointsController,
                enabled: !assignState.isLoading,
              ),
              const SizedBox(height: 16),
              _SubmissionTypeDropdown(
                value: _submissionType,
                enabled: !assignState.isLoading,
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _submissionType = value);
                  }
                },
              ),
              if (_submissionType != 'text') ...[
                const SizedBox(height: 16),
                _AllowedFileTypesField(
                  controller: _allowedFileTypesController,
                  enabled: !assignState.isLoading,
                ),
                const SizedBox(height: 16),
                _MaxFileSizeField(
                  controller: _maxFileSizeController,
                  enabled: !assignState.isLoading,
                ),
              ],
              const SizedBox(height: 16),
              AssignmentDueDatePicker(
                dueAt: _dueAt,
                onTap: _pickDateTime,
                enabled: !assignState.isLoading,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: assignState.isLoading ? null : _handleCreate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2B2B2B),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: const Color(0xFFE0E0E0),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: assignState.isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Create Assignment',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.2,
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

class _SubmissionTypeDropdown extends StatelessWidget {
  final String value;
  final bool enabled;
  final ValueChanged<String?> onChanged;

  const _SubmissionTypeDropdown({
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: 'Submission Type',
        labelStyle: const TextStyle(
          fontSize: 14,
          color: Color(0xFF999999),
        ),
        prefixIcon: const Icon(
          Icons.upload_file_rounded,
          color: Color(0xFF666666),
          size: 20,
        ),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Color(0xFFE0E0E0),
            width: 1,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Color(0xFFE0E0E0),
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Color(0xFF2B2B2B),
            width: 1.5,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
      items: const [
        DropdownMenuItem(value: 'text', child: Text('Text Only')),
        DropdownMenuItem(value: 'file', child: Text('File Only')),
        DropdownMenuItem(
          value: 'text_or_file',
          child: Text('Text and/or File'),
        ),
      ],
      onChanged: enabled ? onChanged : null,
    );
  }
}

class _AllowedFileTypesField extends StatelessWidget {
  final TextEditingController controller;
  final bool enabled;

  const _AllowedFileTypesField({
    required this.controller,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: Color(0xFF2B2B2B),
      ),
      decoration: InputDecoration(
        labelText: 'Allowed File Types (optional)',
        hintText: 'e.g. pdf,docx,png',
        labelStyle: const TextStyle(
          fontSize: 14,
          color: Color(0xFF999999),
        ),
        hintStyle: const TextStyle(
          fontSize: 14,
          color: Color(0xFFCCCCCC),
        ),
        prefixIcon: const Icon(
          Icons.file_present_rounded,
          color: Color(0xFF666666),
          size: 20,
        ),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Color(0xFFE0E0E0),
            width: 1,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Color(0xFFE0E0E0),
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Color(0xFF2B2B2B),
            width: 1.5,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
    );
  }
}

class _MaxFileSizeField extends StatelessWidget {
  final TextEditingController controller;
  final bool enabled;

  const _MaxFileSizeField({
    required this.controller,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: TextInputType.number,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: Color(0xFF2B2B2B),
      ),
      decoration: InputDecoration(
        labelText: 'Max File Size (MB)',
        labelStyle: const TextStyle(
          fontSize: 14,
          color: Color(0xFF999999),
        ),
        prefixIcon: const Icon(
          Icons.sd_storage_rounded,
          color: Color(0xFF666666),
          size: 20,
        ),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Color(0xFFE0E0E0),
            width: 1,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Color(0xFFE0E0E0),
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Color(0xFF2B2B2B),
            width: 1.5,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
    );
  }
}