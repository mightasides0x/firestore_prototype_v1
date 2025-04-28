import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logging/logging.dart';

// Import Repository and Cubit
import 'package:firestore_prototype_v1/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:firestore_prototype_v1/features/auth/domain/repositories/auth_repository.dart';
import 'package:firestore_prototype_v1/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:firestore_prototype_v1/features/auth/presentation/screens/login_screen.dart';
import 'package:firestore_prototype_v1/features/auth/presentation/screens/signup_screen.dart';
import 'package:firestore_prototype_v1/features/home/presentation/screens/home_screen.dart';

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

  // Instantiate the repository
  final authRepository = AuthRepositoryImpl();

  runApp(MyApp(authRepository: authRepository));
}

class MyApp extends StatelessWidget {
  final AuthRepository authRepository;

  const MyApp({super.key, required this.authRepository});

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider.value(
      value: authRepository,
      child: BlocProvider(
        create: (_) => AuthCubit(authRepository: authRepository),
        child: BlocBuilder<AuthCubit, AuthState>(
          builder: (context, state) {
            return MaterialApp(
              title: 'Flutter Demo',
              debugShowCheckedModeBanner: false,
              theme: ThemeData(
                colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
              ),
              home: _buildHome(state),
              routes: {
                '/login': (context) => const LoginScreen(),
                '/signup': (context) => const SignUpScreen(),
                '/home': (context) => const HomeScreen(),
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildHome(AuthState state) {
    if (state is Authenticated) {
      return const HomeScreen();
    } else {
      return const LoginScreen();
    }
  }
}
