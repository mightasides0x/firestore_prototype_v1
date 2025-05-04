import 'package:flutter/material.dart';

class GameScreen extends StatelessWidget {
  static const routeName = '/game';

  final String gameId;

  const GameScreen({super.key, required this.gameId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Game: $gameId'),
        // Automatically handles back navigation
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Game Screen Placeholder',
              style: TextStyle(fontSize: 24),
            ),
            const SizedBox(height: 20),
            Text('Game ID: $gameId'),
            // TODO: Implement actual game UI here
          ],
        ),
      ),
    );
  }
} 