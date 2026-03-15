class AppErrorMapper {
  static String toUserMessage(String? rawError) {
    if (rawError == null) return 'Something went wrong. Try again later.';

    final lower = rawError.toLowerCase();

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

    // Network errors
    if (lower.contains('network') ||
        lower.contains('connection') ||
        lower.contains('socket')) {
      return 'Network error. Check your connection and try again.';
    }
    if (lower.contains('timeout')) {
      return 'Connection timed out. Try again.';
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
