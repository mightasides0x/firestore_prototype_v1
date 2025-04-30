import 'package:firestore_prototype_v1/core/domain/entities/topic.dart';

// Contract for fetching topic data
abstract class TopicRepository {
  Future<List<Topic>> getTopics();
} 