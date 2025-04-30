import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firestore_prototype_v1/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth; // Import User type

// Import Home feature dependencies
import 'package:firestore_prototype_v1/features/home/data/repositories/topic_repository_impl.dart';
import 'package:firestore_prototype_v1/features/home/domain/repositories/topic_repository.dart';
import 'package:firestore_prototype_v1/features/home/presentation/cubit/topic_selection_cubit.dart';
import 'package:firestore_prototype_v1/core/domain/entities/topic.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Auth state needed for welcome message & verification status
    final authState = context.watch<AuthCubit>().state;
    firebase_auth.User? user;
    if (authState is Authenticated) {
      user = authState.user;
    }
    if (user == null) {
      // This should ideally not happen due to the router logic in main.dart
      // If it does, navigate back to login or show an error state
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacementNamed('/login');
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final bool isVerified = user.emailVerified;

    // Provide Topic Repository & Cubit specifically for this screen/feature area
    return BlocProvider(
      create: (context) => TopicSelectionCubit(
        // Use RepositoryProvider.of if repository was provided higher up,
        // otherwise instantiate directly (simpler for now)
        topicRepository: TopicRepositoryImpl(),
      )..loadTopics(), // Load topics immediately when cubit is created
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Select a Topic'), // Changed title
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Logout',
              onPressed: () {
                context.read<AuthCubit>().logOut();
              },
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Welcome & Verification Section
              Text(
                'Welcome, ${user.email}!',
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              if (!isVerified)
                Card(
                   color: Colors.amber.shade100,
                   child: const Padding(
                     padding: EdgeInsets.all(8.0),
                     child: Row(children: [ /* ... unverified content ... */ ]),
                   ),
                 )
              else
                 Card(
                   color: Colors.green.shade100,
                   child: const Padding(
                     padding: EdgeInsets.all(8.0),
                     child: Row(children: [ /* ... verified content ... */ ]),
                   ),
                 ),

              const SizedBox(height: 24),
              Text(
                'Choose a topic to start a quiz:',
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              // Topic List Section (Task 2.6 - Connect UI to Cubit)
              Expanded(
                child: BlocBuilder<TopicSelectionCubit, TopicSelectionState>(
                  builder: (context, state) {
                    if (state is TopicSelectionLoading || state is TopicSelectionInitial) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (state is TopicSelectionError) {
                      return Center(
                        child: Text(
                          'Error loading topics: ${state.message}\nPlease try again later.',
                          textAlign: TextAlign.center,
                        ),
                      );
                    }
                    if (state is TopicSelectionLoaded) {
                      if (state.topics.isEmpty) {
                        return const Center(child: Text('No topics available right now.'));
                      }
                      // Build the list/grid using state.topics
                      return ListView.builder(
                        itemCount: state.topics.length,
                        itemBuilder: (context, index) {
                          final topic = state.topics[index];
                          return Card(
                            child: ListTile(
                              title: Text(topic.name),
                              trailing: const Icon(Icons.play_arrow),
                              onTap: () {
                                // TODO: Trigger matchmaking for this topic (Phase 3)
                                print('Selected Topic: ${topic.name} (ID: ${topic.id})');
                              },
                            ),
                          );
                        },
                      );
                    }
                    // Should not happen, but fallback
                    return const Center(child: Text('Something went wrong.'));
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Helper widgets for verification cards (to keep build method cleaner)
// (You can paste the previous Card widgets here) 