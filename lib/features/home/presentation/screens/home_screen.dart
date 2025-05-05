import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firestore_prototype_v1/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth; // Import User type

// Import Home feature dependencies
import 'package:firestore_prototype_v1/features/topic/domain/entities/topic.dart'; // Updated path
import 'package:firestore_prototype_v1/features/home/presentation/cubit/home_cubit.dart'; // Renamed cubit
import 'package:firestore_prototype_v1/features/home/presentation/cubit/home_state.dart'; // Renamed state
import 'package:firestore_prototype_v1/features/matchmaking/presentation/cubit/matchmaking_cubit.dart';
// Import matchmaking state for listener
import 'package:firestore_prototype_v1/features/matchmaking/presentation/cubit/matchmaking_state.dart';
import 'package:firestore_prototype_v1/features/game/presentation/screens/game_screen.dart';
import 'package:go_router/go_router.dart';

// Helper variable to track if the dialog is currently shown
// Note: Using a global variable like this isn't ideal for complex scenarios,
// but simple enough for MVP. A better approach might involve managing
// the dialog state within the HomeScreen's State object if it were StatefulWidget.
bool _isMatchmakingDialogShowing = false;

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  // Helper method to show the dialog
  void _showWaitingDialog(BuildContext context, String topicId) {
    if (_isMatchmakingDialogShowing) return; // Prevent multiple dialogs
    _isMatchmakingDialogShowing = true;
    showDialog(
      context: context,
      barrierDismissible: false, // User cannot dismiss by tapping outside
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Searching for Opponent...'),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 20),
              Text('Waiting for another player...'),
            ],
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                // Call cancelSearch BEFORE dismissing dialog
                context.read<MatchmakingCubit>().cancelSearch();
                // Dismissal will be handled by the BlocListener when state changes
              },
            ),
          ],
        );
      },
    ).then((_) {
      // This is called when the dialog is dismissed programmatically
      _isMatchmakingDialogShowing = false;
    });
  }

  // Helper method to dismiss the dialog
  void _dismissWaitingDialog(BuildContext context) {
    if (_isMatchmakingDialogShowing) {
      Navigator.of(context).pop(); // Dismiss the dialog
      _isMatchmakingDialogShowing = false;
    }
  }

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

    // Remove local BlocProvider for TopicSelectionCubit
    // return BlocProvider(
    //   create: (context) => TopicSelectionCubit(
    //     topicRepository: context.read<TopicRepository>(), // Get from provider
    //   )..loadTopics(),
    //   child: BlocListener<MatchmakingCubit, MatchmakingState>(
    return BlocListener<MatchmakingCubit, MatchmakingState>(
      listener: (context, matchmakingState) {
        // Dismiss dialog if it's showing and we are no longer searching
        if (matchmakingState is! MatchmakingSearching && _isMatchmakingDialogShowing) {
           _dismissWaitingDialog(context);
        }

        // Show dialog when searching starts
        if (matchmakingState is MatchmakingSearching) {
          _showWaitingDialog(context, matchmakingState.topicId);
        }
        // Show error snackbar on failure
        else if (matchmakingState is MatchmakingFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Matchmaking Failed: ${matchmakingState.message}'),
              backgroundColor: Colors.red,
            ),
          );
        }
        // Navigate on success
        else if (matchmakingState is MatchmakingSuccess) {
          print('Matchmaking Success! Navigating to Game Screen for game: ${matchmakingState.gameId}');
          context.push('/game/${matchmakingState.gameId}');
        }
        // Handle cancelled state AND dismiss dialog
        else if (matchmakingState is MatchmakingCancelled) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Matchmaking Cancelled'),
              backgroundColor: Colors.red,
            ),
          );
          _dismissWaitingDialog(context);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Select a Topic'),
          actions: [
            // Temporary button to clear user's match state
            IconButton(
              icon: const Icon(Icons.cleaning_services),
              tooltip: 'Clear Match State',
              onPressed: () async {
                 // Prevent action while searching for a match
                 if (context.read<MatchmakingCubit>().state is MatchmakingSearching) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Cannot clear state while searching.')),
                    );
                    return;
                  }
                 try {
                    await context.read<AuthCubit>().clearMatchId();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Match state cleared successfully.'),
                        backgroundColor: Colors.green,
                      ),
                    );
                 } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to clear match state: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                 }
              },
            ),
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Logout',
              onPressed: () {
                // Prevent logout while searching for a match
                if (context.read<MatchmakingCubit>().state is MatchmakingSearching) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please cancel matchmaking before logging out.')),
                  );
                  return;
                }
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

              // Topic List Section
              Expanded(
                child: BlocBuilder<HomeCubit, HomeState>(
                  builder: (context, homeState) { // Renamed state variable
                    if (homeState is HomeLoading || homeState is HomeInitial) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (homeState is HomeError) {
                      return Center(
                        child: Text(
                          'Error loading topics: ${homeState.message}\nPlease try again later.',
                          textAlign: TextAlign.center,
                        ),
                      );
                    }
                    if (homeState is HomeLoaded) {
                      if (homeState.topics.isEmpty) {
                        return const Center(child: Text('No topics available right now.'));
                      }
                      // Build the list/grid using state.topics
                      return ListView.builder(
                        itemCount: homeState.topics.length,
                        itemBuilder: (context, index) {
                          final topic = homeState.topics[index]; // Use topic from HomeLoaded
                          return Card(
                            child: BlocBuilder<MatchmakingCubit, MatchmakingState>(
                              builder: (context, matchmakingState) {
                                final bool isSearching = matchmakingState is MatchmakingSearching;
                                return ListTile(
                                  title: Text(topic.name),
                                  trailing: const Icon(Icons.play_arrow),
                                  enabled: !isSearching,
                                  onTap: isSearching ? null : () {
                                    print('Starting matchmaking for Topic: ${topic.name} (ID: ${topic.id})');
                                    context.read<MatchmakingCubit>().findMatch(topic.id);
                                  },
                                );
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