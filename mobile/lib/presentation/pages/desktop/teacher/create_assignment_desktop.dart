import 'dart:convert';

import 'package:fleather/fleather.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/core/errors/error_messages.dart';
import 'package:likha/domain/assignments/usecases/create_assignment.dart';
import 'package:likha/presentation/pages/desktop/core/desktop_page_scaffold.dart';
import 'package:likha/presentation/pages/shared/widgets/forms/form_message.dart';
import 'package:likha/presentation/pages/shared/widgets/forms/rich_text_field.dart';
import 'package:likha/presentation/providers/assignment_provider.dart';

class CreateAssignmentDesktop extends ConsumerStatefulWidget {
  final String classId;

  const CreateAssignmentDesktop({super.key, required this.classId});

  @override
  ConsumerState<CreateAssignmentDesktop> createState() =>
      _CreateAssignmentDesktopState();
}

class _CreateAssignmentDesktopState
    extends ConsumerState<CreateAssignmentDesktop> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  late final FleatherController _instructionsController;
  final _totalPointsController = TextEditingController(text: '100');
  String _submissionType = 'text_or_file';
  DateTime _dueAt = DateTime.now().add(const Duration(days: 7));
  int? _quarter;
  String? _component;
  bool _isPublished = true;
  String? _formError;

  @override
  void initState() {
    super.initState();
    _instructionsController = FleatherController();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _instructionsController.dispose();
    _totalPointsController.dispose();
    super.dispose();
  }

  String _displayDateTime(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final hour = dt.hour > 12
        ? dt.hour - 12
        : dt.hour == 0
            ? 12
            : dt.hour;
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '${months[dt.month - 1]} ${dt.day.toString().padLeft(2, '0')}, ${dt.year}  $hour:$minute $period';
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

  Future<void> _pickDueDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _dueAt,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: Color(0xFF2B2B2B),
            onPrimary: Colors.white,
            surface: Colors.white,
            onSurface: Color(0xFF2B2B2B),
          ),
        ),
        child: child!,
      ),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_dueAt),
      initialEntryMode: TimePickerEntryMode.input,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: Color(0xFF2B2B2B),
            onPrimary: Colors.white,
            surface: Colors.white,
            onSurface: Color(0xFF2B2B2B),
            secondary: Color(0xFF2B2B2B),
            tertiary: Color(0xFF2B2B2B),
            onTertiary: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (time == null || !mounted) return;

    setState(() {
      _dueAt = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _formError = null);

    final params = CreateAssignmentParams(
      classId: widget.classId,
      title: _titleController.text.trim(),
      instructions: jsonEncode(_instructionsController.document.toJson()),
      totalPoints: int.parse(_totalPointsController.text.trim()),
      submissionType: _submissionType,
      dueAt: _formatDateTimeForApi(_dueAt),
      isPublished: _isPublished,
      quarter: _quarter,
      component: _component,
    );

    await ref.read(assignmentProvider.notifier).createAssignment(params);
  }

  String _componentLabel(String value) {
    switch (value) {
      case 'ww':
        return 'Written Work';
      case 'pt':
        return 'Performance Task';
      case 'qa':
        return 'Quarterly Assessment';
      default:
        return value;
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(assignmentProvider);

    ref.listen<AssignmentState>(assignmentProvider, (prev, next) {
      if (next.successMessage != null &&
          prev?.successMessage != next.successMessage) {
        ref.read(assignmentProvider.notifier).clearMessages();
        if (next.successMessage == 'Assignment created') {
          Navigator.pop(context, true);
        }
      }
      if (next.error != null && prev?.error != next.error) {
        setState(() => _formError = AppErrorMapper.toUserMessage(next.error));
        ref.read(assignmentProvider.notifier).clearMessages();
      }
    });

    return Scaffold(
      backgroundColor: AppColors.backgroundSecondary,
      body: DesktopPageScaffold(
        title: 'Create Assignment',
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'Back',
        ),
        body: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 600),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    FormMessage(
                      message: _formError,
                      severity: MessageSeverity.error,
                    ),
                    if (_formError != null) const SizedBox(height: 12),

                    // Title
                    TextFormField(
                      controller: _titleController,
                      decoration: _inputDecoration('Title'),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Title is required' : null,
                    ),
                    const SizedBox(height: 16),

                    // Instructions
                    RichTextField(
                      controller: _instructionsController,
                      label: 'Instructions',
                      icon: Icons.description_outlined,
                      enabled: true,
                      minHeight: 120,
                    ),
                    const SizedBox(height: 16),

                    // Total Points
                    TextFormField(
                      controller: _totalPointsController,
                      decoration: _inputDecoration('Total Points'),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Points required';
                        final pts = int.tryParse(v.trim());
                        if (pts == null || pts <= 0) return 'Must be greater than 0';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Submission Type
                    DropdownButtonFormField<String>(
                      value: _submissionType,
                      decoration: _inputDecoration('Submission Type'),
                      items: const [
                        DropdownMenuItem(value: 'text_or_file', child: Text('Text or File')),
                        DropdownMenuItem(value: 'text', child: Text('Text Only')),
                        DropdownMenuItem(value: 'file', child: Text('File Only')),
                      ],
                      onChanged: (v) {
                        if (v != null) setState(() => _submissionType = v);
                      },
                    ),
                    const SizedBox(height: 16),

                    // Due Date
                    _buildDateTimeField(
                      label: 'Due Date',
                      dateTime: _dueAt,
                      onPick: _pickDueDate,
                    ),
                    const SizedBox(height: 16),

                    // Quarter
                    DropdownButtonFormField<int?>(
                      value: _quarter,
                      decoration: _inputDecoration('Quarter (optional)'),
                      items: const [
                        DropdownMenuItem(value: null, child: Text('None')),
                        DropdownMenuItem(value: 1, child: Text('Quarter 1')),
                        DropdownMenuItem(value: 2, child: Text('Quarter 2')),
                        DropdownMenuItem(value: 3, child: Text('Quarter 3')),
                        DropdownMenuItem(value: 4, child: Text('Quarter 4')),
                      ],
                      onChanged: (v) => setState(() => _quarter = v),
                    ),
                    const SizedBox(height: 16),

                    // Grade Component
                    DropdownButtonFormField<String?>(
                      value: _component,
                      decoration: _inputDecoration('Grade Component (optional)'),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('None')),
                        ...['ww', 'pt', 'qa'].map(
                          (c) => DropdownMenuItem(
                            value: c,
                            child: Text(_componentLabel(c)),
                          ),
                        ),
                      ],
                      onChanged: (v) => setState(() => _component = v),
                    ),
                    const SizedBox(height: 16),

                    // Publish toggle
                    SwitchListTile(
                      value: _isPublished,
                      onChanged: (v) => setState(() => _isPublished = v),
                      title: const Text(
                        'Publish Immediately',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.foregroundDark,
                        ),
                      ),
                      subtitle: Text(
                        _isPublished
                            ? 'Students will see this assignment right away'
                            : 'Save as draft, publish later',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.foregroundTertiary,
                        ),
                      ),
                      contentPadding: EdgeInsets.zero,
                      activeColor: AppColors.foregroundPrimary,
                    ),
                    const SizedBox(height: 24),

                    // Save button
                    SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: state.isLoading ? null : _handleSave,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.foregroundPrimary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: state.isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : const Text(
                                'Create Assignment',
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
        ),
      ),
    );
  }

  Widget _buildDateTimeField({
    required String label,
    required DateTime dateTime,
    required VoidCallback onPick,
  }) {
    return InkWell(
      onTap: onPick,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: _inputDecoration(label).copyWith(
          suffixIcon: const Icon(
            Icons.arrow_drop_down_rounded,
            color: Color(0xFF666666),
          ),
        ),
        child: Text(
          _displayDateTime(dateTime),
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.foregroundDark,
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(
        fontSize: 14,
        color: AppColors.foregroundSecondary,
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
        borderSide: const BorderSide(color: AppColors.foregroundPrimary, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}
