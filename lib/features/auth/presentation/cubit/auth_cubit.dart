import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart'; // Import here
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth; // Import here
import 'package:firestore_prototype_v1/features/auth/domain/repositories/auth_repository.dart';
import 'package:logging/logging.dart'; // Use consistent logging package

part 'auth_state.dart'; // Include the state file

class AuthCubit extends Cubit<AuthState> {
  final AuthRepository _authRepository;
  late StreamSubscription<firebase_auth.User?> _userSubscription;
  static final _log = Logger('AuthCubit');

  AuthCubit({required AuthRepository authRepository}) // Inject repository
      : _authRepository = authRepository,
        super(AuthInitial()) // Start with Initial state
  {
    // Subscribe to user changes immediately upon creation
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
    try {
      await _authRepository.signUp(email: email, password: password);
      // State will update via _onUserChanged listener
    } catch (e) {
      emit(AuthError(e.toString()));
      emit(Unauthenticated()); // Revert to unauthenticated after error
    }
  }

  Future<void> logIn(String email, String password) async {
    try {
      await _authRepository.logInWithEmailAndPassword(
          email: email, password: password);
      // State will update via _onUserChanged listener
    } catch (e) {
      emit(AuthError(e.toString()));
      emit(Unauthenticated()); // Revert to unauthenticated after error
    }
  }

  Future<void> logOut() async {
    try {
      await _authRepository.logOut();
      emit(Unauthenticated()); // Explicitly emit unauthenticated state
    } catch (e) {
      // Log error, but still assume logout locally
      _log.severe('Error during logout', e);
      emit(Unauthenticated());
    }
  }

  Future<void> clearMatchId() async {
    if (state is Authenticated) {
      final user = (state as Authenticated).user;
      if (user != null) {
        try {
          await _authRepository.clearUserMatchId(user.uid);
          _log.info('User triggered match ID clear successfully.');
          // Optionally emit a success state or message?
        } catch (e) {
          _log.severe('Error clearing match ID via Cubit', e);
          // Optionally emit an error state or message?
        }
      } else {
         _log.warning('ClearMatchId called but user is null in state.');
      }
    } else {
       _log.warning('ClearMatchId called when not authenticated.');
    }
  }

  // Cancel subscription when Cubit is closed
  @override
  Future<void> close() {
    _userSubscription.cancel();
    return super.close();
  }
} 