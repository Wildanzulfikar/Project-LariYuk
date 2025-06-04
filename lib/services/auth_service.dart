import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Register dengan email & password dan kirim email verifikasi
  Future<User?> signUpWithEmail(String email, String password) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      await result.user!.sendEmailVerification(); // Kirim email verifikasi
      return result.user;
    } catch (e) {
      print('Error signing up: $e');
      return null;
    }
  }

  // Login dengan email & password, cek verifikasi email
  Future<User?> signInWithEmail(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      User user = result.user!;
      await user.reload(); // Refresh status user
      if (user.emailVerified) {
        return user;
      } else {
        await _auth.signOut();
        return null; // Email belum verifikasi, tolak login
      }
    } catch (e) {
      print('Error signing in: $e');
      return null;
    }
  }

  // Login dengan Google
  Future<User?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential =
          await _auth.signInWithCredential(credential);

      User user = userCredential.user!;
      await user.reload();

      // Untuk Google sign in biasanya sudah verified
      if (user.emailVerified) {
        return user;
      } else {
        await _auth.signOut();
        return null;
      }
    } catch (e) {
      print('Google Sign-In Error: $e');
      return null;
    }
  }

  // Logout
  Future<void> signOut() async {
    await _auth.signOut();
    await GoogleSignIn().signOut();
  }

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Refresh user info (misal untuk cek emailVerified terbaru)
  Future<User?> reloadUser() async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        await user.reload();
        return _auth.currentUser;
      }
      return null;
    } catch (e) {
      print('Error reloading user: $e');
      return null;
    }
  }
}
