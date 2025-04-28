import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart'; // Import here
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth; // Import here
import 'package:firestore_prototype_v1/features/auth/domain/repositories/auth_repository.dart';

part 'auth_state.dart'; // Include the state file

class AuthCubit extends Cubit<AuthState> {
  final AuthRepository _authRepository;
  late StreamSubscription<firebase_auth.User?> _userSubscription;

  AuthCubit({required AuthRepository authRepository}) // Inject repository
      : _authRepository = authRepository,
        super(AuthInitial()) { // Start with Initial state
    // Listen to user changes immediately
    _userSubscription = _authRepository.user.listen(_onUserChanged);
  }

  // Callback for user stream changes
  void _onUserChanged(firebase_auth.User? user) {
    if (user != null) {
      emit(Authenticated(user));
    } else {
      emit(Unauthenticated());
    }
  }

  Future<void> signUp(String email, String password) async {
    emit(AuthLoading());
    try {
      await _authRepository.signUp(email: email, password: password);
      // State will automatically change to Authenticated via _onUserChanged listener
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> logIn(String email, String password) async {
    emit(AuthLoading());
    try {
      await _authRepository.logInWithEmailAndPassword(email: email, password: password);
      // State will automatically change to Authenticated via _onUserChanged listener
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> logOut() async {
    // Don't necessarily need loading state for logout, but can add if desired
    try {
      await _authRepository.logOut();
      // State will automatically change to Unauthenticated via _onUserChanged listener
    } catch (e) {
      emit(AuthError(e.toString())); // Emit error if logout fails
    }
  }

  // Cancel subscription when Cubit is closed
  @override
  Future<void> close() {
    _userSubscription.cancel();
    return super.close();
  }
} 