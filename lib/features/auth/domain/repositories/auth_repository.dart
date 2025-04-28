import 'package:firebase_auth/firebase_auth.dart' as firebase_auth; // Alias needed

// Define the contract for authentication operations
abstract class AuthRepository {
  // Stream to listen for authentication state changes (logged in/out user)
  Stream<firebase_auth.User?> get user;

  // Sign up with email and password
  Future<void> signUp({required String email, required String password});

  // Log in with email and password
  Future<void> logInWithEmailAndPassword({
    required String email,
    required String password,
  });

  // Log out the current user
  Future<void> logOut();
} 