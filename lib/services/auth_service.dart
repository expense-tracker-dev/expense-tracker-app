import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<UserCredential> login({
    required String email,
    required String password,
  }) async {
    try {
      final result = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      if (result.user != null && !result.user!.emailVerified) {
        await _auth.signOut();
        throw Exception('Please verify your email before logging in.');
      }

      return result;
    } on FirebaseAuthException catch (e) {
      throw Exception(_getErrorMessage(e.code));
    }
  }

  Future<UserCredential> signup({
    required String name,
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    try {
      if (password != confirmPassword) {
        throw Exception('Passwords do not match.');
      }

      final result = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      await result.user?.updateDisplayName(name.trim());
      await result.user?.sendEmailVerification();

      return result;
    } on FirebaseAuthException catch (e) {
      throw Exception(_getErrorMessage(e.code));
    }
  }

  Future<UserCredential> googleLogin() async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();

      await googleSignIn.signOut();

      final GoogleSignInAccount? googleUser =
      await googleSignIn.signIn();

      if (googleUser == null) {
        throw Exception('Google sign-in was cancelled.');
      }

      final GoogleSignInAuthentication googleAuth =
      await googleUser.authentication;

      final OAuthCredential credential =
      GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
        accessToken: googleAuth.accessToken,
      );

      return await _auth.signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      throw Exception(_getErrorMessage(e.code));
    } catch (e) {
      if (e.toString().contains('cancelled')) {
        rethrow;
      }

      throw Exception('Google sign-in failed. Please try again.');
    }
  }

  Future<bool> checkEmailVerified() async {
    final user = _auth.currentUser;

    if (user == null) return false;

    await user.reload();

    return _auth.currentUser?.emailVerified ?? false;
  }

  Future<void> resendVerificationEmail() async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('Please create your account again.');
    }

    if (user.emailVerified) {
      throw Exception('Your email is already verified.');
    }

    await user.sendEmailVerification();
  }

  Future<void> logout() async {
    await _auth.signOut();

    try {
      await GoogleSignIn().signOut();
    } catch (_) {
      // Firebase sign-out has already completed.
    }
  }

  String _getErrorMessage(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'This email is already registered.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'weak-password':
        return 'Please choose a stronger password.';
      case 'user-not-found':
      case 'invalid-credential':
      case 'wrong-password':
        return 'Invalid email or password.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'network-request-failed':
        return 'Network error. Check your internet connection.';
      default:
        return 'Authentication failed. Please try again.';
    }
  }
}