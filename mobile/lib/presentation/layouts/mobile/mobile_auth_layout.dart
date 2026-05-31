import 'package:flutter/material.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/presentation/widgets/shared/tokens/app_text_styles.dart';

/// Mobile auth wrapper for login / activation pages.
///
/// Centres the [formContent] vertically with a constrained max width,
/// consistent background, and a small logo header.
class MobileAuthLayout extends StatelessWidget {
  final Widget formContent;
  final bool showLogo;

  const MobileAuthLayout({
    super.key,
    required this.formContent,
    this.showLogo = true,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (showLogo) ...[
                    Center(
                      child: Image.asset(
                        'assets/images/likha-logo.png',
                        width: 64,
                        height: 64,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Center(
                      child: Text(
                        'likha',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: AppColors.foregroundDark,
                          letterSpacing: -0.8,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Center(
                      child: Text(
                        'Create, learn and grow.',
                        style: AppTextStyles.mobilePageSubtitle,
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                  formContent,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
