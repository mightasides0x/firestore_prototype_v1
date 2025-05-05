import 'package:firestore_prototype_v1/features/topic/domain/entities/topic.dart'; // Updated path

// Contract for fetching topic data
abstract class TopicRepository {
  Future<List<Topic>> getTopics();
  // Add other methods like getRandomTopicId() here later if needed
} 