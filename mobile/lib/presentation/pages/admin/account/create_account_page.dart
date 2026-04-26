import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/core/errors/error_messages.dart';
import 'package:likha/core/logging/page_logger.dart';
import 'package:likha/presentation/pages/admin/widgets/styled_text_field.dart';
import 'package:likha/presentation/pages/admin/widgets/styled_dropdown.dart';
import 'package:likha/presentation/pages/admin/widgets/styled_button.dart';
import 'package:likha/presentation/pages/shared/widgets/forms/form_message.dart';
import 'package:likha/presentation/providers/admin_provider.dart';

class CreateAccountPage extends ConsumerStatefulWidget {
  const CreateAccountPage({super.key});

  @override
  ConsumerState<CreateAccountPage> createState() => _CreateAccountPageState();
}

class _CreateAccountPageState extends ConsumerState<CreateAccountPage> {
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

    final username = _usernameController.text.trim();
    final fullName = _fullNameController.text.trim();
    PageLogger.instance.log('_handleCreate START: username=$username, fullName=$fullName, role=$_selectedRole');

    setState(() => _isSubmitting = true);
    try {
      await ref.read(adminProvider.notifier).createAccount(
            username: username,
            fullName: fullName,
            role: _selectedRole,
          );

      if (mounted) {
        final state = ref.read(adminProvider);
        PageLogger.instance.log('After createAccount: success=${state.successMessage}, error=${state.error}');
        if (state.successMessage != null) {
          PageLogger.instance.log('Account creation successful, navigating back');
          ref.read(adminProvider.notifier).clearMessages();
          Navigator.maybePop(context).then((_) {
            ref.read(adminProvider.notifier).loadAccounts();
          });
        } else if (state.error != null) {
          PageLogger.instance.error('Account creation failed with error: ${state.error}');
          ref.read(adminProvider.notifier).clearMessages();
          setState(() => _formError = AppErrorMapper.toUserMessage(state.error));
        } else {
          PageLogger.instance.warn('No success or error message returned');
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: AppColors.foregroundDark,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Create Account',
          style: TextStyle(
            color: AppColors.foregroundDark,
            fontWeight: FontWeight.w700,
            fontSize: 20,
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
              const SizedBox(height: 8),
              FormMessage(
                message: _formError,
                severity: MessageSeverity.error,
              ),
              const SizedBox(height: 16),
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
                  DropdownMenuItem(value: 'student', child: Text('Student')),
                  DropdownMenuItem(value: 'teacher', child: Text('Teacher')),
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
    );
  }
}