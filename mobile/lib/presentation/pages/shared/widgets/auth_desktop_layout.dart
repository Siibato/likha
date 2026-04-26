import 'package:flutter/material.dart';
import 'package:likha/core/theme/app_colors.dart';

class AuthDesktopLayout extends StatelessWidget {
  const AuthDesktopLayout({super.key, required this.formContent});

  final Widget formContent;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Left branding panel (50%)
        Expanded(
          child: Container(
            color: AppColors.backgroundTertiary,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'assets/images/likha-logo.png',
                    width: 100,
                    height: 100,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'likha',
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.w700,
                      color: AppColors.foregroundDark,
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Create, learn and grow.',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: AppColors.foregroundTertiary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        // Right form panel (50%)
        Expanded(
          child: Container(
            color: Colors.white,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: formContent,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
