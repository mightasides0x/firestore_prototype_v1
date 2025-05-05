import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firestore_prototype_v1/features/game/presentation/cubit/game_cubit.dart';
import 'package:firestore_prototype_v1/features/game/presentation/cubit/game_state.dart';

class GameScreen extends StatelessWidget {
  static const routeName = '/game';

  final String gameId;

  const GameScreen({super.key, required this.gameId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Game'), // Simpler title
      ),
      // Use BlocBuilder to react to GameState changes
      body: BlocBuilder<GameCubit, GameState>(
        builder: (context, state) {
          // Loading State
          if (state is GameLoading || state is GameInitial) {
            return const Center(
              child: Column(
                 mainAxisSize: MainAxisSize.min,
                 children: [
                   CircularProgressIndicator(),
                   SizedBox(height: 16),
                   Text('Loading Game...'),
                 ],
               ),
            );
          }
          // Error State
          if (state is GameError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Error: ${state.message}',
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          // Game Ready State
          if (state is GameReady) {
            // TODO: Build the main game UI (Score, Question, Options)
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Game Ready!', style: TextStyle(fontSize: 24)),
                  SizedBox(height: 10),
                  Text('Game ID: ${state.game.id}'),
                  Text('Topic ID: ${state.game.topicId}'),
                  Text('Player 1: ${state.game.player1Id} (Score: ${state.game.player1Score})'),
                  Text('Player 2: ${state.game.player2Id} (Score: ${state.game.player2Score})'),
                  SizedBox(height: 20),
                  Text('Current Question (${state.game.currentQuestionIndex + 1}/${state.game.questionIds.length}):'),
                  Text('${state.currentQuestion.text}', style: TextStyle(fontSize: 18)),
                  // Display Options later
                ],
              ),
            );
          }
          // Game Finished State
          if (state is GameFinished) {
            // TODO: Build the results UI
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Game Finished!', style: TextStyle(fontSize: 24)),
                  SizedBox(height: 10),
                  Text('Game ID: ${state.finalGameState.id}'),
                  Text('Player 1 Score: ${state.finalGameState.player1Score}'),
                  Text('Player 2 Score: ${state.finalGameState.player2Score}'),
                  SizedBox(height: 20),
                   Text('Winner: ${state.winnerId}', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  // Add Play Again button later
                ],
              ),
            );
          }

          // Fallback (should not be reached)
          return const Center(child: Text('Unknown game state.'));
        },
      ),
    );
  }
} 