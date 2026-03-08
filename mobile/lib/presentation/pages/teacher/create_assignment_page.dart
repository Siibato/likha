import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/core/constants/file_types.dart';
import 'package:likha/core/utils/snackbar_utils.dart';
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
  Set<String> _selectedFileTypes = {};
  String _submissionType = 'text_or_file';
  DateTime _dueAt = DateTime.now().add(const Duration(days: 7));
  bool _isPublished = true;

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
  int _getCategorySelectionState(FileTypeCategory category) {
    final selectedCount = category.types
        .where((type) => _selectedFileTypes.contains(type))
        .length;
    if (selectedCount == 0) return 0;
    if (selectedCount == category.types.length) return 2;
    return 1;
  }

  /// Toggle all types in a category
  void _toggleCategory(FileTypeCategory category) {
    setState(() {
      final state = _getCategorySelectionState(category);
      if (state == 2) {
        // All selected → deselect all
        for (final type in category.types) {
          _selectedFileTypes.remove(type);
        }
      } else {
        // None or partial → select all
        for (final type in category.types) {
          _selectedFileTypes.add(type);
        }
      }
    });
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

  Future<void> _showFileTypesPicker() async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (context, setLocalState) {
          // Local temporary selection for instant UI updates
          Set<String> tempSelection = Set.from(_selectedFileTypes);

          /// Get category selection state based on tempSelection
          int getCategoryState(FileTypeCategory category) {
            final selectedCount = category.types
                .where((type) => tempSelection.contains(type))
                .length;
            if (selectedCount == 0) return 0;
            if (selectedCount == category.types.length) return 2;
            return 1;
          }

          /// Toggle category in temp selection
          void toggleCategoryLocal(FileTypeCategory category) {
            final state = getCategoryState(category);
            if (state == 2) {
              // All selected → deselect all
              for (final type in category.types) {
                tempSelection.remove(type);
              }
            } else {
              // None or partial → select all
              for (final type in category.types) {
                tempSelection.add(type);
              }
            }
            // Update local UI
            setLocalState(() {});
            // Persist to parent immediately
            setState(() => _selectedFileTypes = Set.from(tempSelection));
          }

          return DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.6,
            maxChildSize: 0.85,
            minChildSize: 0.4,
            builder: (context, scrollController) => Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Allowed File Types',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF2B2B2B),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      children: [
                        for (final category in kFileTypeCategories) ...[
                          Container(
                            margin: const EdgeInsets.only(top: 16, bottom: 12),
                            decoration: BoxDecoration(
                              color: getCategoryState(category) > 0
                                  ? const Color(0xFF2B2B2B).withOpacity(0.05)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: getCategoryState(category) > 0
                                    ? const Color(0xFF2B2B2B).withOpacity(0.2)
                                    : Colors.transparent,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              child: Row(
                                children: [
                                  Checkbox(
                                    value: getCategoryState(category) == 2
                                        ? true
                                        : getCategoryState(category) == 1
                                            ? null
                                            : false,
                                    tristate: true,
                                    onChanged: (_) =>
                                        toggleCategoryLocal(category),
                                    activeColor: const Color(0xFF2B2B2B),
                                    materialTapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      category.label,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: getCategoryState(category) > 0
                                            ? const Color(0xFF2B2B2B)
                                            : const Color(0xFF666666),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final type in category.types)
                                FilterChip(
                                  label: Text(type),
                                  selected: tempSelection.contains(type),
                                  onSelected: (selected) {
                                    setLocalState(() {
                                      if (selected) {
                                        tempSelection.add(type);
                                      } else {
                                        tempSelection.remove(type);
                                      }
                                    });
                                    // Persist to parent immediately
                                    setState(() =>
                                        _selectedFileTypes =
                                            Set.from(tempSelection));
                                  },
                                  selectedColor: const Color(0xFF2B2B2B),
                                  labelStyle: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: tempSelection.contains(type)
                                        ? Colors.white
                                        : const Color(0xFF2B2B2B),
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                    side: BorderSide(
                                      color: tempSelection.contains(type)
                                          ? const Color(0xFF2B2B2B)
                                          : const Color(0xFFE0E0E0),
                                    ),
                                  ),
                                  backgroundColor: Colors.white,
                                  showCheckmark: false,
                                ),
                            ],
                          ),
                          if (category != kFileTypeCategories.last)
                            const SizedBox(height: 8),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2B2B2B),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Done',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _handleCreate() async {
    if (!_formKey.currentState!.validate()) return;

    final totalPoints = int.tryParse(_totalPointsController.text.trim());
    if (totalPoints == null || totalPoints <= 0 || totalPoints > 1000) {
      context.showErrorSnackBar('Total points must be between 1 and 1000');
      return;
    }

    String? allowedFileTypes;
    int? maxFileSizeMb;

    if (_submissionType != 'text') {
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
            instructions: _instructionsController.text.trim(),
            totalPoints: totalPoints,
            submissionType: _submissionType,
            allowedFileTypes: allowedFileTypes,
            maxFileSizeMb: maxFileSizeMb,
            dueAt: _formatDateTimeForApi(_dueAt),
            isPublished: _isPublished,
          ),
        );

    if (!mounted) return;
    final state = ref.read(assignmentProvider);
    if (state.error != null) {
      context.showErrorSnackBar(state.error!);
      ref.read(assignmentProvider.notifier).clearMessages();
    } else {
      final message = _isPublished
          ? 'Assignment created and published'
          : 'Assignment saved as draft';
      context.showSuccessSnackBar(message);
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
              AssignmentDueDatePicker(
                dueAt: _dueAt,
                onTap: _pickDateTime,
                enabled: !assignState.isLoading,
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
                  activeColor: const Color(0xFF2B2B2B),
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
        Text(
          'Allowed File Types (optional)',
          style: const TextStyle(
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