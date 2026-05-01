import 'package:flutter/material.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/core/services/school_setup_service.dart';
import 'package:likha/injection_container.dart' as di;
import 'package:likha/presentation/pages/desktop/core/platform_detector.dart';
import 'package:likha/presentation/pages/setup/school_setup_page.dart';
import 'package:likha/presentation/pages/shared/widgets/auth_desktop_layout.dart';
import 'package:likha/presentation/widgets/shared/forms/styled_text_field.dart';
import 'package:likha/presentation/providers/auth_provider.dart';
import 'package:likha/presentation/widgets/shared/dialogs/styled_dialog.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  String? _formError;
  String? _schoolName;

  @override
  void initState() {
    super.initState();
    _loadSchoolName();
  }

  Future<void> _loadSchoolName() async {
    final config = await di.sl<SchoolSetupService>().getSchoolConfig();
    if (mounted) {
      setState(() => _schoolName = config?.schoolName);
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _handleContinue() async {
    if (!_formKey.currentState!.validate()) return;

    await ref
        .read(authProvider.notifier)
        .checkUsernameForLogin(_usernameController.text.trim());

    if (!mounted) return;
    final state = ref.read(authProvider);

    if (state.error != null) {
      setState(() => _formError = state.error);
    }
  }

  Future<void> _showDisconnectModal() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => const _ChangeSchoolDialog(),
    );

    if (confirmed == true && mounted) {
      await di.sl<SchoolSetupService>().clearSchoolConfig();
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const SchoolSetupPage()),
        );
      }
    }
  }

  Widget _buildSchoolIndicator() {
    if (_schoolName == null) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.backgroundDisabled,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(Icons.school_outlined, size: 16, color: AppColors.foregroundTertiary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _schoolName!,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.foregroundTertiary,
              ),
            ),
          ),
          GestureDetector(
            onTap: _showDisconnectModal,
            child: const Text(
              'Not your school?',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.foregroundTertiary,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormBody(bool isLoading) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Logo
            Image.asset(
              'assets/images/likha-logo.png',
              width: 120,
              height: 120,
            ),
            const SizedBox(height: 32),
            const Text(
              'Welcome to Likha',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: AppColors.foregroundDark,
                letterSpacing: -0.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Enter your username to continue',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: AppColors.foregroundTertiary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            _buildSchoolIndicator(),
            if (_formError != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.semanticErrorBackground,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.semanticErrorDark,
                    width: 1,
                  ),
                ),
                child: Text(
                  _formError!,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.semanticErrorDark,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            const SizedBox(height: 16),
            StyledTextField(
              controller: _usernameController,
              label: 'Username',
              icon: Icons.person_outline_rounded,
              enabled: !isLoading,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter your username';
                }
                return null;
              },
              onChanged: (_) => setState(() => _formError = null),
            ),
            const SizedBox(height: 24),

            // Continue button
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
                  onPressed: isLoading ? null : _handleContinue,
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
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: AppColors.foregroundTertiary,
                          ),
                        )
                      : const Text(
                          'Continue',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.3,
                          ),
                        ),
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

    return Scaffold(
      backgroundColor: Colors.white,
      body: PlatformDetector.isDesktop
          ? AuthDesktopLayout(formContent: _buildFormBody(authState.isLoading))
          : SafeArea(
              child: Center(child: _buildFormBody(authState.isLoading)),
            ),
    );
  }
}

/// Dialog to confirm changing the school connection.
class _ChangeSchoolDialog extends StatelessWidget {
  const _ChangeSchoolDialog();

  @override
  Widget build(BuildContext context) {
    return StyledDialog(
      title: 'Change school?',
      content: const Text(
        'This will remove your current school connection. '
        'You will need to scan a QR code or enter a school code to reconnect.',
      ),
      actions: [
        StyledDialogAction(
          label: 'Cancel',
          onPressed: () => Navigator.pop(context, false),
        ),
        StyledDialogAction(
          label: 'Change School',
          isPrimary: true,
          isDestructive: true,
          onPressed: () => Navigator.pop(context, true),
        ),
      ],
    );
  }
}
