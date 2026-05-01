import 'package:flutter/material.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'app_loader.dart';
import 'app_error_state.dart';

/// A widget that handles the isLoading / error / empty / content state pattern
/// repeated on every list page in Likha LMS.
///
/// Replaces the nested ternary chains:
/// ```dart
/// state.isLoading && state.items.isEmpty
///     ? const Center(child: CircularProgressIndicator(...))
///     : state.error != null
///         ? Center(child: Column(...))
///         : state.items.isEmpty
///             ? emptyState
///             : content
/// ```
///
/// With pull-to-refresh when [onRefresh] is provided:
/// ```dart
/// ContentStateBuilder(
///   isLoading: state.isLoading && state.items.isEmpty,
///   error: state.error,
///   isEmpty: state.items.isEmpty,
///   onRetry: () => ref.read(provider.notifier).load(),
///   onRefresh: () => ref.read(provider.notifier).load(),
///   emptyState: const AppEmptyState.assessments(),
///   child: ListView.builder(...),
/// )
/// ```
class ContentStateBuilder extends StatelessWidget {
  final bool isLoading;
  final String? error;
  final bool isEmpty;
  final Widget child;
  final Widget? emptyState;
  final VoidCallback? onRetry;
  final Future<void> Function()? onRefresh;
  final String errorMessage;

  const ContentStateBuilder({
    super.key,
    required this.isLoading,
    required this.isEmpty,
    required this.child,
    this.error,
    this.emptyState,
    this.onRetry,
    this.onRefresh,
    this.errorMessage = 'Something went wrong',
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const AppLoader();
    }

    if (error != null) {
      return AppErrorState(
        message: errorMessage,
        onRetry: onRetry,
      );
    }

    if (isEmpty && emptyState != null) {
      return emptyState!;
    }

    if (onRefresh != null) {
      return RefreshIndicator(
        onRefresh: onRefresh!,
        color: AppColors.accentCharcoal,
        child: child,
      );
    }

    return child;
  }
}
