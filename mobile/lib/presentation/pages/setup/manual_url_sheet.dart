import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/presentation/pages/login_page.dart';
import 'package:likha/presentation/pages/shared/widgets/forms/form_message.dart';
import 'package:likha/presentation/pages/shared/widgets/forms/styled_text_field.dart';
import 'package:likha/presentation/providers/school_setup_provider.dart';

/// Admin-only bottom sheet for manually entering a server URL.
///
/// Reachable only via the settings icon on [SchoolSetupPage].
/// Pings the URL health endpoint before storing the config.
class ManualUrlSheet extends ConsumerStatefulWidget {
  const ManualUrlSheet({super.key});

  @override
  ConsumerState<ManualUrlSheet> createState() => _ManualUrlSheetState();
}

class _ManualUrlSheetState extends ConsumerState<ManualUrlSheet> {
  final _urlController = TextEditingController();
  final _nameController = TextEditingController();

  @override
  void dispose() {
    _urlController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _onConnect() async {
    await ref.read(schoolSetupProvider.notifier).connectManual(
          _urlController.text,
          _nameController.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<SchoolSetupState>(schoolSetupProvider, (_, next) {
      if (next.isConnected) {
        Navigator.of(context).pop(); // close sheet
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LoginPage()),
        );
      }
    });

    final state = ref.watch(schoolSetupProvider);

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE0E0E0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Manual Setup',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF202020),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Enter the server URL and school name. Only for admins.',
            style: TextStyle(fontSize: 13, color: Color(0xFF999999)),
          ),
          const SizedBox(height: 20),
          FormMessage(
            message: state.error,
            severity: MessageSeverity.error,
          ),
          StyledTextField(
            controller: _urlController,
            label: 'Server URL',
            icon: Icons.link_rounded,
            enabled: !state.isLoading,
            hintText: 'http://192.168.1.1:8080',
            keyboardType: TextInputType.url,
            onChanged: (_) =>
                ref.read(schoolSetupProvider.notifier).clearError(),
          ),
          const SizedBox(height: 16),
          StyledTextField(
            controller: _nameController,
            label: 'School Name',
            icon: Icons.school_outlined,
            enabled: !state.isLoading,
            hintText: 'e.g. Santo Niño Elementary School',
            onChanged: (_) =>
                ref.read(schoolSetupProvider.notifier).clearError(),
          ),
          const SizedBox(height: 24),
          _ConnectButton(isLoading: state.isLoading, onPressed: _onConnect),
        ],
      ),
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
