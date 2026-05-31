import 'package:flutter/material.dart';

/// Wraps a list of skeleton cards with a pulse (fade) animation.
///
/// Provides a single [AnimationController] that animates opacity from 1.0 to 0.5
/// and back in a 1200ms loop. All child skeleton cards pulse in sync.
///
/// Usage:
/// ```dart
/// SkeletonPulse(
///   child: ListView.builder(
///     itemCount: 6,
///     itemBuilder: (_, __) => const ClassCardSkeleton(),
///   ),
/// )
/// ```
class SkeletonPulse extends StatefulWidget {
  final Widget child;
  final Duration duration;

  const SkeletonPulse({
    required this.child,
    this.duration = const Duration(milliseconds: 1200),
    super.key,
  });

  @override
  State<SkeletonPulse> createState() => _SkeletonPulseState();
}

class _SkeletonPulseState extends State<SkeletonPulse>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    )..repeat();

    _opacity = Tween<double>(begin: 1.0, end: 0.5).animate(_controller);
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: widget.child,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
