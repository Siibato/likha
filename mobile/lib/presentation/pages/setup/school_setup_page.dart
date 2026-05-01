import 'package:flutter/material.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/presentation/pages/desktop/core/platform_detector.dart';
import 'package:likha/presentation/pages/setup/connection_method_page.dart';
import 'package:likha/presentation/layouts/desktop/desktop_auth_layout.dart';
import 'package:likha/presentation/layouts/mobile/mobile_auth_layout.dart';

/// First-launch welcome page.
///
/// On desktop/web: uses [DesktopAuthLayout] (left branding + right form).
/// On mobile: uses [MobileAuthLayout] centered single-column layout.
class SchoolSetupPage extends StatelessWidget {
  const SchoolSetupPage({super.key});

  Widget _buildContent(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!PlatformDetector.isDesktop) ...[
            Image.asset(
              'assets/images/likha-logo.png',
              width: 120,
              height: 120,
            ),
            const SizedBox(height: 32),
          ],
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
            'Your offline classroom, anywhere.',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: AppColors.foregroundTertiary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),
          Container(
            decoration: BoxDecoration(
              color: AppColors.accentCharcoal,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Container(
              margin: const EdgeInsets.fromLTRB(1, 1, 1, 3.5),
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const ConnectionMethodPage(),
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentCharcoal,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(13),
                  ),
                ),
                child: const Text(
                  'Get Started',
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
