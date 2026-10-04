import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

/// Identifies the same person across devices, signed in with Google, so
/// their data can sync via [CloudWorkoutRepository].
class AuthService {
  AuthService({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  /// `signInWithProvider` is the cross-platform method on Android and iOS,
  /// but the web platform package only implements the popup/redirect-based
  /// flow — calling `signInWithProvider` there throws "not implemented".
  Future<UserCredential> signInWithGoogle() {
    final provider = GoogleAuthProvider();
    return kIsWeb ? _auth.signInWithPopup(provider) : _auth.signInWithProvider(provider);
  }

  Future<void> signOut() => _auth.signOut();
}
