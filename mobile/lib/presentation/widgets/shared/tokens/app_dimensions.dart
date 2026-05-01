/// Design system spacing and size constants for Likha LMS.
///
/// This file contains all dimensional tokens used across the app:
/// - Border radius values for cards and inputs
/// - Spacing and padding values
/// - Icon sizes and slot dimensions
abstract final class AppDimensions {
  // ============ CARD SHELL RADII ============
  /// Outer radius for Pattern A cards (raised bottom border)
  static const double kCardOuterRadius = 16.0;

  /// Inner radius for Pattern A cards
  static const double kCardInnerRadius = 15.0;

  /// Outer radius for Pattern A-Small cards (teacher list items)
  static const double kCardSmOuterRadius = 12.0;

  /// Inner radius for Pattern A-Small cards
  static const double kCardSmInnerRadius = 11.0;

  // ============ CARD SHELL BORDERS ============
  /// Bottom inset for Pattern A card inner container (creates raised shadow)
  static const double kCardShellBottomInset = 3.5;

  /// Bottom inset for Pattern A-Small card inner container
  static const double kCardSmShellBottomInset = 2.5;

  // ============ CARD SPACING ============
  /// Bottom margin for cards in a list (Pattern A)
  static const double kCardListSpacing = 14.0;

  /// Bottom margin for cards in a list (Pattern A-Small)
  static const double kCardSmListSpacing = 12.0;

  // ============ CARD PADDING ============
  /// Small padding for A-Small cards and compact layouts
  static const double kCardPadSm = 14.0;

  /// Medium padding for standard list card content
  static const double kCardPadMd = 16.0;

  /// Large padding for column-layout cards
  static const double kCardPadLg = 18.0;

  /// Extra-large padding for nav/dashboard cards
  static const double kCardPadXl = 20.0;

  // ============ ICON SLOT ============
  /// Icon slot padding (small)
  static const double kIconSlotPadSm = 8.0;

  /// Icon slot padding (medium)
  static const double kIconSlotPadMd = 10.0;

  /// Icon slot padding (large)
  static const double kIconSlotPadLg = 12.0;

  /// Icon slot border radius (standard)
  static const double kIconSlotRadius = 12.0;

  /// Icon slot border radius (small)
  static const double kIconSlotRadiusSm = 10.0;

  /// Icon size (small)
  static const double kIconSizeSm = 20.0;

  /// Icon size (medium)
  static const double kIconSizeMd = 22.0;

  /// Icon size (large)
  static const double kIconSizeLg = 28.0;

  // ============ DIALOG & PANEL ============
  /// Border radius for StyledDialog
  static const double kDialogRadius = 20.0;

  /// Border radius for info panels and flat-border panels
  static const double kPanelRadius = 12.0;

  // ============ BADGE RADIUS ============
  /// Large badge border radius (outlined pills)
  static const double kBadgeRadiusLg = 12.0;

  /// Medium badge border radius
  static const double kBadgeRadiusMd = 8.0;

  /// Small badge border radius (filled badges)
  static const double kBadgeRadiusSm = 6.0;
}
