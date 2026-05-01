import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/presentation/pages/setup/qr_scanner_widget.dart';
import 'package:likha/presentation/pages/desktop/core/platform_detector.dart';
import 'package:likha/presentation/widgets/shared/forms/form_message.dart';
import 'package:likha/presentation/providers/school_setup_provider.dart';
import 'package:likha/presentation/widgets/auth_wrapper.dart';

class QrScanPage extends ConsumerStatefulWidget {
  const QrScanPage({super.key});

  @override
  ConsumerState<QrScanPage> createState() => _QrScanPageState();
}

class _QrScanPageState extends ConsumerState<QrScanPage> {
  bool _qrScanned = false;

  void _onDetect(String rawValue) {
    if (_qrScanned) return;
    if (rawValue.isEmpty) return;
    _qrScanned = true;
    ref.read(schoolSetupProvider.notifier).connectViaQr(rawValue);
  }

  void _restartApp() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AuthWrapper()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<SchoolSetupState>(schoolSetupProvider, (prev, next) {
      if (prev?.isConnected != true && next.isConnected) _restartApp();
      // Allow re-scanning if there was an error
      if (next.error != null) setState(() => _qrScanned = false);
    });

    final state = ref.watch(schoolSetupProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Scan QR Code',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.foregroundDark,
          ),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: PlatformDetector.isDesktop ? 520 : double.infinity,
          ),
          child: Column(
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
                child: state.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : Padding(
                        padding: const EdgeInsets.all(24),
                        child: QrScannerWidget(onDetect: _onDetect),
                      ),
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(24, 0, 24, 32),
                child: Text(
                  'Point the camera at the QR code provided by your school admin.',
                  style: TextStyle(fontSize: 13, color: AppColors.foregroundTertiary),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
