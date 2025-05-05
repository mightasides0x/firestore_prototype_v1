import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logging/logging.dart';
import 'package:go_router/go_router.dart';

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
import 'package:firestore_prototype_v1/features/game/domain/repositories/game_repository.dart';
import 'package:firestore_prototype_v1/features/game/data/repositories/game_repository_impl.dart';

// Matchmaking Feature
import 'package:firestore_prototype_v1/features/matchmaking/data/repositories/matchmaking_repository_impl.dart';
import 'package:firestore_prototype_v1/features/matchmaking/domain/repositories/matchmaking_repository.dart';
import 'package:firestore_prototype_v1/features/matchmaking/presentation/cubit/matchmaking_cubit.dart';

// Import GameScreen and GameCubit
import 'package:firestore_prototype_v1/features/game/presentation/screens/game_screen.dart';
import 'package:firestore_prototype_v1/features/game/presentation/cubit/game_cubit.dart';

// Import the AppRouter
import 'package:firestore_prototype_v1/core/navigation/app_router.dart';

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
  final gameRepository = GameRepositoryImpl(firestore: firestore);

  // Create the router instance
  final appRouter = AppRouter(authRepository: authRepository);

  runApp(MyApp(
    authRepository: authRepository,
    topicRepository: topicRepository,
    questionRepository: questionRepository,
    matchmakingRepository: matchmakingRepository,
    gameRepository: gameRepository,
    router: appRouter.router, // Pass the GoRouter instance
  ));
}

class MyApp extends StatelessWidget {
  final AuthRepository authRepository;
  final TopicRepository topicRepository;
  final QuestionRepository questionRepository;
  final MatchmakingRepository matchmakingRepository;
  final GameRepository gameRepository;
  final GoRouter router; // Add router property

  const MyApp({
    super.key,
    required this.authRepository,
    required this.topicRepository,
    required this.questionRepository,
    required this.matchmakingRepository,
    required this.gameRepository,
    required this.router, // Add to constructor
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
        RepositoryProvider.value(value: gameRepository),
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
        // Remove BlocBuilder<AuthCubit, AuthState>
        // Use MaterialApp.router instead of MaterialApp
        child: MaterialApp.router(
          title: 'Realtime Quiz',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
            useMaterial3: true,
          ),
          // Provide the router configuration
          routerConfig: router,
          // home, routes, onGenerateRoute are replaced by routerConfig
        ),
      ),
    );
  }
}
