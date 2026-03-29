import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:likha/presentation/pages/login_page.dart';
import 'package:likha/presentation/pages/setup/manual_url_sheet.dart';
import 'package:likha/presentation/pages/shared/widgets/forms/form_message.dart';
import 'package:likha/presentation/pages/shared/widgets/forms/styled_text_field.dart';
import 'package:likha/presentation/providers/school_setup_provider.dart';

class SchoolSetupPage extends ConsumerStatefulWidget {
  const SchoolSetupPage({super.key});

  @override
  ConsumerState<SchoolSetupPage> createState() => _SchoolSetupPageState();
}

class _SchoolSetupPageState extends ConsumerState<SchoolSetupPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _codeController = TextEditingController();
  bool _qrScanned = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  void _onQrDetect(BarcodeCapture capture) {
    if (_qrScanned) return;
    final barcode = capture.barcodes.firstOrNull;
    if (barcode?.rawValue == null) return;
    _qrScanned = true;
    ref
        .read(schoolSetupProvider.notifier)
        .connectViaQr(barcode!.rawValue!);
  }

  Future<void> _onConnectCode() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) return;
    await ref.read(schoolSetupProvider.notifier).connectViaCode(code);
  }

  void _navigateToLogin() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<SchoolSetupState>(schoolSetupProvider, (_, next) {
      if (next.isConnected) _navigateToLogin();
    });

    final state = ref.watch(schoolSetupProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Connect to School',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF202020),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Color(0xFF999999)),
            tooltip: 'Manual setup',
            onPressed: () => _showManualSheet(context),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF2B2B2B),
          unselectedLabelColor: const Color(0xFF999999),
          indicatorColor: const Color(0xFF2B2B2B),
          tabs: const [
            Tab(text: 'Scan QR'),
            Tab(text: 'Enter Code'),
          ],
        ),
      ),
      body: Column(
        children: [
          if (state.error != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: FormMessage(
                message: state.error,
                severity: MessageSeverity.error,
              ),
            ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _QrTab(
                  isLoading: state.isLoading,
                  onDetect: _onQrDetect,
                  onReset: () => setState(() => _qrScanned = false),
                ),
                _CodeTab(
                  controller: _codeController,
                  isLoading: state.isLoading,
                  onConnect: _onConnectCode,
                  onChanged: (_) =>
                      ref.read(schoolSetupProvider.notifier).clearError(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showManualSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const ManualUrlSheet(),
    );
  }
}

// ---------------------------------------------------------------------------
// QR tab
// ---------------------------------------------------------------------------

class _QrTab extends StatelessWidget {
  final bool isLoading;
  final void Function(BarcodeCapture) onDetect;
  final VoidCallback onReset;

  const _QrTab({
    required this.isLoading,
    required this.onDetect,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: MobileScanner(
                onDetect: onDetect,
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
          child: Text(
            'Point the camera at the QR code provided by your school admin.',
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF999999),
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Code tab
// ---------------------------------------------------------------------------

class _CodeTab extends StatelessWidget {
  final TextEditingController controller;
  final bool isLoading;
  final VoidCallback onConnect;
  final ValueChanged<String> onChanged;

  const _CodeTab({
    required this.controller,
    required this.isLoading,
    required this.onConnect,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
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
          StyledTextField(
            controller: controller,
            label: 'School Code',
            icon: Icons.tag_rounded,
            enabled: !isLoading,
            keyboardType: TextInputType.text,
            inputFormatters: [
              LengthLimitingTextInputFormatter(6),
              FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
            ],
            onChanged: onChanged,
          ),
          const SizedBox(height: 24),
          _ConnectButton(isLoading: isLoading, onPressed: onConnect),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared button
// ---------------------------------------------------------------------------

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
