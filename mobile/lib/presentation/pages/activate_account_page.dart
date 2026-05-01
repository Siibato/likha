import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/core/errors/error_messages.dart';
import 'package:likha/presentation/pages/desktop/core/platform_detector.dart';
import 'package:likha/presentation/pages/shared/widgets/auth_desktop_layout.dart';
import 'package:likha/presentation/widgets/shared/forms/form_message.dart';
import 'package:likha/presentation/providers/auth_provider.dart';

class ActivateAccountPage extends ConsumerStatefulWidget {
  const ActivateAccountPage({super.key});

  @override
  ConsumerState<ActivateAccountPage> createState() =>
      _ActivateAccountPageState();
}

class _ActivateAccountPageState extends ConsumerState<ActivateAccountPage> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  String? _formError;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleActivate() async {
    if (!_formKey.currentState!.validate()) return;

    final authState = ref.read(authProvider);
    final username = authState.pendingActivationUsername;
    if (username == null) return;

    await ref.read(authProvider.notifier).activateAccount(
          username: username,
          password: _passwordController.text,
          confirmPassword: _confirmPasswordController.text,
        );

    if (mounted) {
      final state = ref.read(authProvider);
      if (state.error != null) {
        setState(() => _formError = AppErrorMapper.toUserMessage(state.error));
      }
    }
  }

  Widget _buildFormBody(String fullName, bool isLoading) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FormMessage(
              message: _formError,
              severity: MessageSeverity.error,
            ),
            if (_formError != null) const SizedBox(height: 12),
            Container(
              width: 96,
              height: 96,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.backgroundTertiary,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.lock_open_rounded,
                size: 56,
                color: AppColors.accentCharcoal,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Welcome, $fullName!',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: AppColors.foregroundDark,
                letterSpacing: -0.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Create a password to activate your account',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: AppColors.foregroundTertiary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),

            // Password field
            Container(
              decoration: BoxDecoration(
                color: AppColors.borderLight,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Container(
                margin: const EdgeInsets.fromLTRB(1, 1, 1, 3),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: AppColors.foregroundDark,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Password',
                    labelStyle: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: AppColors.foregroundTertiary,
                    ),
                    prefixIcon: const Icon(
                      Icons.lock_outline_rounded,
                      color: AppColors.foregroundTertiary,
                      size: 22,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: AppColors.foregroundTertiary,
                        size: 22,
                      ),
                      onPressed: () {
                        setState(() => _obscurePassword = !_obscurePassword);
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(13),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(13),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(13),
                      borderSide: BorderSide(
                        color: AppColors.accentCharcoal,
                        width: 1.5,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a password';
                    }
                    if (value.length < 8) {
                      return 'Password must be at least 8 characters';
                    }
                    return null;
                  },
                  textInputAction: TextInputAction.next,
                  enabled: !isLoading,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Confirm password field
            Container(
              decoration: BoxDecoration(
                color: AppColors.borderLight,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Container(
                margin: const EdgeInsets.fromLTRB(1, 1, 1, 3),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirm,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: AppColors.foregroundDark,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Confirm Password',
                    labelStyle: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: AppColors.foregroundTertiary,
                    ),
                    prefixIcon: const Icon(
                      Icons.lock_outline_rounded,
                      color: AppColors.foregroundTertiary,
                      size: 22,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirm
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: AppColors.foregroundTertiary,
                        size: 22,
                      ),
                      onPressed: () {
                        setState(() => _obscureConfirm = !_obscureConfirm);
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(13),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(13),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(13),
                      borderSide: BorderSide(
                        color: AppColors.accentCharcoal,
                        width: 1.5,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please confirm your password';
                    }
                    if (value != _passwordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _handleActivate(),
                  enabled: !isLoading,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Activate button
            Container(
              decoration: BoxDecoration(
                color: isLoading
                    ? AppColors.borderLight
                    : AppColors.accentCharcoal,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Container(
                margin: const EdgeInsets.fromLTRB(1, 1, 1, 3.5),
                child: ElevatedButton(
                  onPressed: isLoading ? null : _handleActivate,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isLoading
                        ? AppColors.backgroundDisabled
                        : AppColors.accentCharcoal,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(13),
                    ),
                  ),
                  child: isLoading
                      ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: AppColors.foregroundTertiary,
                          ),
                        )
                      : Text(
                          'Activate Account',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.foregroundLight,
                            letterSpacing: -0.3,
                          ),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Back button
            TextButton(
              onPressed: isLoading
                  ? null
                  : () {
                      ref.read(authProvider.notifier).clearPendingActivation();
                    },
              style: TextButton.styleFrom(
                foregroundColor: AppColors.accentCharcoal,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text(
                'Back to Login',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final fullName = authState.pendingActivationFullName ?? 'User';

    return Scaffold(
      backgroundColor: Colors.white,
      body: PlatformDetector.isDesktop
          ? AuthDesktopLayout(
              formContent: _buildFormBody(fullName, authState.isLoading),
            )
          : SafeArea(
              child: Center(
                child: _buildFormBody(fullName, authState.isLoading),
              ),
            ),
    );
  }
}
