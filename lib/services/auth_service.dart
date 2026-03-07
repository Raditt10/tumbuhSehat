import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_model.dart';
import 'database_service.dart'; // We will create this next

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Sign in with email and password
  Future<UserModel?> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? user = result.user;

      if (user != null) {
        // Fetch custom user model from Firestore
        return await DatabaseService().getUserData(user.uid);
      }
      return null;
    } catch (e) {
      print("Error signing in: \$e");
      return null;
    }
  }

  // Register with email and password
  Future<UserModel?> registerWithEmailAndPassword(
    String email,
    String password,
    String role,
  ) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? user = result.user;

      if (user != null) {
        // Create an initial document in users collection
        UserModel newUser = UserModel(id: user.uid, email: email, role: role);

        await _firestore.collection('users').doc(user.uid).set(newUser.toMap());
        return newUser;
      }
      return null;
    } catch (e) {
      print("Error registering: \$e");
      return null;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await GoogleSignIn().signOut();
      return await _auth.signOut();
    } catch (e) {
      print("Error signing out: \$e");
    }
  }

  // Get Google email without full Firebase sign-in (for pre-check)
  Future<String?> getGoogleEmail() async {
    final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
    return googleUser?.email;
  }

  // Sign out Google only (without Firebase sign out)
  Future<void> signOutGoogle() async {
    await GoogleSignIn().signOut();
  }

  // Full Google Sign-In to Firebase
  Future<User?> signInWithGoogle() async {
    final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
    if (googleUser == null) return null;

    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;

    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final UserCredential userCredential =
        await _auth.signInWithCredential(credential);
    return userCredential.user;
  }

  // Link Google account to existing user (called from Profile)
  // Requires password to handle orphaned account cleanup
  Future<String?> linkGoogleAccount(String password) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return null;

    final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
    if (googleUser == null) return null;

    final googleEmail = googleUser.email;
    final originalEmail = currentUser.email!;
    final originalUid = currentUser.uid;

    // Check if this Google email is already linked to another Firestore account
    final existing = await _firestore
        .collection('users')
        .where('linkedGoogleEmail', isEqualTo: googleEmail)
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty && existing.docs.first.id != originalUid) {
      await GoogleSignIn().signOut();
      throw Exception('Akun Google ini sudah dikaitkan dengan akun lain.');
    }

    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;
    final googleCredential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    try {
      // Link Google provider to current Firebase Auth account
      await currentUser.linkWithCredential(googleCredential);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'credential-already-in-use') {
        // Orphaned Firebase Auth account exists with this Google credential
        // Clean it up: sign into orphan, delete it, sign back, link again
        try {
          final orphanResult =
              await _auth.signInWithCredential(googleCredential);
          await orphanResult.user?.delete();
        } catch (_) {}

        // Sign back into original account
        await _auth.signInWithEmailAndPassword(
          email: originalEmail,
          password: password,
        );

        // Try linking again
        await _auth.currentUser!.linkWithCredential(googleCredential);
      } else if (e.code == 'provider-already-linked') {
        // Google already linked at Firebase Auth level, just update Firestore
      } else {
        await GoogleSignIn().signOut();
        rethrow;
      }
    }

    // Save linked Google email in Firestore
    await _firestore.collection('users').doc(originalUid).update({
      'linkedGoogleEmail': googleEmail,
    });

    await GoogleSignIn().signOut();
    return googleEmail;
  }

  // Unlink Google account
  Future<void> unlinkGoogleAccount() async {
    final currentUser = _auth.currentUser;
    if (currentUser != null) {
      // Unlink from Firebase Auth
      try {
        await currentUser.unlink('google.com');
      } catch (_) {}

      // Remove from Firestore
      await _firestore.collection('users').doc(currentUser.uid).update({
        'linkedGoogleEmail': FieldValue.delete(),
      });
    }
  }

  // Auth State Stream
  Stream<User?> get user {
    return _auth.authStateChanges();
  }
}
