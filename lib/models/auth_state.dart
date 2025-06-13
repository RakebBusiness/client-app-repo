enum AuthStatus {
  initial,
  loading,
  codeSent,
  verified,
  error,
  authenticated,
  unauthenticated
}

class AuthState {
  final AuthStatus status;
  final String? error;
  final String? verificationId;
  final String? phoneNumber;

  const AuthState({
    this.status = AuthStatus.initial,
    this.error,
    this.verificationId,
    this.phoneNumber,
  });

  AuthState copyWith({
    AuthStatus? status,
    String? error,
    String? verificationId,
    String? phoneNumber,
  }) {
    return AuthState(
      status: status ?? this.status,
      error: error,
      verificationId: verificationId ?? this.verificationId,
      phoneNumber: phoneNumber ?? this.phoneNumber,
    );
  }
}