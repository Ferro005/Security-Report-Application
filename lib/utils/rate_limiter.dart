import 'dart:collection';

/// Simple in-memory rate limiter (per app session)
/// Limits the number of attempts for a named operation within a time window.
class RateLimiter {
  static final Map<String, Queue<DateTime>> _attempts = {};

  /// Maximum attempts per window
  static const int _maxAttempts = 20;

  /// Sliding window duration
  static const Duration _window = Duration(minutes: 15);

  static bool isBlocked(String operation) {
    _prune(operation);
    final q = _attempts[operation];
    if (q == null) return false;
    return q.length >= _maxAttempts;
  }

  static void record(String operation) {
    final now = DateTime.now();
    final q = _attempts.putIfAbsent(operation, () => Queue<DateTime>());
    q.addLast(now);
    _prune(operation);
  }

  static void _prune(String operation) {
    final cutoff = DateTime.now().subtract(_window);
    final q = _attempts[operation];
    if (q == null) return;
    while (q.isNotEmpty && q.first.isBefore(cutoff)) {
      q.removeFirst();
    }
  }
}
