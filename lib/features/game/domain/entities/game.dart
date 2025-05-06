import 'package:cloud_firestore/cloud_firestore.dart'; // For Timestamp
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
  final Map<String, Map<String, dynamic>> player1Answers; // { questionId: { 'answerIndex': int, 'timeTakenMs': int, 'isCorrect': bool } }
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

  // Factory constructor for creating from Firestore data
  factory Game.fromFirestore(String id, Map<String, dynamic> data) {
    // Safely parse map fields, defaulting to empty maps if null/missing
    final Map<String, Map<String, dynamic>> p1Answers = {};
    (data['player1Answers'] as Map<String, dynamic>? ?? {}).forEach((key, value) {
      if (value is Map<String, dynamic>) {
        p1Answers[key] = value;
      }
    });

    final Map<String, Map<String, dynamic>> p2Answers = {};
    (data['player2Answers'] as Map<String, dynamic>? ?? {}).forEach((key, value) {
      if (value is Map<String, dynamic>) {
        p2Answers[key] = value;
      }
    });

    return Game(
      id: id,
      topicId: data['topicId'] as String? ?? '',
      questionIds: List<String>.from(data['questionIds'] as List<dynamic>? ?? []),
      player1Id: data['player1Id'] as String? ?? '',
      player2Id: data['player2Id'] as String? ?? '',
      player1Score: data['player1Score'] as int? ?? 0,
      player2Score: data['player2Score'] as int? ?? 0,
      player1Answers: p1Answers,
      player2Answers: p2Answers,
      currentQuestionIndex: data['currentQuestionIndex'] as int? ?? 0,
      player1ReadyForNext: data['player1ReadyForNext'] as bool? ?? false,
      player2ReadyForNext: data['player2ReadyForNext'] as bool? ?? false,
      status: data['status'] as String? ?? 'unknown',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }
} 