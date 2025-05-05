import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:firestore_prototype_v1/features/auth/domain/repositories/auth_repository.dart';
import 'package:logging/logging.dart'; // Import logging

class AuthRepositoryImpl implements AuthRepository {
  // Add logger
  static final _log = Logger('AuthRepositoryImpl');

  final firebase_auth.FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;

  // Constants
  static const String _usersCollection = 'users';
  static const String _fieldCurrentMatchId = 'currentMatchId';
  static const String _fieldEmail = 'email';
  static const String _fieldCreatedAt = 'createdAt';

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
  Stream<String?> get onMatchIdChanged {
    return user.asyncExpand<String?>((firebaseUser) {
      if (firebaseUser == null) {
        _log.info('User logged out, matchId stream emitting null.');
        return Stream.value(null);
      } else {
        _log.info('User ${firebaseUser.uid} logged in, listening to matchId changes.');
        final userDocRef = _firestore.collection(_usersCollection).doc(firebaseUser.uid);
        return userDocRef.snapshots().map((docSnapshot) {
          if (!docSnapshot.exists || docSnapshot.data() == null) {
            _log.warning('User document ${firebaseUser.uid} does not exist or has no data.');
            return null;
          }
          final data = docSnapshot.data()!;
          final matchId = data[_fieldCurrentMatchId] as String?;
          _log.finer('User document ${firebaseUser.uid} snapshot received. Match ID: $matchId');
          return matchId;
        }).handleError((error, stackTrace) {
          _log.severe('Error listening to user document ${firebaseUser.uid} snapshots', error, stackTrace);
          // Emit null or let the error propagate? Emitting null might be safer for UI.
          return null;
        });
      }
    });
  }

  @override
  Future<void> signUp({
    required String email,
    required String password,
  }) async {
    _log.info('Attempting to sign up user with email: $email');
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
        _log.info('Verification email sent to $email');
      } catch (e, stackTrace) {
        // Log if sending email fails, but don't block signup
        _log.warning('Failed to send verification email', e, stackTrace);
      }

      // 2. Create corresponding user document in Firestore (Task 1.6)
      await _firestore.collection(_usersCollection).doc(firebaseUser.uid).set({
        _fieldEmail: email,
        _fieldCreatedAt: FieldValue.serverTimestamp(), // Good practice to store creation time
        _fieldCurrentMatchId: null, // Initialize fields expected later
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
    _log.info('Attempting login for $email');
    try {
      await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      _log.info('Login successful for $email');
    } on firebase_auth.FirebaseAuthException catch (e) {
      _log.severe('Firebase Auth Login error: ${e.code}', e);
      throw Exception('Login failed: ${e.message ?? e.code}');
    } catch (e, stackTrace) {
      _log.severe('General Login error', e, stackTrace);
      throw Exception('An unexpected error occurred during login.');
    }
  }

  @override
  Future<void> logOut() async {
    try {
      await _firebaseAuth.signOut();
      _log.info('User logged out successfully.');
    } catch (e, stackTrace) {
      _log.severe('Error logging out', e, stackTrace);
      // Let caller handle logout errors if needed, often safe to ignore
    }
  }

  @override
  Future<void> clearUserMatchId(String userId) async {
    _log.info('Clearing currentMatchId for user $userId');
    try {
      final userDocRef = _firestore.collection(_usersCollection).doc(userId);
      await userDocRef.update({_fieldCurrentMatchId: null});
      _log.info('Successfully cleared currentMatchId for user $userId.');
    } catch (e, stackTrace) {
      _log.severe('Error clearing currentMatchId for user $userId', e, stackTrace);
      // Rethrow or handle as needed
      throw Exception('Failed to clear match state: ${e.toString()}');
    }
  }
} 