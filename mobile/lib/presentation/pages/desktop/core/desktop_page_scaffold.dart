import 'package:flutter/material.dart';
import 'package:likha/core/theme/app_colors.dart';

class DesktopPageScaffold extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget>? actions;
  final Widget body;
  final double maxWidth;
  final Widget? leading;

  const DesktopPageScaffold({
    super.key,
    required this.title,
    this.subtitle,
    this.actions,
    required this.body,
    this.maxWidth = 1200,
    this.leading,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header bar
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(
              bottom: BorderSide(color: AppColors.borderLight, width: 1),
            ),
          ),
          child: Row(
            children: [
              if (leading != null) ...[
                leading!,
                const SizedBox(width: 16),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: AppColors.foregroundDark,
                        letterSpacing: -0.5,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle!,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.foregroundSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (actions != null) ...actions!,
            ],
          ),
        ),

        // Body
        Expanded(
          child: Container(
            color: AppColors.backgroundSecondary,
            width: double.infinity,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxWidth),
                  child: body,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
