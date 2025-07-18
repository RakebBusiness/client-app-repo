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
  final String? userId;

  const AuthState({
    this.status = AuthStatus.initial,
    this.error,
    this.verificationId,
    this.phoneNumber,
    this.userId,
  });

  AuthState copyWith({
    AuthStatus? status,
    String? error,
    String? verificationId,
    String? phoneNumber,
    String? userId,
  }) {
    return AuthState(
      status: status ?? this.status,
      error: error,
      verificationId: verificationId ?? this.verificationId,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      userId: userId ?? this.userId,
    );
  }
}