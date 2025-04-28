import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:firestore_prototype_v1/features/auth/domain/repositories/auth_repository.dart';
import 'package:logging/logging.dart'; // Import logging

class AuthRepositoryImpl implements AuthRepository {
  // Add logger
  static final _log = Logger('AuthRepositoryImpl');

  final firebase_auth.FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;

  AuthRepositoryImpl({
    firebase_auth.FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
  })  : _firebaseAuth = firebaseAuth ?? firebase_auth.FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Stream<firebase_auth.User?> get user {
    return _firebaseAuth.authStateChanges();
  }

  @override
  Future<void> signUp({
    required String email,
    required String password,
  }) async {
    try {
      // 1. Create user in Firebase Auth
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Ensure we have a user
      final firebaseUser = userCredential.user;
      if (firebaseUser == null) {
        throw Exception('Sign up successful, but user data is null.');
      }

      // Send verification email
      try {
        await firebaseUser.sendEmailVerification();
        _log.info('Verification email sent to ${firebaseUser.email}');
      } catch (e, stackTrace) {
        // Log if sending email fails, but don't block signup
        _log.warning('Failed to send verification email', e, stackTrace);
      }

      // 2. Create corresponding user document in Firestore (Task 1.6)
      await _firestore.collection('users').doc(firebaseUser.uid).set({
        'uid': firebaseUser.uid,
        'email': email,
        'createdAt': FieldValue.serverTimestamp(), // Good practice to store creation time
        'currentMatchId': null, // Initialize fields expected later
        // Add any other initial user fields here
      });
    } on firebase_auth.FirebaseAuthException catch (e, stackTrace) {
      // Replaced print with logger
      _log.warning('FirebaseAuthException during signup: ${e.code}', e, stackTrace);
      throw Exception('Sign up failed: ${e.message}');
    } catch (e, stackTrace) {
      // Replaced print with logger
      _log.severe('Unexpected error during signup', e, stackTrace);
      throw Exception('An unexpected error occurred during sign up.');
    }
  }

  @override
  Future<void> logInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on firebase_auth.FirebaseAuthException catch (e, stackTrace) {
      _log.warning('FirebaseAuthException during login: ${e.code}', e, stackTrace);
      throw Exception('Log in failed: ${e.message}');
    } catch (e, stackTrace) {
      _log.severe('Unexpected error during login', e, stackTrace);
      throw Exception('An unexpected error occurred during log in.');
    }
  }

  @override
  Future<void> logOut() async {
    try {
      await _firebaseAuth.signOut();
    } on firebase_auth.FirebaseAuthException catch (e, stackTrace) {
      _log.warning('FirebaseAuthException during logout: ${e.code}', e, stackTrace);
      throw Exception('Log out failed: ${e.message}');
    } catch (e, stackTrace) {
      _log.severe('Unexpected error during logout', e, stackTrace);
      throw Exception('An unexpected error occurred during log out.');
    }
  }
} 