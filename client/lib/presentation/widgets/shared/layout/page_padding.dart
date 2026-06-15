import 'package:flutter/material.dart';

/// Standard page content padding for Likha LMS.
///
/// Prevents diverging raw [EdgeInsets] literals across pages.
/// Default matches the most common page padding: `EdgeInsets.all(24)`.
///
/// Usage:
/// ```dart
/// PagePadding(child: Column(...))
/// PagePadding.list(child: ListView(...))  // fromLTRB(24, 16, 24, 24)
/// PagePadding.horizontal(child: Row(...)) // symmetric(horizontal: 24)
/// ```
class PagePadding extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;

  const PagePadding({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(24),
  });

  const PagePadding.list({
    super.key,
    required this.child,
  }) : padding = const EdgeInsets.fromLTRB(24, 16, 24, 24);

  const PagePadding.horizontal({
    super.key,
    required this.child,
  }) : padding = const EdgeInsets.symmetric(horizontal: 24);

  const PagePadding.top({
    super.key,
    required this.child,
  }) : padding = const EdgeInsets.fromLTRB(24, 24, 24, 0);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: child,
    );
  }
}
