import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:nasr_isp/features/auth/data/models/user_model.dart';

/// Low-level service that wraps Firebase Authentication and Firestore reads.
/// Throws [FirebaseAuthException] for auth errors and [Exception] for others.
class FirebaseAuthService {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  FirebaseAuthService({
    FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
  })  : _auth = firebaseAuth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  // ── Auth ──────────────────────────────────────────────────────────────────

  /// Signs in and returns the raw Firebase [User]. Throws [FirebaseAuthException].
  Future<User> signInWithEmailAndPassword(String email, String password) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final user = credential.user;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'null-user',
        message: 'Login failed. Please try again.',
      );
    }
    return user;
  }

  /// Signs out the current user.
  Future<void> signOut() => _auth.signOut();

  /// Returns the currently authenticated Firebase [User], or null.
  User? get currentUser => _auth.currentUser;

  /// Reloads the current user's token / profile from Firebase.
  Future<void> reloadCurrentUser() async {
    await _auth.currentUser?.reload();
  }

  // ── Firestore ─────────────────────────────────────────────────────────────

  /// Fetches the Firestore user document for [uid] and maps it to [UserModel].
  /// Returns null if the document does not exist.
  Future<UserModel?> fetchUserProfile(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return UserModel.fromFirestore(doc);
  }
}
