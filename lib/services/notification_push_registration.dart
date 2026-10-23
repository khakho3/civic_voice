/// Serialize device-token ownership changes so an old registration cannot
/// finish after the new account's registration and leave the token misbound.
class NotificationPushRegistration {
  NotificationPushRegistration({
    required this.owner,
    required this.credential,
    required this.register,
    required this.unregister,
  });
  final String? Function() owner;
  final Future<String?> Function() credential;
  final Future<void> Function(String credential, String token) register;
  final Future<void> Function(String credential, String token) unregister;
  Future<void> _tail = Future<void>.value();

  Future<void> bind(String token) {
    final identity = owner();
    final operation = _tail.then((_) async {
      if (identity == null || owner() != identity) return;
      String? auth;
      var dispatched = false;
      try {
        auth = await credential();
        if (auth == null || owner() != identity) return;
        dispatched = true;
        await register(auth, token);
      } catch (_) {
        // A future app open or provider token refresh retries registration.
      } finally {
        if (dispatched && auth != null && owner() != identity) {
          try {
            // Server cleanup is constrained to the credential's own account.
            await unregister(auth, token);
          } catch (_) {}
        }
      }
    });
    _tail = operation;
    return operation;
  }
}
