import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/core/errors/error_messages.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/presentation/pages/admin/widgets/styled_button.dart';
import 'package:likha/presentation/pages/admin/widgets/styled_dropdown.dart';
import 'package:likha/presentation/pages/admin/widgets/styled_text_field.dart';
import 'package:likha/presentation/pages/desktop/core/desktop_page_scaffold.dart';
import 'package:likha/presentation/pages/shared/widgets/forms/form_message.dart';
import 'package:likha/presentation/providers/admin_provider.dart';
import 'package:likha/presentation/providers/class_provider.dart';

class AdminCreateClassDesktop extends ConsumerStatefulWidget {
  const AdminCreateClassDesktop({super.key});

  @override
  ConsumerState<AdminCreateClassDesktop> createState() =>
      _AdminCreateClassDesktopState();
}

class _AdminCreateClassDesktopState
    extends ConsumerState<AdminCreateClassDesktop> {
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
    final selectedTeacher =
        teachers.firstWhere((t) => t.id == _selectedTeacherId!);

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
    final teachers = adminState.accounts.where((u) => u.isTeacher).toList();

    return Scaffold(
      backgroundColor: AppColors.backgroundSecondary,
      body: DesktopPageScaffold(
        title: 'Create Class',
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          color: AppColors.foregroundPrimary,
          onPressed: () => Navigator.pop(context),
        ),
        body: Center(
          child: teachers.isEmpty && !adminState.isLoading
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.person_outline_rounded,
                        size: 64, color: AppColors.borderLight),
                    SizedBox(height: 16),
                    Text(
                      'No teachers available',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.foregroundPrimary,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Create teacher accounts before creating classes',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.foregroundTertiary,
                      ),
                    ),
                  ],
                )
              : Container(
                  constraints: const BoxConstraints(maxWidth: 500),
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FormMessage(
                          message: _formError,
                          severity: MessageSeverity.error,
                        ),
                        if (_formError != null) const SizedBox(height: 16),
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
                          onChanged: (_) =>
                              setState(() => _formError = null),
                        ),
                        const SizedBox(height: 16),
                        StyledTextField(
                          controller: _descriptionController,
                          label: 'Description (Optional)',
                          icon: Icons.description_outlined,
                          enabled: !classState.isLoading,
                          validator: null,
                          onChanged: (_) =>
                              setState(() => _formError = null),
                        ),
                        const SizedBox(height: 16),
                        StyledDropdown<String?>(
                          value: _selectedTeacherId,
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
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.borderLight),
                          ),
                          child: SwitchListTile(
                            value: _isAdvisory,
                            onChanged: classState.isLoading
                                ? null
                                : (value) =>
                                    setState(() => _isAdvisory = value),
                            title: const Text(
                              'Advisory Class',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppColors.foregroundPrimary,
                              ),
                            ),
                            subtitle: const Text(
                              'Enables SF9/SF10 report card access for this teacher',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.foregroundTertiary,
                              ),
                            ),
                            activeThumbColor: AppColors.foregroundPrimary,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 4),
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
      ),
    );
  }
}
