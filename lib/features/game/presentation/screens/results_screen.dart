import 'package:flutter/material.dart';
import 'package:firestore_prototype_v1/features/game/domain/entities/game.dart';
import 'package:go_router/go_router.dart';

class ResultsScreen extends StatelessWidget {
  static const routeName = '/results'; // Define a route name

  final Game finalGame;

  const ResultsScreen({super.key, required this.finalGame});

  String _getWinnerMessage() {
    // Determine winner based on scores
    // This logic can be enhanced or moved to the Game entity if more complex
    if (finalGame.player1Score > finalGame.player2Score) {
      // Assuming we know or can fetch player names/aliases later
      // For now, just using Player ID or a generic "Player 1"
      return 'Player 1 Wins!'; // Replace with actual player identifier if available
    } else if (finalGame.player2Score > finalGame.player1Score) {
      return 'Player 2 Wins!'; // Replace with actual player identifier if available
    } else {
      return 'It\'s a Draw!';
    }
  }

  @override
  Widget build(BuildContext context) {
    final winnerMessage = _getWinnerMessage();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Game Results'),
        automaticallyImplyLeading: false, // No back button to game screen
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Game Over!',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Text(
                        'Final Scores',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Player 1: ${finalGame.player1Score}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Player 2: ${finalGame.player2Score}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                winnerMessage,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: winnerMessage.contains('Draw') ? Colors.blue : Colors.green,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: () {
                  // Navigate to Home Screen (Topic Selection)
                  context.go('/'); 
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                ),
                child: const Text('Play Again (New Topic)'),
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () {
                  // Navigate to Home Screen (Topic Selection)
                  context.go('/');
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                ),
                child: const Text('Return to Home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 