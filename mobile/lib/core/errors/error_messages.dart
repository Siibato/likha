import 'package:likha/core/errors/failures.dart';

class AppErrorMapper {
  /// Type-safe error mapping from Failure objects using ErrorCategory
  static String? fromFailure(Failure failure) {
    switch (failure.category) {
      case ErrorCategory.network:
        return null; // Suppress — expected in offline-first app
      case ErrorCategory.unauthorized:
        return 'Session expired. Please log in again.';
      case ErrorCategory.forbidden:
        return "You don't have permission for this action.";
      case ErrorCategory.notFound:
        return 'Resource not found.';
      case ErrorCategory.serverError:
      case ErrorCategory.cache:
      case ErrorCategory.unknown:
        // Check if the message is already user-friendly before using generic error
        if (_isUserFriendlyMessage(failure.message)) {
          return failure.message;
        }
        return 'Something went wrong. Try again later.';
      case ErrorCategory.validation:
        return failure.message; // Already user-friendly
    }
  }

  /// Check if a message is user-friendly (short, no technical jargon)
  static bool _isUserFriendlyMessage(String? message) {
    if (message == null) return false;
    
    final lower = message.toLowerCase();
    const technicalTerms = [
      'exception',
      'null',
      'stack',
      'trace',
      'sqlite',
      'constraint',
      'failed:',
      'error:',
      "type '",
    ];
    
    final isTechnical = technicalTerms.any((term) => lower.contains(term));
    // Short messages without technical terms are considered user-friendly
    return message.length < 100 && !isTechnical;
  }

  static String? toUserMessage(String? rawError) {
    if (rawError == null) return null;

    final lower = rawError.toLowerCase();

    // Connectivity errors are expected in an offline-first app â suppress entirely
    if (lower.contains('internet') ||
        lower.contains('unreachable') ||
        lower.contains('network') ||
        lower.contains('connection') ||
        lower.contains('socket') ||
        lower.contains('timeout')) {
      return null;
    }

    // Check if the error message looks user-friendly FIRST (short, no technical jargon)
    // These are messages already crafted by the notifier and should pass through
    const technicalTerms = [
      'exception',
      'null',
      'stack',
      'trace',
      'sqlite',
      'constraint',
      'failed:',
      'error:',
      "type '",
    ];

    final isTechnical = technicalTerms.any((term) => lower.contains(term));
    if (rawError.length < 80 && !isTechnical) {
      return rawError;
    }

    // Authentication-specific error handling
    if (lower.contains('username does not exist')) {
      return 'Username does not exist';
    }
    
    if (lower.contains('invalid password')) {
      return 'Password is incorrect';
    }
    
    if (lower.contains('account locked')) {
      return 'Account is locked. Contact an administrator.';
    }
    
    if (lower.contains('activation required')) {
      return 'Account requires activation';
    }

    if (lower.contains('unauthorized') || lower.contains('401')) {
      return 'Session expired. Please log in again.';
    }
    if (lower.contains('forbidden') || lower.contains('403')) {
      return "You don't have permission for this action.";
    }

    if (lower.contains('sqlite') ||
        lower.contains('database') ||
        lower.contains('constraint')) {
      return 'Something went wrong. Try again later.';
    }

    // Server errors
    if (lower.contains('500') ||
        lower.contains('503') ||
        lower.contains('server error')) {
      return 'Something went wrong. Try again later.';
    }

    // Not found
    if (lower.contains('not found') || lower.contains('404')) {
      return 'Resource not found.';
    }

    return 'Something went wrong. Try again later.';
  }
}
