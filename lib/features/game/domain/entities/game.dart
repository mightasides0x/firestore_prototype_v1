import 'package:equatable/equatable.dart';

// Represents the state of a single game instance
class Game extends Equatable {
  final String id; // Firestore document ID
  final String topicId;
  final List<String> questionIds;
  final String player1Id;
  final String player2Id;
  final int player1Score;
  final int player2Score;
  final Map<String, Map<String, dynamic>> player1Answers; // { questionId: { 'answerIndex': int, 'timeTakenMs': int } }
  final Map<String, Map<String, dynamic>> player2Answers;
  final int currentQuestionIndex;
  final bool player1ReadyForNext;
  final bool player2ReadyForNext;
  final String status; // e.g., 'pending', 'active', 'finished'
  final DateTime? createdAt; // Firestore timestamp converted

  const Game({
    required this.id,
    required this.topicId,
    required this.questionIds,
    required this.player1Id,
    required this.player2Id,
    required this.player1Score,
    required this.player2Score,
    required this.player1Answers,
    required this.player2Answers,
    required this.currentQuestionIndex,
    required this.player1ReadyForNext,
    required this.player2ReadyForNext,
    required this.status,
    this.createdAt,
  });

  @override
  List<Object?> get props => [
        id,
        topicId,
        questionIds,
        player1Id,
        player2Id,
        player1Score,
        player2Score,
        player1Answers,
        player2Answers,
        currentQuestionIndex,
        player1ReadyForNext,
        player2ReadyForNext,
        status,
        createdAt,
      ];

  // TODO: Implement fromFirestore factory method
  // factory Game.fromFirestore(String id, Map<String, dynamic> data) { ... }
} 