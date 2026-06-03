import 'package:flutter/material.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/presentation/pages/shared/class_section_header.dart';
import 'package:likha/presentation/widgets/shared/cards/base_card.dart';
import 'package:likha/presentation/widgets/shared/forms/styled_button.dart';
import 'package:likha/presentation/widgets/shared/primitives/info_chip.dart';
import 'package:likha/presentation/widgets/shared/primitives/status_badge.dart';
import 'package:likha/presentation/widgets/shared/primitives/text_block.dart';

// Dev-only design system reference page — remove before production.
class DesignSystemPage extends StatelessWidget {
  const DesignSystemPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundSecondary,
      body: SafeArea(
        child: Column(
          children: [
            const ClassSectionHeader(
              title: 'Design System',
              showBackButton: true,
              fontSize: 24,
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _DSSection(
                      label: 'CARDS',
                      child: Column(
                        children: [
                          _CardShowcase(
                            variantLabel: 'BASE',
                            description: 'White bg, light gray border',
                            child: BaseCard.base(
                              margin: EdgeInsets.zero,
                              child: TextBlock.titleSubtitle(
                                'Base Card',
                                'White background with subtle border.',
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          _CardShowcase(
                            variantLabel: 'DARK',
                            description: 'Charcoal bg, white text',
                            child: BaseCard.dark(
                              margin: EdgeInsets.zero,
                              child: TextBlock.titleSubtitle(
                                'Dark Card',
                                'High contrast, strong presence.',
                                onDark: true,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          _CardShowcase(
                            variantLabel: 'ACCENT',
                            description: 'Amber bg, white text',
                            child: BaseCard.accentFill(
                              margin: EdgeInsets.zero,
                              child: TextBlock.titleSubtitle(
                                'Accent Card',
                                'Highlight and call-to-action use.',
                                onDark: true,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          _CardShowcase(
                            variantLabel: 'OUTLINE',
                            description: 'White bg, dark charcoal border',
                            child: BaseCard.outline(
                              margin: EdgeInsets.zero,
                              child: TextBlock.titleSubtitle(
                                'Outline Card',
                                'Structured emphasis without color.',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    _DSSection(
                      label: 'TYPOGRAPHY',
                      child: Column(
                        children: [
                          _TypographyShowcase(
                            label: 'TITLE + SUBTITLE',
                            child: TextBlock.titleSubtitle(
                              'Section Title',
                              'Supporting subtitle text here',
                            ),
                          ),
                          const SizedBox(height: 16),
                          _TypographyShowcase(
                            label: 'TITLE + PARAGRAPH',
                            child: TextBlock.titleParagraph(
                              'Card Title',
                              'This is body paragraph text with a comfortable reading line height and secondary color for long-form content.',
                            ),
                          ),
                          const SizedBox(height: 16),
                          _TypographyShowcase(
                            label: 'SUBTITLE + PARAGRAPH',
                            child: TextBlock.subtitleParagraph(
                              'Subtitle Label',
                              'Body text that follows a subtitle label, used in info panels and detail sections.',
                            ),
                          ),
                          const SizedBox(height: 16),
                          _TypographyShowcase(
                            label: 'TITLE + SUBTITLE + PARAGRAPH',
                            child: TextBlock.titleSubtitleParagraph(
                              'Full Block Title',
                              'Short subtitle line',
                              'A longer paragraph below the subtitle. Useful for feature cards, onboarding screens, or descriptive list items.',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    const _DSSection(
                      label: 'BUTTONS',
                      child: Column(
                        children: [
                          _ButtonRow(label: 'DEFAULT', variant: StyledButtonVariant.primary),
                          SizedBox(height: 12),
                          _ButtonRow(label: 'DARK', variant: StyledButtonVariant.dark),
                          SizedBox(height: 12),
                          _ButtonRow(label: 'ACCENT', variant: StyledButtonVariant.accent),
                          SizedBox(height: 12),
                          _ButtonRow(label: 'OUTLINED', variant: StyledButtonVariant.outlined),
                          SizedBox(height: 12),
                          _ButtonRow(
                            label: 'DESTRUCTIVE',
                            variant: StyledButtonVariant.destructive,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    const _DSSection(
                      label: 'BADGES',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _BadgeRow(label: 'OUTLINED'),
                          SizedBox(height: 12),
                          _BadgeRow(label: 'FILLED', filled: true),
                          SizedBox(height: 16),
                          _DSVariantLabel('PALETTE VARIANTS'),
                          SizedBox(height: 10),
                          _PaletteBadgeRow(),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    _DSSection(
                      label: 'CHIPS',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _ChipRow(label: 'DEFAULT'),
                          const SizedBox(height: 12),
                          _ChipRow(label: 'DARK', variant: InfoChipVariant.dark),
                          const SizedBox(height: 12),
                          _ChipRow(label: 'ACCENT', variant: InfoChipVariant.accent),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DSSection extends StatelessWidget {
  final String label;
  final Widget child;

  const _DSSection({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppColors.foregroundTertiary,
            letterSpacing: 1.4,
          ),
        ),
        const SizedBox(height: 14),
        child,
      ],
    );
  }
}

class _CardShowcase extends StatelessWidget {
  final String variantLabel;
  final String description;
  final Widget child;

  const _CardShowcase({
    required this.variantLabel,
    required this.description,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              variantLabel,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: AppColors.foregroundLight,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              description,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.foregroundTertiary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

class _TypographyShowcase extends StatelessWidget {
  final String label;
  final Widget child;

  const _TypographyShowcase({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return BaseCard.base(
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.foregroundLight,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _ButtonRow extends StatelessWidget {
  final String label;
  final StyledButtonVariant variant;

  const _ButtonRow({required this.label, required this.variant});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.foregroundLight,
              letterSpacing: 1.2,
            ),
          ),
        ),
        Expanded(
          child: StyledButton(
            text: 'Button',
            isLoading: false,
            onPressed: () {},
            variant: variant,
          ),
        ),
      ],
    );
  }
}

class _BadgeRow extends StatelessWidget {
  final String label;
  final bool filled;

  const _BadgeRow({required this.label, this.filled = false});

  @override
  Widget build(BuildContext context) {
    final variant = filled ? BadgeVariant.filled : BadgeVariant.outlined;

    return Row(
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.foregroundLight,
              letterSpacing: 1.2,
            ),
          ),
        ),
        Expanded(
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              StatusBadge(
                label: 'Default',
                color: AppColors.foregroundSecondary,
                variant: variant,
              ),
              StatusBadge(
                label: 'Charcoal',
                color: AppColors.accentCharcoal,
                icon: Icons.circle,
                variant: variant,
              ),
              StatusBadge(
                label: 'Amber',
                color: AppColors.accentAmber,
                icon: Icons.star_rounded,
                variant: variant,
              ),
              StatusBadge(
                label: 'Success',
                color: AppColors.semanticSuccess,
                icon: Icons.check_circle_outline_rounded,
                variant: variant,
              ),
              StatusBadge(
                label: 'Error',
                color: AppColors.semanticError,
                icon: Icons.error_outline_rounded,
                variant: variant,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DSVariantLabel extends StatelessWidget {
  final String text;
  const _DSVariantLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w600,
        color: AppColors.foregroundLight,
        letterSpacing: 1.1,
      ),
    );
  }
}

class _PaletteBadgeRow extends StatelessWidget {
  const _PaletteBadgeRow();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        StatusBadge.base(label: 'Base'),
        StatusBadge.dark(label: 'Dark', icon: Icons.circle),
        StatusBadge.accent(label: 'Accent', icon: Icons.star_rounded),
        StatusBadge.outline(label: 'Outline'),
      ],
    );
  }
}

class _ChipRow extends StatelessWidget {
  final String label;
  final InfoChipVariant variant;

  const _ChipRow({
    required this.label,
    this.variant = InfoChipVariant.defaultStyle,
  });

  @override
  Widget build(BuildContext context) {
    Widget chip;
    switch (variant) {
      case InfoChipVariant.dark:
        chip = InfoChip.dark(icon: Icons.class_outlined, label: 'Label');
        break;
      case InfoChipVariant.accent:
        chip = InfoChip.accent(icon: Icons.star_rounded, label: 'Label');
        break;
      case InfoChipVariant.defaultStyle:
        chip = const InfoChip(icon: Icons.info_outline_rounded, label: 'Label');
        break;
    }

    return Row(
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.foregroundLight,
              letterSpacing: 1.2,
            ),
          ),
        ),
        chip,
      ],
    );
  }
}
