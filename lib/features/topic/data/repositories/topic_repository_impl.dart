import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firestore_prototype_v1/features/topic/domain/entities/topic.dart'; // Updated path
import 'package:firestore_prototype_v1/features/topic/domain/repositories/topic_repository.dart'; // Updated path
import 'package:logging/logging.dart';

class TopicRepositoryImpl implements TopicRepository {
  final FirebaseFirestore _firestore;
  static final _log = Logger('TopicRepositoryImpl');

  TopicRepositoryImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<List<Topic>> getTopics() async {
    _log.info('Fetching topics from Firestore...');
    try {
      final snapshot = await _firestore.collection('topics').get();

      final topics = snapshot.docs.map((doc) {
        try {
          return Topic.fromFirestore(doc.id, doc.data());
        } catch (e, stackTrace) {
          _log.severe('Error parsing topic document ${doc.id}', e, stackTrace);
          return null; // Skip invalid documents
        }
      }).whereType<Topic>().toList(); // Filter out nulls from failed parsing

      _log.info('Fetched ${topics.length} topics successfully.');
      return topics;
    } catch (e, stackTrace) {
      _log.severe('Error fetching topics from Firestore', e, stackTrace);
      // Re-throw as a more specific exception or handle appropriately
      throw Exception('Failed to fetch topics: $e');
    }
  }
} 