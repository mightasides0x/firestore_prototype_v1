import 'package:firestore_prototype_v1/features/game/domain/entities/game.dart';

// Contract for game-related data operations
abstract class GameRepository {
  /// Retrieves a real-time stream of the game state for the given game ID.
  Stream<Game> getGameStream(String gameId);

  /// Submits a player's answer for a specific question in the game.
  Future<void> submitAnswer({
    required String gameId,
    required String userId,
    required String questionId,
    required int answerIndex,
    required int timeTakenMs,
    required bool isCorrect, // Pre-calculated correctness might simplify Firestore logic
  });

  /// Updates the game state to advance to the next question.
  /// Typically called by Player 1 when both players are ready.
  Future<void> advanceToNextQuestion(String gameId);

  /// Updates the player's readiness status for the current question.
  /// (Alternative to submitting answer - might be needed if player times out without answering)
  Future<void> setPlayerReadyStatus({
      required String gameId,
      required String userId,
      required bool isReady,
  });
} 