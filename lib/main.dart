import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logging/logging.dart';

// Auth Feature
import 'package:firestore_prototype_v1/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:firestore_prototype_v1/features/auth/domain/repositories/auth_repository.dart';
import 'package:firestore_prototype_v1/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:firestore_prototype_v1/features/auth/presentation/screens/login_screen.dart';
import 'package:firestore_prototype_v1/features/auth/presentation/screens/signup_screen.dart';

// Home/Topic Feature
import 'package:firestore_prototype_v1/features/topic/data/repositories/topic_repository_impl.dart';
import 'package:firestore_prototype_v1/features/topic/domain/repositories/topic_repository.dart';
import 'package:firestore_prototype_v1/features/home/presentation/cubit/home_cubit.dart';
import 'package:firestore_prototype_v1/features/home/presentation/screens/home_screen.dart';

// Game Feature
import 'package:firestore_prototype_v1/features/game/data/repositories/question_repository_impl.dart';
import 'package:firestore_prototype_v1/features/game/domain/repositories/question_repository.dart';

// Matchmaking Feature
import 'package:firestore_prototype_v1/features/matchmaking/data/repositories/matchmaking_repository_impl.dart';
import 'package:firestore_prototype_v1/features/matchmaking/domain/repositories/matchmaking_repository.dart';
import 'package:firestore_prototype_v1/features/matchmaking/presentation/cubit/matchmaking_cubit.dart';

// Import GameScreen
import 'package:firestore_prototype_v1/features/game/presentation/screens/game_screen.dart';

void main() async {
  // Configure logging FIRST
  Logger.root.level = Level.ALL; // Log all levels
  Logger.root.onRecord.listen((record) {
    // Simple console output
    debugPrint('${record.level.name}: ${record.time}: ${record.loggerName}: ${record.message}');
    if (record.error != null) {
      debugPrint('Error: ${record.error}');
    }
    if (record.stackTrace != null) {
      debugPrint('StackTrace: ${record.stackTrace}');
    }
  });

  // Then initialize other bindings and services
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Instantiate dependencies
  final firebaseAuth = firebase_auth.FirebaseAuth.instance;
  final firestore = FirebaseFirestore.instance;

  final authRepository = AuthRepositoryImpl(firebaseAuth: firebaseAuth);
  final topicRepository = TopicRepositoryImpl(firestore: firestore);
  final questionRepository = QuestionRepositoryImpl(firestore: firestore);
  final matchmakingRepository = MatchmakingRepositoryImpl(firestore: firestore);

  runApp(MyApp(
    authRepository: authRepository,
    topicRepository: topicRepository,
    questionRepository: questionRepository,
    matchmakingRepository: matchmakingRepository,
  ));
}

class MyApp extends StatelessWidget {
  final AuthRepository authRepository;
  final TopicRepository topicRepository;
  final QuestionRepository questionRepository;
  final MatchmakingRepository matchmakingRepository;

  const MyApp({
    super.key,
    required this.authRepository,
    required this.topicRepository,
    required this.questionRepository,
    required this.matchmakingRepository,
  });

  @override
  Widget build(BuildContext context) {
    // Provide repositories first
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: authRepository),
        RepositoryProvider.value(value: topicRepository),
        RepositoryProvider.value(value: questionRepository),
        RepositoryProvider.value(value: matchmakingRepository),
      ],
      // Then provide Blocs/Cubits that depend on repositories
      child: MultiBlocProvider(
        providers: [
          BlocProvider<AuthCubit>(
            create: (_) => AuthCubit(authRepository: authRepository),
          ),
          // Renamed HomeCubit
          BlocProvider<HomeCubit>(
            create: (context) => HomeCubit(
              topicRepository: context.read<TopicRepository>(),
            )..loadTopics(),
          ),
          BlocProvider<MatchmakingCubit>(
            create: (context) => MatchmakingCubit(
              matchmakingRepository: context.read<MatchmakingRepository>(),
              authRepository: context.read<AuthRepository>(),
              questionRepository: context.read<QuestionRepository>(),
            ),
          ),
        ],
        child: BlocBuilder<AuthCubit, AuthState>(
          builder: (context, authState) {
            return MaterialApp(
              title: 'Realtime Quiz',
              debugShowCheckedModeBanner: false,
              theme: ThemeData(
                colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
                useMaterial3: true,
              ),
              home: _buildHome(authState),
              routes: {
                // Reverted to simple string routes
                '/login': (context) => const LoginScreen(),
                '/signup': (context) => const SignUpScreen(),
                '/home': (context) => const HomeScreen(),
                // Add GameScreen route
                GameScreen.routeName: (context) {
                  // Extract gameId from arguments
                  final gameId = ModalRoute.of(context)?.settings.arguments as String?;
                  // Handle cases where gameId might be null (e.g., navigating directly)
                  if (gameId == null) {
                    // Navigate back or show error
                    // For simplicity, return a placeholder or navigate home
                    print('Error: Navigated to GameScreen without gameId!');
                    return const Scaffold(
                      body: Center(child: Text('Error: Missing Game ID')),
                    );
                  }
                  return GameScreen(gameId: gameId);
                },
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildHome(AuthState state) {
    if (state is Authenticated) {
      // User is authenticated, show HomeScreen
      return const HomeScreen();
    } else {
      // User is not authenticated, show LoginScreen
      return const LoginScreen();
    }
  }
}
