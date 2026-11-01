import 'dart:async';

class AuthTransitionInterrupted implements Exception {
  const AuthTransitionInterrupted();
}

class AuthTransitionBusy implements Exception {
  const AuthTransitionBusy();
}

/// One app-controlled authentication pipeline owns SDK/cache publication.
/// Logout invalidates it immediately, then waits for its uncancellable SDK work.
class AuthTransitions {
  AuthTransitions();
  static final instance = AuthTransitions();

  Future<void>? _tail;
  AuthTransitionLease? _active;
  Future<void>? _closing;
  int _revision = 0;

  bool get isBusy => _active != null || _closing != null;
  bool get isClosing => _closing != null;
  int get revision => _revision;
  AuthTransitionLease? get active => _active;
  Future<void> get settled => _tail ?? Future<void>.value();
  bool owns(AuthTransitionLease lease) => identical(_active, lease);

  Future<T> _enqueue<T>(Future<T> Function() action) {
    final previous = _tail;
    final result = previous == null
        ? Future<T>.sync(action)
        : previous.then((_) => action());
    final tail = result.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    _tail = tail;
    tail.then((_) {
      if (identical(_tail, tail)) _tail = null;
    });
    return result;
  }

  Future<T> run<T>(
    Future<T> Function(AuthTransitionLease lease) action, {
    Future<void> Function(AuthTransitionLease lease)? onFailure,
  }) {
    if (isBusy) return Future<T>.error(const AuthTransitionBusy());
    final lease = AuthTransitionLease._(this, ++_revision);
    _active = lease;
    return _enqueue(() async {
      var completed = false;
      try {
        lease.check();
        final result = await action(lease);
        lease.check();
        completed = true;
        return result;
      } finally {
        if (!completed &&
            !isClosing &&
            lease.cleanupUid != null &&
            onFailure != null) {
          try {
            await onFailure(lease);
          } catch (_) {
            // Preserve the original failure; owned cleanup is best effort.
          }
        }
        if (owns(lease)) _active = null;
      }
    });
  }

  Future<void> close(Future<void> Function() cleanup) {
    final existing = _closing;
    if (existing != null) return existing;
    _active?.cancel();
    _revision++;
    final done = Completer<void>();
    _closing = done.future;
    _enqueue(cleanup).then<void>(
      (_) {
        _closing = null;
        done.complete();
      },
      onError: (Object error, StackTrace stack) {
        _closing = null;
        done.completeError(error, stack);
      },
    );
    return done.future;
  }
}

class AuthTransitionLease {
  AuthTransitionLease._(this._owner, this._revision);
  final AuthTransitions _owner;
  final int _revision;
  bool _valid = true;
  String? cleanupUid;
  bool cleanedOwned = false;
  bool endSdkOnFailure = false;

  bool get isLatest => _valid && _revision == _owner._revision;
  bool get isCurrent => isLatest && _owner.owns(this) && !_owner.isClosing;
  void check() {
    if (!isCurrent) throw const AuthTransitionInterrupted();
  }

  void cancel() => _valid = false;
  void recordSdkUser(String uid) {
    if (_owner.owns(this)) {
      cleanupUid = uid;
      endSdkOnFailure = true;
    }
  }

  void requireCleanupFor(String uid, {bool endSdkSession = false}) {
    if (_owner.owns(this)) {
      cleanupUid ??= uid;
      endSdkOnFailure |= endSdkSession;
    }
  }
}

/// Binds non-SDK auth forms to the session which opened them, including a
/// subsequent sign-in to the same UID. No credentials are stored here.
class AuthSessionFence {
  AuthSessionFence.capture({
    required String? Function() currentUid,
    AuthTransitions? transitions,
  }) : _currentUid = currentUid,
       _transitions = transitions ?? AuthTransitions.instance {
    _uid = currentUid();
    _revision = _transitions.revision;
  }
  final String? Function() _currentUid;
  final AuthTransitions _transitions;
  late final String? _uid;
  late final int _revision;
  bool get isCurrent =>
      !_transitions.isBusy &&
      _transitions.revision == _revision &&
      _currentUid() == _uid;
}
