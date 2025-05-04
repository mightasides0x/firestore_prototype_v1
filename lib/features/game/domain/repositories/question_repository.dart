import 'package:firestore_prototype_v1/core/models/question.dart';

// Contract for fetching question data
abstract class QuestionRepository {
  // Fetch multiple questions based on a list of IDs
  Future<List<Question>> getQuestionsByIds(List<String> ids);

  // Fetch a list of question IDs for a specific topic, optionally limited.
  Future<List<String>> getQuestionIdsByTopic(String topicId, {int? limit});

  // Optional: Fetch a single question by ID (might be useful)
  // Future<Question?> getQuestionById(String id);
} 