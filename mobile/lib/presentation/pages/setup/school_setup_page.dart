import 'package:flutter/material.dart';
import 'package:likha/presentation/pages/desktop/core/platform_detector.dart';
import 'package:likha/presentation/pages/setup/connection_method_page.dart';
import 'package:likha/presentation/pages/shared/widgets/auth_desktop_layout.dart';

/// First-launch welcome page.
///
/// On desktop/web: uses [AuthDesktopLayout] (left branding + right form).
/// On mobile: centered single-column layout.
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
              color: Color(0xFF202020),
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
              color: Color(0xFF999999),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF2B2B2B),
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
                  backgroundColor: const Color(0xFF2B2B2B),
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
    return Scaffold(
      backgroundColor: Colors.white,
      body: PlatformDetector.isDesktop
          ? AuthDesktopLayout(formContent: _buildContent(context))
          : SafeArea(child: Center(child: _buildContent(context))),
    );
  }
}
