import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/presentation/pages/desktop/core/platform_detector.dart';
import 'package:likha/presentation/layouts/desktop/desktop_auth_layout.dart';
import 'package:likha/presentation/layouts/mobile/mobile_auth_layout.dart';
import 'package:likha/presentation/widgets/shared/forms/form_message.dart';
import 'package:likha/presentation/widgets/shared/forms/styled_text_field.dart';
import 'package:likha/presentation/providers/school_setup_provider.dart';
import 'package:likha/presentation/widgets/auth_wrapper.dart';

class SchoolCodePage extends ConsumerStatefulWidget {
  const SchoolCodePage({super.key});

  @override
  ConsumerState<SchoolCodePage> createState() => _SchoolCodePageState();
}

class _SchoolCodePageState extends ConsumerState<SchoolCodePage> {
  final _codeController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _onConnect() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) return;
    await ref.read(schoolSetupProvider.notifier).connectViaCode(code);
  }

  void _restartApp() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AuthWrapper()),
      (route) => false,
    );
  }

  Widget _buildFormContent(SchoolSetupState state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 24),
          const Text(
            'Enter your 6-character school code',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.foregroundDark,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'Ask your school admin for the code.',
            style: TextStyle(fontSize: 13, color: AppColors.foregroundTertiary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          if (state.error != null)
            FormMessage(
              message: state.error,
              severity: MessageSeverity.error,
            ),
          StyledTextField(
            controller: _codeController,
            label: 'School Code',
            icon: Icons.tag_rounded,
            enabled: !state.isLoading,
            keyboardType: TextInputType.text,
            inputFormatters: [
              LengthLimitingTextInputFormatter(6),
              FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
              TextInputFormatter.withFunction((oldValue, newValue) {
                return newValue.copyWith(text: newValue.text.toUpperCase());
              }),
            ],
            onChanged: (_) =>
                ref.read(schoolSetupProvider.notifier).clearError(),
          ),
          const SizedBox(height: 24),
          _ConnectButton(isLoading: state.isLoading, onPressed: _onConnect),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<SchoolSetupState>(schoolSetupProvider, (prev, next) {
      if (prev?.isConnected != true && next.isConnected) _restartApp();
    });

    final state = ref.watch(schoolSetupProvider);

    if (PlatformDetector.isDesktop) {
      return DesktopAuthLayout(formContent: _buildFormContent(state));
    }

    return MobileAuthLayout(
      showLogo: false,
      formContent: _buildFormContent(state),
    );
  }
}

class _ConnectButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onPressed;

  const _ConnectButton({required this.isLoading, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isLoading ? AppColors.borderLight : AppColors.accentCharcoal,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Container(
        margin: const EdgeInsets.fromLTRB(1, 1, 1, 3.5),
        child: ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor:
                isLoading ? AppColors.backgroundTertiary : AppColors.accentCharcoal,
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
                  'Connect',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.3,
                  ),
                ),
        ),
      ),
    );
  }
}
