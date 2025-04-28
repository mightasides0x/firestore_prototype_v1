part of 'auth_cubit.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

// Initial state before anything happens
class AuthInitial extends AuthState {}

// State while an async operation (login, signup) is in progress
class AuthLoading extends AuthState {}

// State when the user is successfully authenticated
class Authenticated extends AuthState {
  final firebase_auth.User user;

  const Authenticated(this.user);

  @override
  List<Object?> get props => [user];
}

// State when the user is not authenticated
class Unauthenticated extends AuthState {}

// State when an error occurs during authentication
class AuthError extends AuthState {
  final String message;

  const AuthError(this.message);

  @override
  List<Object?> get props => [message];
} 