import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/core/errors/error_messages.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/presentation/widgets/shared/forms/styled_button.dart';
import 'package:likha/presentation/widgets/shared/forms/styled_dropdown.dart';
import 'package:likha/presentation/widgets/shared/forms/styled_text_field.dart';
import 'package:likha/presentation/pages/desktop/core/desktop_page_scaffold.dart';
import 'package:likha/presentation/widgets/shared/forms/form_message.dart';
import 'package:likha/presentation/providers/admin_provider.dart';

class CreateAccountDesktop extends ConsumerStatefulWidget {
  const CreateAccountDesktop({super.key});

  @override
  ConsumerState<CreateAccountDesktop> createState() =>
      _CreateAccountDesktopState();
}

class _CreateAccountDesktopState extends ConsumerState<CreateAccountDesktop> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _fullNameController = TextEditingController();
  String _selectedRole = 'student';
  bool _isSubmitting = false;
  String? _formError;

  @override
  void dispose() {
    _usernameController.dispose();
    _fullNameController.dispose();
    super.dispose();
  }

  Future<void> _handleCreate() async {
    if (_isSubmitting) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    try {
      await ref.read(adminProvider.notifier).createAccount(
            username: _usernameController.text.trim(),
            fullName: _fullNameController.text.trim(),
            role: _selectedRole,
          );

      if (mounted) {
        final state = ref.read(adminProvider);
        if (state.successMessage != null) {
          ref.read(adminProvider.notifier).clearMessages();
          Navigator.pop(context);
        } else if (state.error != null) {
          ref.read(adminProvider.notifier).clearMessages();
          setState(
              () => _formError = AppErrorMapper.toUserMessage(state.error));
        }
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final adminState = ref.watch(adminProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundSecondary,
      body: DesktopPageScaffold(
        title: 'Create Account',
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          color: AppColors.foregroundPrimary,
          onPressed: () => Navigator.pop(context),
        ),
        body: Center(
          child: Container(
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
                    controller: _usernameController,
                    label: 'Username',
                    icon: Icons.person_outline_rounded,
                    enabled: !adminState.isLoading,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Username is required';
                      }
                      if (value.trim().length < 3) {
                        return 'Username must be at least 3 characters';
                      }
                      return null;
                    },
                    onChanged: (_) => setState(() => _formError = null),
                  ),
                  const SizedBox(height: 16),
                  StyledTextField(
                    controller: _fullNameController,
                    label: 'Full Name',
                    icon: Icons.badge_outlined,
                    enabled: !adminState.isLoading,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Full name is required';
                      }
                      return null;
                    },
                    onChanged: (_) => setState(() => _formError = null),
                  ),
                  const SizedBox(height: 16),
                  StyledDropdown(
                    value: _selectedRole,
                    label: 'Role',
                    icon: Icons.work_outline_rounded,
                    enabled: !adminState.isLoading,
                    items: const [
                      DropdownMenuItem(
                          value: 'student', child: Text('Student')),
                      DropdownMenuItem(
                          value: 'teacher', child: Text('Teacher')),
                      DropdownMenuItem(value: 'admin', child: Text('Admin')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedRole = value;
                          _formError = null;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 32),
                  StyledButton(
                    text: 'Create Account',
                    isLoading: adminState.isLoading,
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
