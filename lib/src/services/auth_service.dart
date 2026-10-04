import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

/// Identifies the same person across devices so their data can sync via
/// [CloudWorkoutRepository] — either by signing in with Google, or via a
/// passwordless email link as a fallback for people without a Google
/// account handy.
///
/// The email-link path intentionally avoids relying on platform
/// deep-linking: the sign-in link is emailed to the user, and they paste it
/// back into the app to finish signing in. That works without a Firebase
/// Hosting domain or native Universal Links / App Links configuration.
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

  Future<void> sendSignInLink(String email) {
    final projectId = Firebase.app().options.projectId;

    return _auth.sendSignInLinkToEmail(
      email: email,
      actionCodeSettings: ActionCodeSettings(
        url: 'https://$projectId.firebaseapp.com/finish-sign-in',
        handleCodeInApp: true,
      ),
    );
  }

  bool isSignInLink(String link) => _auth.isSignInWithEmailLink(link);

  Future<UserCredential> completeSignIn({
    required String email,
    required String link,
  }) {
    return _auth.signInWithEmailLink(email: email, emailLink: link);
  }

  Future<void> signOut() => _auth.signOut();
}
