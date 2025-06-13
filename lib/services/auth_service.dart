import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/auth_state.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  AuthState _state = const AuthState();

  AuthState get state => _state;
  User? get currentUser => _auth.currentUser;
  bool get isAuthenticated => currentUser != null;

  AuthService() {
    _auth.authStateChanges().listen((User? user) {
      if (user != null) {
        _updateState(_state.copyWith(status: AuthStatus.authenticated));
      } else {
        _updateState(_state.copyWith(status: AuthStatus.unauthenticated));
      }
    });
  }

  void _updateState(AuthState newState) {
    _state = newState;
    notifyListeners();
  }

  Future<void> requestOTP(String phoneNumber) async {
    try {
      _updateState(_state.copyWith(status: AuthStatus.loading));

      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          await _auth.signInWithCredential(credential);
          _updateState(_state.copyWith(status: AuthStatus.authenticated));
        },
        verificationFailed: (FirebaseAuthException e) {
          _updateState(_state.copyWith(
            status: AuthStatus.error,
            error: _getErrorMessage(e),
          ));
        },
        codeSent: (String verificationId, int? resendToken) {
          _updateState(_state.copyWith(
            status: AuthStatus.codeSent,
            verificationId: verificationId,
            phoneNumber: phoneNumber,
          ));
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          // Handle timeout
        },
        timeout: const Duration(seconds: 60),
      );
    } catch (e) {
      _updateState(_state.copyWith(
        status: AuthStatus.error,
        error: 'Une erreur est survenue: ${e.toString()}',
      ));
    }
  }

  Future<void> verifyOTP(String smsCode) async {
    try {
      _updateState(_state.copyWith(status: AuthStatus.loading));

      if (_state.verificationId == null) {
        _updateState(_state.copyWith(
          status: AuthStatus.error,
          error: 'ID de vérification manquant',
        ));
        return;
      }

      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: _state.verificationId!,
        smsCode: smsCode,
      );

      await _auth.signInWithCredential(credential);
      _updateState(_state.copyWith(status: AuthStatus.verified));
    } on FirebaseAuthException catch (e) {
      _updateState(_state.copyWith(
        status: AuthStatus.error,
        error: _getErrorMessage(e),
      ));
    } catch (e) {
      _updateState(_state.copyWith(
        status: AuthStatus.error,
        error: 'Erreur de vérification: ${e.toString()}',
      ));
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
      _updateState(const AuthState(status: AuthStatus.unauthenticated));
    } catch (e) {
      _updateState(_state.copyWith(
        status: AuthStatus.error,
        error: 'Erreur de déconnexion: ${e.toString()}',
      ));
    }
  }

  void clearError() {
    _updateState(_state.copyWith(error: null));
  }

  String _getErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-phone-number':
        return 'Le numéro de téléphone est invalide';
      case 'too-many-requests':
        return 'Trop de tentatives. Réessayez plus tard';
      case 'invalid-verification-code':
        return 'Code de vérification invalide';
      case 'session-expired':
        return 'Session expirée. Demandez un nouveau code';
      default:
        return 'Erreur d\'authentification: ${e.message}';
    }
  }
}