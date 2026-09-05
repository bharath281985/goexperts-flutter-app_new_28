/// Called when refresh token fails — triggers logout in [AuthBloc].
class SessionHandler {
  void Function(String message)? onSessionExpired;
  Future<void> Function()? onTokenRefreshed;

  DateTime? _lastExpiredNotified;

  Future<void> notifyExpired([
    String message = 'Session expired. Please login again.',
  ]) async {
    final now = DateTime.now();
    if (_lastExpiredNotified != null &&
        now.difference(_lastExpiredNotified!).inSeconds < 5) {
      return;
    }
    _lastExpiredNotified = now;
    onSessionExpired?.call(message);
  }

  Future<void> notifyTokenRefreshed() async {
    final cb = onTokenRefreshed;
    if (cb != null) await cb();
  }
}
