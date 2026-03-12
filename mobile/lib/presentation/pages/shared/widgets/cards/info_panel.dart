import 'package:flutter/material.dart';
import '../tokens/app_decorations.dart';
import '../tokens/app_dimensions.dart';

/// A flat-bordered panel for detail pages and information sections.
///
/// Uses Pattern B design: single container with border and no shadow effect.
/// No tap handler or margin (panels are typically embedded in detail pages).
class InfoPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;

  const InfoPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppDimensions.kCardPadMd),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppDecorations.infoPanel(),
      padding: padding,
      child: child,
    );
  }
}
