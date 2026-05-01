import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/core/errors/error_messages.dart';
import 'package:likha/domain/classes/entities/class_entity.dart';
import 'package:likha/presentation/widgets/shared/forms/styled_button.dart';
import 'package:likha/presentation/widgets/shared/forms/styled_dropdown.dart';
import 'package:likha/presentation/widgets/shared/forms/styled_text_field.dart';
import 'package:likha/presentation/widgets/shared/forms/form_message.dart';
import 'package:likha/presentation/providers/admin_provider.dart';
import 'package:likha/presentation/providers/class_provider.dart';

class AdminEditClassPage extends ConsumerStatefulWidget {
  final ClassEntity classEntity;

  const AdminEditClassPage({super.key, required this.classEntity});

  @override
  ConsumerState<AdminEditClassPage> createState() => _AdminEditClassPageState();
}

class _AdminEditClassPageState extends ConsumerState<AdminEditClassPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late String? _selectedTeacherId;
  late bool _isAdvisory;
  String? _formError;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.classEntity.title);
    _descriptionController =
        TextEditingController(text: widget.classEntity.description ?? '');
    _selectedTeacherId = widget.classEntity.teacherId;
    _isAdvisory = widget.classEntity.isAdvisory;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(adminProvider.notifier).loadAccounts();
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();
    final cls = widget.classEntity;

    // Only send changed fields
    final newTitle = title != cls.title ? title : null;
    final newDescription =
        description != (cls.description ?? '') ? description : null;
    final newTeacherId =
        _selectedTeacherId != cls.teacherId ? _selectedTeacherId : null;
    final newIsAdvisory = _isAdvisory != cls.isAdvisory ? _isAdvisory : null;

    if (newTitle == null &&
        newDescription == null &&
        newTeacherId == null &&
        newIsAdvisory == null) {
      Navigator.pop(context);
      return;
    }

    await ref.read(classProvider.notifier).updateClass(
          classId: cls.id,
          title: newTitle,
          description: newDescription,
          teacherId: newTeacherId,
          isAdvisory: newIsAdvisory,
        );

    if (mounted) {
      final state = ref.read(classProvider);
      if (state.successMessage != null) {
        Navigator.pop(context);
      } else if (state.error != null) {
        setState(() => _formError = AppErrorMapper.toUserMessage(state.error));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final adminState = ref.watch(adminProvider);
    final classState = ref.watch(classProvider);

    final teachers = adminState.accounts.where((u) => u.isTeacher).toList();

    return Scaffold(
      backgroundColor: AppColors.backgroundSecondary,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Edit Class',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.accentCharcoal,
            letterSpacing: -0.4,
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.accentCharcoal),
      ),
      body: SingleChildScrollView(
        child: Padding(
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
                StyledTextField(
                  controller: _titleController,
                  label: 'Class Title',
                  icon: Icons.class_outlined,
                  enabled: !classState.isLoading,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Class title is required';
                    }
                    return null;
                  },
                  onChanged: (_) => setState(() => _formError = null),
                ),
                const SizedBox(height: 16),
                StyledTextField(
                  controller: _descriptionController,
                  label: 'Description (Optional)',
                  icon: Icons.description_outlined,
                  enabled: !classState.isLoading,
                  validator: null,
                  onChanged: (_) => setState(() => _formError = null),
                ),
                const SizedBox(height: 16),
                StyledDropdown<String?>(
                  value: teachers.any((t) => t.id == _selectedTeacherId)
                      ? _selectedTeacherId
                      : null,
                  label: 'Assign Teacher',
                  icon: Icons.person_outline_rounded,
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      enabled: false,
                      child: Text('Select a teacher'),
                    ),
                    ...teachers.map(
                      (teacher) => DropdownMenuItem<String?>(
                        value: teacher.id,
                        child: Text(
                          '${teacher.fullName} (@${teacher.username})',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedTeacherId = value;
                      _formError = null;
                    });
                  },
                  enabled: !classState.isLoading,
                ),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.backgroundPrimary,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: SwitchListTile(
                    value: _isAdvisory,
                    onChanged: classState.isLoading
                        ? null
                        : (value) => setState(() => _isAdvisory = value),
                    title: const Text(
                      'Advisory Class',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.accentCharcoal,
                      ),
                    ),
                    subtitle: const Text(
                      'Enables SF9/SF10 report card access for this teacher',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.foregroundTertiary,
                      ),
                    ),
                    activeColor: AppColors.accentCharcoal,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                StyledButton(
                  text: 'Save Changes',
                  isLoading: classState.isLoading,
                  onPressed: _handleSave,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
