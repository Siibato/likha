import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/core/theme/app_colors.dart';

/// Reusable widget that wraps a provider's `ref.listen` snackbar
/// auto-show/clear for states that expose `successMessage` and `error`.
///
/// Usage:
/// ```dart
/// ProviderMessageListener<TosState>(
///   provider: tosProvider,
///   successMessage: (s) => s.successMessage,
///   errorMessage: (s) => s.errorMessage,
///   onClear: () => ref.read(tosProvider.notifier).clearMessages(),
///   intercept: (prev, next) {
///     if (next.successMessage == 'Deleted') { Navigator.pop(context); return true; }
///     return false;
///   },
///   child: Scaffold(...),
/// )
/// ```
class ProviderMessageListener<T> extends ConsumerWidget {
  final ProviderListenable<T> provider;
  final Widget child;
  final String? Function(T state) successMessage;
  final String? Function(T state) errorMessage;
  final VoidCallback onClear;

  /// Return `true` to swallow the message and skip the default snackbar.
  final bool Function(T prev, T next)? intercept;

  const ProviderMessageListener({
    super.key,
    required this.provider,
    required this.child,
    required this.successMessage,
    required this.errorMessage,
    required this.onClear,
    this.intercept,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<T>(provider, (prev, next) {
      if (prev == null || next == null) return;

      if (intercept != null && intercept!(prev, next)) {
        return;
      }

      final s = successMessage(next);
      final ps = successMessage(prev);
      if (s != null && s != ps) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(s),
            backgroundColor: AppColors.semanticSuccess,
          ),
        );
        onClear();
      }

      final e = errorMessage(next);
      final pe = errorMessage(prev);
      if (e != null && e != pe) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e),
            backgroundColor: AppColors.semanticError,
          ),
        );
        onClear();
      }
    });

    return child;
  }
}
