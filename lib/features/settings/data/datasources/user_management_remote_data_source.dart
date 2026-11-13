import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:http/http.dart' as http;
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

  UserManagementRemoteDataSourceImpl({
    FirebaseFirestore? firestore,
    FirebaseAuth? firebaseAuth,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference get _usersCol => _firestore.collection('users');

  @override
  Future<List<UserModel>> getUsers() async {
    final snapshot = await _usersCol.get();
    return snapshot.docs.map((doc) => UserModel.fromFirestore(doc)).toList();
  }

  @override
  Future<void> createUser(
    String email,
    String password,
    String name,
    String role,
  ) async {
    // Create the login through the Auth REST API. Unlike
    // createUserWithEmailAndPassword, this never signs the browser in as the
    // new user, so the admin's session stays intact.
    final uri = Uri.https(
      'identitytoolkit.googleapis.com',
      '/v1/accounts:signUp',
      {'key': Firebase.app().options.apiKey},
    );

    final http.Response response;
    try {
      response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'email': email.trim(),
              'password': password,
              'returnSecureToken': false,
            }),
          )
          .timeout(const Duration(seconds: 20));
    } on TimeoutException {
      throw Exception('Timed out reaching Firebase. Check your connection.');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode != 200) {
      final code = ((body['error'] as Map?)?['message'] as String?) ?? '';
      if (code.startsWith('EMAIL_EXISTS')) {
        throw Exception(
          'The email address is already in use by another account.',
        );
      }
      if (code.startsWith('WEAK_PASSWORD')) {
        throw Exception(
          'The password provided is too weak (minimum 6 characters).',
        );
      }
      if (code.startsWith('INVALID_EMAIL')) {
        throw Exception('Please enter a valid email address.');
      }
      if (code.startsWith('OPERATION_NOT_ALLOWED')) {
        throw Exception(
          'Email/password sign-in is turned off in Firebase Authentication.',
        );
      }
      throw Exception(code.isEmpty ? 'Failed to create user.' : code);
    }

    final uid = body['localId'] as String?;
    if (uid == null || uid.isEmpty) {
      throw Exception('Failed to create Firebase Auth user.');
    }

    final model = UserModel(
      id: uid,
      name: name,
      email: email.trim(),
      phone: '',
      role: role,
      isActive: true,
      createdAt: DateTime.now(),
    );

    // Written with the admin's own session, so the existing admin-only
    // rule for creating users applies.
    await _usersCol
        .doc(uid)
        .set(model.toMap())
        .timeout(const Duration(seconds: 15));
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
