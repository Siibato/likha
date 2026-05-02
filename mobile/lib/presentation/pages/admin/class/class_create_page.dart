import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/core/errors/error_messages.dart';
import 'package:likha/presentation/widgets/shared/forms/styled_button.dart';
import 'package:likha/presentation/widgets/shared/forms/styled_dropdown.dart';
import 'package:likha/presentation/widgets/shared/forms/styled_text_field.dart';
import 'package:likha/presentation/widgets/shared/forms/form_message.dart';
import 'package:likha/presentation/providers/admin_provider.dart';
import 'package:likha/presentation/providers/class_provider.dart';

class AdminCreateClassPage extends ConsumerStatefulWidget {
  const AdminCreateClassPage({super.key});

  @override
  ConsumerState<AdminCreateClassPage> createState() => _AdminCreateClassPageState();
}

class _AdminCreateClassPageState extends ConsumerState<AdminCreateClassPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  String? _selectedTeacherId;
  bool _isAdvisory = false;
  String? _formError;

  @override
  void initState() {
    super.initState();
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

  Future<void> _handleCreate() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedTeacherId == null || _selectedTeacherId!.isEmpty) {
      setState(() => _formError = 'Please select a teacher');
      return;
    }

    final adminState = ref.read(adminProvider);
    final teachers = adminState.accounts.where((u) => u.isTeacher).toList();
    final selectedTeacher = teachers.firstWhere((t) => t.id == _selectedTeacherId!);

    await ref.read(classProvider.notifier).createClass(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          teacherId: _selectedTeacherId,
          teacherUsername: selectedTeacher.username,
          teacherFullName: selectedTeacher.fullName,
          isAdvisory: _isAdvisory,
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

    // Filter teachers (include pending activation status)
    final teachers = adminState.accounts.where((u) => u.isTeacher).toList();

    // If no teachers, show empty state
    if (teachers.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.backgroundSecondary,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: const Text(
            'Create Class',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.accentCharcoal,
              letterSpacing: -0.4,
            ),
          ),
          iconTheme: const IconThemeData(color: AppColors.accentCharcoal),
        ),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.person_outline_rounded, size: 64, color: AppColors.foregroundLight),
                SizedBox(height: 16),
                Text(
                  'No teachers available',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.accentCharcoal,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Create teacher accounts before creating classes',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.foregroundTertiary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundSecondary,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Create Class',
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
                  value: _selectedTeacherId,
                  label: 'Assign Teacher',
                  icon: Icons.person_outline_rounded,
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('Select a teacher'),
                      enabled: false,
                    ),
                    ...teachers
                        .map(
                          (teacher) => DropdownMenuItem<String?>(
                            value: teacher.id,
                            child: Text(
                              '${teacher.fullName} (@${teacher.username})',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
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
                    activeThumbColor: AppColors.accentCharcoal,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                StyledButton(
                  text: 'Create Class',
                  isLoading: classState.isLoading,
                  onPressed: _handleCreate,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
