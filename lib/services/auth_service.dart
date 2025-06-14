import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
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

      // Format phone number properly for Algeria
      String formattedPhone = phoneNumber;
      if (!phoneNumber.startsWith('+')) {
        // Remove leading zero if present and add country code
        if (phoneNumber.startsWith('0')) {
          formattedPhone = '+213${phoneNumber.substring(1)}';
        } else {
          formattedPhone = '+213$phoneNumber';
        }
      }

      print('Attempting to send OTP to: $formattedPhone');

      // For web platform, we need to handle reCAPTCHA
      if (kIsWeb) {
        await _requestOTPWeb(formattedPhone);
      } else {
        await _requestOTPMobile(formattedPhone);
      }
    } catch (e) {
      print('Request OTP error: ${e.toString()}');
      _updateState(_state.copyWith(
        status: AuthStatus.error,
        error: 'Une erreur est survenue: ${e.toString()}',
      ));
    }
  }

  Future<void> _requestOTPWeb(String phoneNumber) async {
    try {
      // Create a reCAPTCHA verifier for web
      final RecaptchaVerifier recaptchaVerifier = RecaptchaVerifier(
        container: 'recaptcha-container',
        size: RecaptchaVerifierSize.compact,
        theme: RecaptchaVerifierTheme.light,
        onSuccess: () {
          print('reCAPTCHA solved successfully');
        },
        onError: (FirebaseAuthException error) {
          print('reCAPTCHA error: ${error.message}');
        },
        onExpired: () {
          print('reCAPTCHA expired');
        },
      );

      // Send verification code
      final ConfirmationResult confirmationResult = 
          await _auth.signInWithPhoneNumber(phoneNumber, recaptchaVerifier);

      _updateState(_state.copyWith(
        status: AuthStatus.codeSent,
        verificationId: confirmationResult.verificationId,
        phoneNumber: phoneNumber,
      ));

      print('Code sent successfully for web');
    } catch (e) {
      print('Web OTP error: ${e.toString()}');
      throw e;
    }
  }

  Future<void> _requestOTPMobile(String phoneNumber) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: (PhoneAuthCredential credential) async {
        try {
          await _auth.signInWithCredential(credential);
          _updateState(_state.copyWith(status: AuthStatus.authenticated));
        } catch (e) {
          _updateState(_state.copyWith(
            status: AuthStatus.error,
            error: 'Erreur lors de la connexion automatique: ${e.toString()}',
          ));
        }
      },
      verificationFailed: (FirebaseAuthException e) {
        print('Verification failed: ${e.code} - ${e.message}');
        _updateState(_state.copyWith(
          status: AuthStatus.error,
          error: _getErrorMessage(e),
        ));
      },
      codeSent: (String verificationId, int? resendToken) {
        print('Code sent successfully. Verification ID: $verificationId');
        _updateState(_state.copyWith(
          status: AuthStatus.codeSent,
          verificationId: verificationId,
          phoneNumber: phoneNumber,
        ));
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        print('Auto retrieval timeout for: $verificationId');
      },
      timeout: const Duration(seconds: 60),
    );
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

      UserCredential userCredential;

      if (kIsWeb) {
        // For web, we need to use the confirmation result
        // This is a simplified approach - in a real app, you'd store the confirmation result
        final credential = PhoneAuthProvider.credential(
          verificationId: _state.verificationId!,
          smsCode: smsCode,
        );
        userCredential = await _auth.signInWithCredential(credential);
      } else {
        // For mobile platforms
        PhoneAuthCredential credential = PhoneAuthProvider.credential(
          verificationId: _state.verificationId!,
          smsCode: smsCode,
        );
        userCredential = await _auth.signInWithCredential(credential);
      }

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
      case 'quota-exceeded':
        return 'Quota SMS dépassé. Réessayez plus tard';
      case 'app-not-authorized':
        return 'Application non autorisée pour ce pays';
      case 'missing-phone-number':
        return 'Numéro de téléphone manquant';
      case 'invalid-app-credential':
        return 'Problème de vérification reCAPTCHA. Veuillez réessayer.';
      case 'captcha-check-failed':
        return 'Échec de la vérification reCAPTCHA. Veuillez réessayer.';
      case 'web-context-cancelled':
        return 'Vérification annulée. Veuillez réessayer.';
      default:
        // Check if it's the region error
        if (e.message?.contains('region') == true || 
            e.message?.contains('SMS unable to be sent') == true) {
          return 'Ce pays n\'est pas encore supporté. Contactez le support.';
        }
        return 'Erreur d\'authentification: ${e.message ?? e.code}';
    }
  }
}