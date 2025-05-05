import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firestore_prototype_v1/features/game/domain/entities/game.dart';
import 'package:firestore_prototype_v1/features/game/domain/repositories/game_repository.dart';
import 'package:logging/logging.dart';

class GameRepositoryImpl implements GameRepository {
  final FirebaseFirestore _firestore;
  static final _log = Logger('GameRepositoryImpl');

  // Constants for Firestore field names
  static const String _gamesCollection = 'games';
  static const String _fieldPlayer1Id = 'player1Id';
  static const String _fieldPlayer2Id = 'player2Id';
  static const String _fieldPlayer1Score = 'player1Score';
  static const String _fieldPlayer2Score = 'player2Score';
  static const String _fieldPlayer1Answers = 'player1Answers';
  static const String _fieldPlayer2Answers = 'player2Answers';
  static const String _fieldTopicId = 'topicId';
  static const String _fieldQuestionIds = 'questionIds';
  static const String _fieldCurrentQuestionIndex = 'currentQuestionIndex';
  static const String _fieldPlayer1ReadyForNext = 'player1ReadyForNext';
  static const String _fieldPlayer2ReadyForNext = 'player2ReadyForNext';
  static const String _fieldCreatedAt = 'createdAt';
  static const String _fieldStatus = 'status';

  GameRepositoryImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Stream<Game> getGameStream(String gameId) {
    _log.info('Subscribing to game stream for $gameId');
    final docRef = _firestore.collection(_gamesCollection).doc(gameId);
    return docRef.snapshots().map(_gameFromSnapshot).handleError((error, stackTrace) {
       _log.severe('Error in game stream for $gameId', error, stackTrace);
       // Rethrow the error to be handled by the listener (e.g., in GameCubit)
       throw error;
    });
  }

  @override
  Future<void> submitAnswer({
    required String gameId,
    required String userId,
    required String questionId,
    required int answerIndex,
    required int timeTakenMs,
    required bool isCorrect,
  }) async {
    _log.info('Submitting answer for game $gameId, user $userId, question $questionId');
    final docRef = _firestore.collection(_gamesCollection).doc(gameId);

    // Determine which player fields to update based on userId
    // Fetch the game doc once to know who is player1 vs player2
    try {
      final gameDoc = await docRef.get();
      if (!gameDoc.exists || gameDoc.data() == null) {
         throw Exception('Game document $gameId not found for submitAnswer.');
      }
      final gameData = gameDoc.data()!;
      final bool isPlayer1 = gameData[_fieldPlayer1Id] == userId;

      final scoreField = isPlayer1 ? _fieldPlayer1Score : _fieldPlayer2Score;
      final answersField = isPlayer1 ? _fieldPlayer1Answers : _fieldPlayer2Answers;
      final readyField = isPlayer1 ? _fieldPlayer1ReadyForNext : _fieldPlayer2ReadyForNext;

      // Calculate score delta (simple example: 10 points for correct, 0 otherwise)
      // TODO: Implement more sophisticated scoring (e.g., based on timeTakenMs)
      final scoreDelta = isCorrect ? 10 : 0;

      // Prepare update data
      final updateData = {
        // Update nested answer map using dot notation
        '$answersField.$questionId': {
          'answerIndex': answerIndex,
          'timeTakenMs': timeTakenMs,
          'isCorrect': isCorrect,
        },
        // Increment score
        scoreField: FieldValue.increment(scoreDelta),
        // Set player ready for next question
        readyField: true,
      };

       _log.finer('Updating game $gameId with data: $updateData');
      await docRef.update(updateData);
       _log.info('Answer submitted successfully for game $gameId, user $userId');

    } catch (e, stackTrace) {
      _log.severe('Error submitting answer for game $gameId, user $userId', e, stackTrace);
      throw Exception('Failed to submit answer: ${e.toString()}');
    }
  }

  @override
  Future<void> advanceToNextQuestion(String gameId) async {
    _log.info('Advancing to next question for game $gameId');
    final docRef = _firestore.collection(_gamesCollection).doc(gameId);

    try {
      await docRef.update({
        _fieldCurrentQuestionIndex: FieldValue.increment(1),
        _fieldPlayer1ReadyForNext: false,
        _fieldPlayer2ReadyForNext: false,
      });
      _log.info('Game $gameId advanced to next question successfully.');
    } catch (e, stackTrace) {
      _log.severe('Error advancing to next question for game $gameId', e, stackTrace);
      throw Exception('Failed to advance to next question: ${e.toString()}');
    }
  }

  @override
  Future<void> setPlayerReadyStatus({
    required String gameId,
    required String userId,
    required bool isReady,
  }) async {
     _log.info('Setting ready status for game $gameId, user $userId to $isReady');
    final docRef = _firestore.collection(_gamesCollection).doc(gameId);

    try {
      final gameDoc = await docRef.get();
      if (!gameDoc.exists || gameDoc.data() == null) {
         throw Exception('Game document $gameId not found for setPlayerReadyStatus.');
      }
      final gameData = gameDoc.data()!;
      final bool isPlayer1 = gameData[_fieldPlayer1Id] == userId;

      final readyField = isPlayer1 ? _fieldPlayer1ReadyForNext : _fieldPlayer2ReadyForNext;

      await docRef.update({readyField: isReady});
      _log.info('Player ready status updated successfully for game $gameId, user $userId');

    } catch (e, stackTrace) {
       _log.severe('Error setting player ready status for game $gameId, user $userId', e, stackTrace);
       throw Exception('Failed to set player ready status: ${e.toString()}');
    }
  }

  // Helper factory method to parse Firestore data into Game entity
  Game _gameFromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) {
      throw Exception('Game document data is null for ID: ${doc.id}');
    }

    // Safely parse map fields, defaulting to empty maps if null/missing
    final Map<String, Map<String, dynamic>> player1Answers = {};
    (data[_fieldPlayer1Answers] as Map<String, dynamic>? ?? {}).forEach((key, value) {
      if (value is Map<String, dynamic>) {
        player1Answers[key] = value;
      }
    });

    final Map<String, Map<String, dynamic>> player2Answers = {};
    (data[_fieldPlayer2Answers] as Map<String, dynamic>? ?? {}).forEach((key, value) {
      if (value is Map<String, dynamic>) {
        player2Answers[key] = value;
      }
    });

    return Game(
      id: doc.id,
      topicId: data[_fieldTopicId] ?? '',
      questionIds: List<String>.from(data[_fieldQuestionIds] ?? []),
      player1Id: data[_fieldPlayer1Id] ?? '',
      player2Id: data[_fieldPlayer2Id] ?? '',
      player1Score: data[_fieldPlayer1Score] ?? 0,
      player2Score: data[_fieldPlayer2Score] ?? 0,
      player1Answers: player1Answers,
      player2Answers: player2Answers,
      currentQuestionIndex: data[_fieldCurrentQuestionIndex] ?? 0,
      player1ReadyForNext: data[_fieldPlayer1ReadyForNext] ?? false,
      player2ReadyForNext: data[_fieldPlayer2ReadyForNext] ?? false,
      status: data[_fieldStatus] ?? 'unknown',
      createdAt: (data[_fieldCreatedAt] as Timestamp?)?.toDate(),
    );
  }
} 