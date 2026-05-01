import 'package:flutter/material.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/presentation/pages/desktop/core/platform_detector.dart';
import 'package:likha/presentation/pages/setup/school_code_page.dart';
import 'package:likha/presentation/pages/setup/qr_scan_page.dart';
import 'package:likha/presentation/layouts/desktop/desktop_auth_layout.dart';
import 'package:likha/presentation/layouts/mobile/mobile_auth_layout.dart';

/// Second step: user picks how to connect (code or QR).
class ConnectionMethodPage extends StatelessWidget {
  const ConnectionMethodPage({super.key});

  Widget _buildContent(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Connect to your school',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.foregroundDark,
              letterSpacing: -0.3,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'How would you like to connect?',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: AppColors.foregroundTertiary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          _OptionButton(
            icon: Icons.tag_rounded,
            label: 'I have a school code',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SchoolCodePage()),
            ),
          ),
          const SizedBox(height: 16),
          _OptionButton(
            icon: Icons.qr_code_scanner_rounded,
            label: 'Scan QR code',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const QrScanPage()),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (PlatformDetector.isDesktop) {
      return DesktopAuthLayout(formContent: _buildContent(context));
    }

    return MobileAuthLayout(
      showLogo: false,
      formContent: _buildContent(context),
    );
  }
}

class _OptionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _OptionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.accentCharcoal,
        side: const BorderSide(color: AppColors.borderLight, width: 1.5),
        padding: const EdgeInsets.symmetric(vertical: 18),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20, color: AppColors.foregroundSecondary),
          const SizedBox(width: 10),
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
    );
  }
}
