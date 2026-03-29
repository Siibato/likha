import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/presentation/pages/desktop/core/platform_detector.dart';
import 'package:likha/presentation/pages/shared/widgets/auth_desktop_layout.dart';
import 'package:likha/presentation/pages/shared/widgets/forms/form_message.dart';
import 'package:likha/presentation/pages/shared/widgets/forms/styled_text_field.dart';
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
              color: Color(0xFF202020),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'Ask your school admin for the code.',
            style: TextStyle(fontSize: 13, color: Color(0xFF999999)),
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
    ref.listen<SchoolSetupState>(schoolSetupProvider, (_, next) {
      if (next.isConnected) _restartApp();
    });

    final state = ref.watch(schoolSetupProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Enter School Code',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF202020),
          ),
        ),
      ),
      body: PlatformDetector.isDesktop
          ? AuthDesktopLayout(formContent: _buildFormContent(state))
          : _buildFormContent(state),
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
        color: isLoading ? const Color(0xFFE0E0E0) : const Color(0xFF2B2B2B),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Container(
        margin: const EdgeInsets.fromLTRB(1, 1, 1, 3.5),
        child: ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor:
                isLoading ? const Color(0xFFF5F5F5) : const Color(0xFF2B2B2B),
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
                    color: Color(0xFF999999),
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
