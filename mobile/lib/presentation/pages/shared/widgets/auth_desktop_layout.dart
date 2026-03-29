import 'package:flutter/material.dart';

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
            color: const Color(0xFFF8F9FA),
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
                      color: Color(0xFF202020),
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Create, learn and grow.',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF999999),
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
