import 'package:equatable/equatable.dart';
import 'package:firestore_prototype_v1/features/game/domain/entities/game.dart';
import 'package:firestore_prototype_v1/features/game/domain/entities/question.dart';

abstract class GameState extends Equatable {
  const GameState();

  @override
  List<Object?> get props => [];
}

/// Initial state before loading game data.
class GameInitial extends GameState {
  const GameInitial();
}

/// State while loading the initial game or question data.
class GameLoading extends GameState {
  final String gameId;
  const GameLoading({required this.gameId});

  @override
  List<Object?> get props => [gameId];
}

/// State when the game and current question data are loaded and ready.
class GameReady extends GameState {
  final Game game;
  final Question currentQuestion;
  final bool isPlayer1; // Useful flag for UI logic

  const GameReady({
    required this.game,
    required this.currentQuestion,
    required this.isPlayer1,
  });

  @override
  List<Object?> get props => [game, currentQuestion, isPlayer1];
}

/// State when the game has finished.
class GameFinished extends GameState {
  final Game finalGameState;
  final bool isPlayer1; // To know who won/lost from this user's perspective

  const GameFinished({required this.finalGameState, required this.isPlayer1});

  // Helper to determine winner
  String get winnerId {
    if (finalGameState.player1Score > finalGameState.player2Score) {
      return finalGameState.player1Id;
    } else if (finalGameState.player2Score > finalGameState.player1Score) {
      return finalGameState.player2Id;
    } else {
      return 'draw'; // Special ID for a draw
    }
  }

  @override
  List<Object?> get props => [finalGameState, isPlayer1];
}

/// State when an error occurs during game loading or gameplay actions.
class GameError extends GameState {
  final String message;
  const GameError({required this.message});

  @override
  List<Object?> get props => [message];
} 