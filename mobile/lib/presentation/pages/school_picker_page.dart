import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/domain/setup/entities/school_config.dart';
import 'package:likha/presentation/pages/login_page.dart';
import 'package:likha/presentation/pages/shared/widgets/forms/form_message.dart';
import 'package:likha/presentation/providers/school_setup_provider.dart';

/// Reachable only via the deep link: likha://setup?server=cloud
///
/// Allows Play Store reviewers to select the cloud demo server without
/// needing the QR or code flow. Not linked from any visible UI.
class SchoolPickerPage extends ConsumerWidget {
  const SchoolPickerPage({super.key});

  static const _cloudOption = SchoolConfig(
    serverUrl: 'https://likha.app',
    schoolName: 'Likha Cloud (Demo)',
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<SchoolSetupState>(schoolSetupProvider, (_, next) {
      if (next.isConnected) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LoginPage()),
        );
      }
    });

    final state = ref.watch(schoolSetupProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Select Server',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF202020),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (state.error != null)
              FormMessage(
                message: state.error,
                severity: MessageSeverity.error,
              ),
            const SizedBox(height: 8),
            _ServerTile(
              config: _cloudOption,
              isLoading: state.isLoading,
              onTap: () => _connect(ref, _cloudOption),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _connect(WidgetRef ref, SchoolConfig config) async {
    await ref.read(schoolSetupProvider.notifier).connectManual(
          config.serverUrl,
          config.schoolName,
        );
  }
}

class _ServerTile extends StatelessWidget {
  final SchoolConfig config;
  final bool isLoading;
  final VoidCallback onTap;

  const _ServerTile({
    required this.config,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFE0E0E0)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.cloud_outlined, color: Color(0xFF2B2B2B)),
        ),
        title: Text(
          config.schoolName,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
            color: Color(0xFF202020),
          ),
        ),
        subtitle: Text(
          config.serverUrl,
          style: const TextStyle(fontSize: 12, color: Color(0xFF999999)),
        ),
        trailing: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.chevron_right, color: Color(0xFF999999)),
        onTap: isLoading ? null : onTap,
      ),
    );
  }
}
