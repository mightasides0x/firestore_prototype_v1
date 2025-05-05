import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

// Repositories needed for listening to auth state
import 'package:firestore_prototype_v1/features/auth/domain/repositories/auth_repository.dart';

// Screens
import 'package:firestore_prototype_v1/features/auth/presentation/screens/login_screen.dart';
import 'package:firestore_prototype_v1/features/auth/presentation/screens/signup_screen.dart';
import 'package:firestore_prototype_v1/features/home/presentation/screens/home_screen.dart';
import 'package:firestore_prototype_v1/features/game/presentation/screens/game_screen.dart';

// BLoC/Cubit - Needed for GameScreen provider
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firestore_prototype_v1/features/game/presentation/cubit/game_cubit.dart';
import 'package:firestore_prototype_v1/features/game/domain/repositories/game_repository.dart';
import 'package:firestore_prototype_v1/features/game/domain/repositories/question_repository.dart';


/// Defines application routes using go_router.
class AppRouter {
  final AuthRepository authRepository;
  // Get FirebaseAuth instance for synchronous checks
  final _firebaseAuthInstance = firebase_auth.FirebaseAuth.instance;
  late final GoRouter router;

  AppRouter({required this.authRepository}) {
    router = GoRouter(
      // Use the auth repository's user stream for refresh
      // This triggers redirection logic when auth state changes
      refreshListenable: GoRouterRefreshStream(authRepository.user),
      initialLocation: '/', // Start at home or let redirect handle it
      debugLogDiagnostics: true, // Enable verbose logging for debugging
      routes: _routes,
      redirect: _redirectLogic,
    );
  }

  // --- Route Definitions ---
  static final List<GoRoute> _routes = [
    // Home Screen
    GoRoute(
      path: '/',
      name: 'home',
      builder: (context, state) => const HomeScreen(),
    ),
    // Login Screen
    GoRoute(
      path: '/login',
      name: 'login',
      builder: (context, state) => const LoginScreen(),
    ),
    // Signup Screen
    GoRoute(
      path: '/signup',
      name: 'signup',
      builder: (context, state) => const SignUpScreen(),
    ),
    // Game Screen
    GoRoute(
      path: '/game/:gameId', // Use path parameters for gameId
      name: 'game',
      builder: (context, state) {
        final gameId = state.pathParameters['gameId'];
        if (gameId == null) {
          // Should not happen if path matches, but handle defensively
          // Consider redirecting to home or showing an error screen
          return const Scaffold(body: Center(child: Text('Error: Missing Game ID in path')));
        }

        // Provide GameCubit here using BlocProvider
        // This context correctly inherits repositories from main.dart
        return BlocProvider<GameCubit>(
          create: (ctx) => GameCubit(
            gameId: gameId,
            gameRepository: context.read<GameRepository>(),
            questionRepository: context.read<QuestionRepository>(),
            authRepository: context.read<AuthRepository>(),
          ),
          child: GameScreen(gameId: gameId),
        );
      },
    ),
  ];

  // --- Redirection Logic ---
  FutureOr<String?> _redirectLogic(BuildContext context, GoRouterState state) {
    // Check current user status SYNCHRONOUSLY for redirection
    final bool loggedIn = _firebaseAuthInstance.currentUser != null;
    final bool loggingIn = state.matchedLocation == '/login' || state.matchedLocation == '/signup';

    // If user is not logged in and not trying to access login/signup, redirect to login.
    if (!loggedIn && !loggingIn) {
      return '/login';
    }

    // If user is logged in and trying to access login/signup, redirect to home.
    if (loggedIn && loggingIn) {
      return '/';
    }

    // No redirect needed.
    return null;
  }
}

// Helper class to listen to a Stream for GoRouter refresh
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
} 