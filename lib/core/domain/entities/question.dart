import 'package:equatable/equatable.dart';

class Question extends Equatable {
  final String id; // Firestore document ID
  final String topicId;
  final String text;
  final List<String> options;
  final int correctAnswerIndex;

  const Question({
    required this.id,
    required this.topicId,
    required this.text,
    required this.options,
    required this.correctAnswerIndex,
  });

  @override
  List<Object?> get props => [id, topicId, text, options, correctAnswerIndex];

  factory Question.fromFirestore(String id, Map<String, dynamic> data) {
    // Basic type checking and default values for robustness
    return Question(
      id: id,
      topicId: data['topicId'] as String? ?? '',
      text: data['text'] as String? ?? 'Missing question text',
      options: List<String>.from(data['options'] as List<dynamic>? ?? []),
      correctAnswerIndex: data['correctAnswerIndex'] as int? ?? -1,
    );
  }

  // Helper to check if the data seems valid
  bool get isValid =>
      id.isNotEmpty &&
      topicId.isNotEmpty &&
      text != 'Missing question text' &&
      options.isNotEmpty &&
      correctAnswerIndex >= 0 &&
      correctAnswerIndex < options.length;
} 