import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:nasr_isp/features/auth/data/models/user_model.dart';

abstract class UserManagementRemoteDataSource {
  Future<List<UserModel>> getUsers();
  Future<void> createUser(
    String email,
    String password,
    String name,
    String role,
  );
  Future<void> updateUserRole(String uid, String role);
  Future<void> toggleUserStatus(String uid, bool isActive);
}

class UserManagementRemoteDataSourceImpl
    implements UserManagementRemoteDataSource {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  UserManagementRemoteDataSourceImpl({
    FirebaseFirestore? firestore,
    FirebaseAuth? firebaseAuth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = firebaseAuth ?? FirebaseAuth.instance;

  CollectionReference get _usersCol => _firestore.collection('users');

  @override
  Future<List<UserModel>> getUsers() async {
    final snapshot = await _usersCol.get();
    return snapshot.docs
        .map((doc) => UserModel.fromFirestore(doc))
        .toList();
  }

  @override
  Future<void> createUser(
    String email,
    String password,
    String name,
    String role,
  ) async {
    // KNOWN LIMITATION:
    // Creating a user with Firebase Client SDK signs the current user out
    // and signs the new user in. We call signOut() immediately after creation.
    // The admin's own session will be logged out unless session-restore/re-auth is handled.
    // The proper fix is using Firebase Admin SDK or a Cloud Function.
    
    final userCredential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final user = userCredential.user;
    if (user == null) {
      throw Exception('Failed to create Firebase Auth user.');
    }

    final model = UserModel(
      id: user.uid,
      name: name,
      email: email.trim(),
      phone: '', // Default/empty since not provided on creation
      role: role,
      isActive: true,
      createdAt: DateTime.now(),
    );

    // Save profile doc
    await _usersCol.doc(user.uid).set(model.toMap());

    // Immediately sign out to clear the new session
    await _auth.signOut();
  }

  @override
  Future<void> updateUserRole(String uid, String role) async {
    await _usersCol.doc(uid).update({'role': role});
  }

  @override
  Future<void> toggleUserStatus(String uid, bool isActive) async {
    await _usersCol.doc(uid).update({'isActive': isActive});
  }
}
