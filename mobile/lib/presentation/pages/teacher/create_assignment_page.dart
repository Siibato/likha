import 'dart:convert';

import 'package:fleather/fleather.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/core/errors/error_messages.dart';
import 'package:likha/domain/assignments/usecases/create_assignment.dart';
import 'package:likha/presentation/pages/teacher/widgets/shared_due_date_time_picker.dart';
import 'package:likha/presentation/pages/teacher/widgets/assignment_instructions_field.dart';
import 'package:likha/presentation/pages/teacher/widgets/assignment_points_field.dart';
import 'package:likha/presentation/pages/teacher/widgets/assignment_title_field.dart';
import 'package:likha/presentation/pages/teacher/widgets/file_type_picker_sheet.dart';
import 'package:likha/presentation/pages/shared/widgets/forms/form_message.dart';
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
  late final FleatherController _instructionsController;
  final _totalPointsController = TextEditingController(text: '100');
  final _maxFileSizeController = TextEditingController(text: '10');
  Set<String> _selectedFileTypes = {};
  bool _allowsTextSubmission = true;
  bool _allowsFileSubmission = false;
  DateTime _dueAt = DateTime.now().add(const Duration(days: 7));
  bool _isPublished = true;
  int? _quarter;
  String? _component = 'performance_task';
  bool _noSubmissionRequired = false;
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
    _maxFileSizeController.dispose();
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

  /// Calculate category selection state: 0 = none, 1 = partial, 2 = all
  // COMMENTED OUT: Only called by _toggleCategory which is also commented out
  // int _getCategorySelectionState(FileTypeCategory category) {
  //   final selectedCount = category.types
  //       .where((type) => _selectedFileTypes.contains(type))
  //       .length;
  //   if (selectedCount == 0) return 0;
  //   if (selectedCount == category.types.length) return 2;
  //   return 1;
  // }

  /// Toggle all types in a category
  // COMMENTED OUT: Unused - no callers found
  // void _toggleCategory(FileTypeCategory category) {
  //   setState(() {
  //     final state = _getCategorySelectionState(category);
  //     if (state == 2) {
  //       // All selected → deselect all
  //       for (final type in category.types) {
  //         _selectedFileTypes.remove(type);
  //       }
  //     } else {
  //       // None or partial → select all
  //       for (final type in category.types) {
  //         _selectedFileTypes.add(type);
  //       }
  //     }
  //   });
  // }


  Future<void> _showFileTypesPicker() async {
    final result = await showModalBottomSheet<Set<String>>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => FileTypePickerSheet(initialSelection: _selectedFileTypes),
    );
    if (result != null) {
      setState(() => _selectedFileTypes = result);
    }
  }

  Future<void> _handleCreate() async {
    if (!_formKey.currentState!.validate()) return;

    final totalPoints = int.tryParse(_totalPointsController.text.trim());
    if (totalPoints == null || totalPoints <= 0 || totalPoints > 1000) {
      setState(() => _formError = 'Total points must be between 1 and 1000');
      return;
    }

    String? allowedFileTypes;
    int? maxFileSizeMb;

    if (_allowsFileSubmission) {
      if (_selectedFileTypes.isNotEmpty) {
        allowedFileTypes = _selectedFileTypes.join(',');
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
            instructions: jsonEncode(_instructionsController.document.toJson()),
            totalPoints: totalPoints,
            allowsTextSubmission: _allowsTextSubmission,
            allowsFileSubmission: _allowsFileSubmission,
            allowedFileTypes: allowedFileTypes,
            maxFileSizeMb: maxFileSizeMb,
            dueAt: _formatDateTimeForApi(_dueAt),
            isPublished: _isPublished,
            gradingPeriodNumber: _quarter,
            component: _component,
            noSubmissionRequired: _noSubmissionRequired,
          ),
        );

    if (!mounted) return;
    final state = ref.read(assignmentProvider);
    if (state.error != null) {
      setState(() => _formError = AppErrorMapper.toUserMessage(state.error));
      ref.read(assignmentProvider.notifier).clearMessages();
    } else {
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
              FormMessage(
                message: _formError,
                severity: MessageSeverity.error,
              ),
              const SizedBox(height: 16),
              AssignmentTitleField(
                controller: _titleController,
                enabled: !assignState.isLoading,
                onChanged: (_) => setState(() => _formError = null),
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Submission Options',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF999999),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  CheckboxListTile(
                    title: const Text('Allow text submission'),
                    value: _allowsTextSubmission,
                    enabled: !assignState.isLoading,
                    onChanged: (value) {
                      setState(() => _allowsTextSubmission = value ?? false);
                    },
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  CheckboxListTile(
                    title: const Text('Allow file submission'),
                    value: _allowsFileSubmission,
                    enabled: !assignState.isLoading,
                    onChanged: (value) {
                      setState(() => _allowsFileSubmission = value ?? false);
                    },
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ],
              ),
              if (_allowsFileSubmission) ...[
                const SizedBox(height: 16),
                _AllowedFileTypesSelector(
                  selectedTypes: _selectedFileTypes,
                  enabled: !assignState.isLoading,
                  onTap: () => _showFileTypesPicker(),
                ),
                const SizedBox(height: 16),
                _MaxFileSizeField(
                  controller: _maxFileSizeController,
                  enabled: !assignState.isLoading,
                ),
              ],
              const SizedBox(height: 16),
              SharedDueDateTimePicker(
                label: 'Due Date',
                dateTime: _dueAt,
                icon: Icons.event_rounded,
                enabled: !assignState.isLoading,
                onChanged: (dt) => setState(() => _dueAt = dt),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int?>(
                initialValue: _quarter,
                decoration: InputDecoration(
                  labelText: 'Quarter (for grading)',
                  labelStyle: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF999999),
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
                items: [
                  const DropdownMenuItem(value: null, child: Text('None')),
                  ...List.generate(4, (i) => DropdownMenuItem(value: i + 1, child: Text('Quarter ${i + 1}'))),
                ],
                onChanged: assignState.isLoading
                    ? null
                    : (v) => setState(() => _quarter = v),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String?>(
                initialValue: _component,
                decoration: InputDecoration(
                  labelText: 'Grade Component',
                  labelStyle: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF999999),
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
                  DropdownMenuItem(value: null, child: Text('None')),
                  DropdownMenuItem(value: 'written_work', child: Text('Written Work')),
                  DropdownMenuItem(value: 'performance_task', child: Text('Performance Task')),
                  DropdownMenuItem(value: 'quarterly_assessment', child: Text('Quarterly Assessment')),
                ],
                onChanged: assignState.isLoading
                    ? null
                    : (v) => setState(() => _component = v),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFE0E0E0),
                    width: 1,
                  ),
                ),
                child: SwitchListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  title: const Text(
                    'No submission required',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2B2B2B),
                    ),
                  ),
                  subtitle: const Text(
                    'Grade item only \u2014 no student submission expected',
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF999999),
                    ),
                  ),
                  value: _noSubmissionRequired,
                  activeThumbColor: const Color(0xFF2B2B2B),
                  onChanged: assignState.isLoading
                      ? null
                      : (v) => setState(() => _noSubmissionRequired = v),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFE0E0E0),
                    width: 1,
                  ),
                ),
                child: SwitchListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  title: const Text(
                    'Publish immediately',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2B2B2B),
                    ),
                  ),
                  subtitle: const Text(
                    'Students can see this assignment right away',
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF999999),
                    ),
                  ),
                  value: _isPublished,
                  activeThumbColor: const Color(0xFF2B2B2B),
                  onChanged: assignState.isLoading
                      ? null
                      : (value) => setState(() => _isPublished = value),
                ),
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


class _AllowedFileTypesSelector extends StatelessWidget {
  final Set<String> selectedTypes;
  final bool enabled;
  final VoidCallback onTap;

  const _AllowedFileTypesSelector({
    required this.selectedTypes,
    required this.enabled,
    required this.onTap,
  });

  String _getDisplayText() {
    if (selectedTypes.isEmpty) {
      return 'Any file type';
    }
    if (selectedTypes.length <= 3) {
      return selectedTypes.join(', ');
    }
    return '${selectedTypes.length} types selected';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Allowed File Types (optional)',
          style: TextStyle(
            fontSize: 14,
            color: Color(0xFF999999),
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: enabled ? onTap : null,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFE0E0E0),
                width: 1,
              ),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.file_present_rounded,
                  color: Color(0xFF666666),
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _getDisplayText(),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: selectedTypes.isEmpty
                          ? const Color(0xFFCCCCCC)
                          : const Color(0xFF2B2B2B),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
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
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
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