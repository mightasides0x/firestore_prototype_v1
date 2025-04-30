import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firestore_prototype_v1/core/domain/entities/question.dart';
import 'package:firestore_prototype_v1/features/game/domain/repositories/question_repository.dart';
import 'package:logging/logging.dart';

class QuestionRepositoryImpl implements QuestionRepository {
  final FirebaseFirestore _firestore;
  static final _log = Logger('QuestionRepositoryImpl');

  QuestionRepositoryImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<List<Question>> getQuestionsByIds(List<String> ids) async {
    if (ids.isEmpty) {
      _log.info('getQuestionsByIds called with empty list, returning empty.');
      return [];
    }

    _log.info('Fetching ${ids.length} questions by IDs from Firestore...');
    try {
      // Firestore 'whereIn' query is efficient for up to 30 IDs at a time.
      // If more are needed, batching might be required, but unlikely for a single quiz game.
      if (ids.length > 30) {
        _log.warning('Attempting to fetch more than 30 questions by ID at once (${ids.length}). Consider batching.');
        // For MVP, proceed anyway, but be aware of potential limitations.
      }

      final snapshot = await _firestore
          .collection('questions')
          .where(FieldPath.documentId, whereIn: ids)
          .get();

      final questions = snapshot.docs.map((doc) {
        try {
          final question = Question.fromFirestore(doc.id, doc.data());
          if (!question.isValid) {
             _log.warning('Fetched question document ${doc.id} has invalid data, skipping.');
             return null;
          }
          return question;
        } catch (e, stackTrace) {
          _log.severe('Error parsing question document ${doc.id}', e, stackTrace);
          return null; // Skip invalid documents
        }
      }).whereType<Question>().toList();

      _log.info('Fetched ${questions.length} valid questions successfully.');

      // Optional: Check if all requested IDs were found
      if (questions.length != ids.length) {
          _log.warning('Could not find all requested question IDs. Requested: ${ids.length}, Found: ${questions.length}');
          // You might want to handle this case specifically depending on game logic
      }

      return questions;
    } catch (e, stackTrace) {
      _log.severe('Error fetching questions by IDs from Firestore', e, stackTrace);
      throw Exception('Failed to fetch questions by IDs: $e');
    }
  }
} 