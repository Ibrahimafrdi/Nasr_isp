import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
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
    final String tempAppName = 'temp_create_user_${DateTime.now().microsecondsSinceEpoch}';
    FirebaseApp? secondaryApp;
    try {
      secondaryApp = await Firebase.initializeApp(
        name: tempAppName,
        options: Firebase.app().options,
      );
      final authForSecondary = FirebaseAuth.instanceFor(app: secondaryApp);
      final userCredential = await authForSecondary.createUserWithEmailAndPassword(
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

      // Save profile doc using primary Firestore instance
      await _usersCol.doc(user.uid).set(model.toMap());
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        throw Exception('The email address is already in use by another account.');
      } else if (e.code == 'weak-password') {
        throw Exception('The password provided is too weak.');
      } else if (e.code == 'invalid-email') {
        throw Exception('Please enter a valid email address.');
      }
      throw Exception(e.message ?? 'Failed to create user.');
    } finally {
      if (secondaryApp != null) {
        try {
          await FirebaseAuth.instanceFor(app: secondaryApp).signOut();
        } catch (_) {}
        try {
          await secondaryApp.delete();
        } catch (_) {}
      }
    }
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
