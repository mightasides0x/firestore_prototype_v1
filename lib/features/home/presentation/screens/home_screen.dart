import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firestore_prototype_v1/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth; // Import User type

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthCubit>().state;
    firebase_auth.User? user; // Use nullable User

    if (authState is Authenticated) {
      user = authState.user;
    }

    // Handle case where state might not be Authenticated (though router should prevent this)
    if (user == null) {
      return const Scaffold(body: Center(child: Text('Error: User not authenticated.')));
    }

    final bool isVerified = user.emailVerified;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Home - Topics Placeholder'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () {
              // Call logout method (Task 1.8)
              context.read<AuthCubit>().logOut();
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'Welcome, ${user.email}!',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            if (!isVerified)
              Card(
                color: Colors.amber.shade100,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: Colors.amber),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Your email is not verified. Please check your inbox for a verification link.',
                        ),
                      ),
                      // TODO: Add a 'Resend Verification' button?
                    ],
                  ),
                ),
              )
            else
              Card(
                color: Colors.green.shade100,
                child: const Padding(
                  padding: EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle_outline, color: Colors.green),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text('Your email is verified.'),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 40),
            const Text('Topic Selection will go here...'),
            // TODO: Add Topic Selection UI (Phase 2)
          ],
        ),
      ),
    );
  }
} 