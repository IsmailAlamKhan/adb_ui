final class AuthUser {
  const AuthUser({required this.id, required this.email});

  final String id;
  final String? email;
}

sealed class AuthState {
  const AuthState();

  const factory AuthState.loading() = AuthStateLoading;
  const factory AuthState.unauthenticated() = AuthStateUnauthenticated;
  factory AuthState.authenticated(AuthUser user) = AuthStateAuthenticated;
  const factory AuthState.error(String message) = AuthStateError;
}

final class AuthStateLoading extends AuthState {
  const AuthStateLoading();
}

final class AuthStateUnauthenticated extends AuthState {
  const AuthStateUnauthenticated();
}

final class AuthStateAuthenticated extends AuthState {
  AuthStateAuthenticated(this.user) : super();

  final AuthUser user;
}

final class AuthStateError extends AuthState {
  const AuthStateError(this.message);

  final String message;
}

extension AuthStateX on AuthState {
  T maybeWhen<T>({
    T Function()? loading,
    T Function()? unauthenticated,
    T Function(AuthUser user)? authenticated,
    T Function(String message)? error,
    required T Function() orElse,
  }) {
    return switch (this) {
      AuthStateLoading() => loading?.call() ?? orElse(),
      AuthStateUnauthenticated() => unauthenticated?.call() ?? orElse(),
      AuthStateAuthenticated(:final user) => authenticated?.call(user) ?? orElse(),
      AuthStateError(:final message) => error?.call(message) ?? orElse(),
    };
  }

  T map<T>({
    required T Function(AuthStateLoading value) loading,
    required T Function(AuthStateUnauthenticated value) unauthenticated,
    required T Function(AuthStateAuthenticated value) authenticated,
    required T Function(AuthStateError value) error,
  }) {
    return switch (this) {
      final AuthStateLoading v => loading(v),
      final AuthStateUnauthenticated v => unauthenticated(v),
      final AuthStateAuthenticated v => authenticated(v),
      final AuthStateError v => error(v),
    };
  }
}
