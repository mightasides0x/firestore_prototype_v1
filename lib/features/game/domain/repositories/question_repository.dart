import 'package:firestore_prototype_v1/core/domain/entities/question.dart';

// Contract for fetching question data
abstract class QuestionRepository {
  // Fetch multiple questions based on a list of IDs
  Future<List<Question>> getQuestionsByIds(List<String> ids);

  // Optional: Fetch a single question by ID (might be useful)
  // Future<Question?> getQuestionById(String id);
} 