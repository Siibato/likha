import 'package:flutter/material.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/presentation/pages/desktop/core/desktop_page_scaffold.dart';
import 'package:likha/presentation/widgets/shared/cards/base_card.dart';
import 'package:likha/presentation/widgets/shared/forms/styled_button.dart';
import 'package:likha/presentation/widgets/shared/primitives/info_chip.dart';
import 'package:likha/presentation/widgets/shared/primitives/status_badge.dart';
import 'package:likha/presentation/widgets/shared/primitives/text_block.dart';

// Dev-only design system reference page — remove before production.
class DesignSystemDesktop extends StatelessWidget {
  const DesignSystemDesktop({super.key});

  @override
  Widget build(BuildContext context) {
    return DesktopPageScaffold(
      title: 'Design System',
      subtitle: 'Dev only — remove before production',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _DSSection(
            label: 'CARDS',
            child: Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                _CardTile(
                  variantLabel: 'BASE CARD',
                  description: 'White bg, light gray border',
                  child: BaseCard.base(
                    margin: EdgeInsets.zero,
                    child: TextBlock.titleSubtitle(
                      'Base Card',
                      'Subtle, neutral. Default surface.',
                    ),
                  ),
                ),
                _CardTile(
                  variantLabel: 'DARK CARD',
                  description: 'Charcoal bg, white text',
                  child: BaseCard.dark(
                    margin: EdgeInsets.zero,
                    child: TextBlock.titleSubtitle(
                      'Dark Card',
                      'High contrast, bold presence.',
                      onDark: true,
                    ),
                  ),
                ),
                _CardTile(
                  variantLabel: 'ACCENT CARD',
                  description: 'Amber bg, white text',
                  child: BaseCard.accentFill(
                    margin: EdgeInsets.zero,
                    child: TextBlock.titleSubtitle(
                      'Accent Card',
                      'Highlight and call-to-action.',
                      onDark: true,
                    ),
                  ),
                ),
                _CardTile(
                  variantLabel: 'OUTLINE CARD',
                  description: 'White bg, dark charcoal border',
                  child: BaseCard.outline(
                    margin: EdgeInsets.zero,
                    child: TextBlock.titleSubtitle(
                      'Outline Card',
                      'Structured emphasis, no fill.',
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
          _DSSection(
            label: 'TYPOGRAPHY',
            child: Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                _TypographyTile(
                  label: 'TITLE + SUBTITLE',
                  child: TextBlock.titleSubtitle(
                    'Section Title',
                    'Supporting subtitle text',
                  ),
                ),
                _TypographyTile(
                  label: 'TITLE + PARAGRAPH',
                  child: TextBlock.titleParagraph(
                    'Card Title',
                    'Body paragraph text with comfortable line height for reading longer content.',
                  ),
                ),
                _TypographyTile(
                  label: 'SUBTITLE + PARAGRAPH',
                  child: TextBlock.subtitleParagraph(
                    'Subtitle Label',
                    'Body text following a subtitle. Used in info panels and detail views.',
                  ),
                ),
                _TypographyTile(
                  label: 'TITLE + SUBTITLE + PARAGRAPH',
                  child: TextBlock.titleSubtitleParagraph(
                    'Full Block',
                    'Short subtitle',
                    'A longer paragraph below. Useful for feature cards and onboarding.',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
          const _DSSection(
            label: 'BUTTONS',
            child: Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                _ButtonTile(label: 'DEFAULT', variant: StyledButtonVariant.primary),
                _ButtonTile(label: 'DARK', variant: StyledButtonVariant.dark),
                _ButtonTile(label: 'ACCENT', variant: StyledButtonVariant.accent),
                _ButtonTile(label: 'OUTLINED', variant: StyledButtonVariant.outlined),
                _ButtonTile(label: 'DESTRUCTIVE', variant: StyledButtonVariant.destructive),
              ],
            ),
          ),
          const SizedBox(height: 40),
          _DSSection(
            label: 'BADGES',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _BadgeRow(label: 'OUTLINED'),
                const SizedBox(height: 16),
                const _BadgeRow(label: 'FILLED', filled: true),
                const SizedBox(height: 20),
                const Text(
                  'PALETTE VARIANTS',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.foregroundLight,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 10),
                const _PaletteBadgeRow(),
              ],
            ),
          ),
          const SizedBox(height: 40),
          _DSSection(
            label: 'CHIPS',
            child: Wrap(
              spacing: 24,
              runSpacing: 16,
              children: [
                _ChipTile(label: 'DEFAULT', chip: const InfoChip(icon: Icons.info_outline_rounded, label: 'Label')),
                _ChipTile(label: 'DARK', chip: InfoChip.dark(icon: Icons.class_outlined, label: 'Label')),
                _ChipTile(label: 'ACCENT', chip: InfoChip.accent(icon: Icons.star_rounded, label: 'Label')),
              ],
            ),
          ),
        ],
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
        const SizedBox(height: 16),
        child,
      ],
    );
  }
}

class _CardTile extends StatelessWidget {
  final String variantLabel;
  final String description;
  final Widget child;

  const _CardTile({
    required this.variantLabel,
    required this.description,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 260,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
          const SizedBox(height: 2),
          Text(
            description,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.foregroundTertiary,
            ),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class _TypographyTile extends StatelessWidget {
  final String label;
  final Widget child;

  const _TypographyTile({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 260,
      child: BaseCard.base(
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
      ),
    );
  }
}

class _ButtonTile extends StatelessWidget {
  final String label;
  final StyledButtonVariant variant;

  const _ButtonTile({required this.label, required this.variant});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
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
          const SizedBox(height: 8),
          StyledButton(
            text: 'Button',
            isLoading: false,
            onPressed: () {},
            variant: variant,
          ),
        ],
      ),
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
      crossAxisAlignment: CrossAxisAlignment.center,
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
        Wrap(
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
      ],
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

class _ChipTile extends StatelessWidget {
  final String label;
  final Widget chip;

  const _ChipTile({required this.label, required this.chip});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
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
        const SizedBox(height: 8),
        chip,
      ],
    );
  }
}
