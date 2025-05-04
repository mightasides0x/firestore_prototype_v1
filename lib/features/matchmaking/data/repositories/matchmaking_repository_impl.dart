import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firestore_prototype_v1/features/matchmaking/domain/repositories/matchmaking_repository.dart';

class MatchmakingRepositoryImpl implements MatchmakingRepository {
  final FirebaseFirestore _firestore;

  // Collection/Document References (Consider moving to a constants file)
  static const String _matchmakingPoolCollection = 'matchmaking_pool';
  static const String _gamesCollection = 'games';
  static const String _usersCollection = 'users';

  // Field names - Matchmaking Pool
  static const String _fieldUserId = 'userId';
  static const String _fieldTopicId = 'topicId';
  static const String _fieldTimestamp = 'timestamp';

  // Field names - Games Collection
  static const String _fieldPlayer1Id = 'player1Id';
  static const String _fieldPlayer2Id = 'player2Id';
  static const String _fieldPlayer1Score = 'player1Score';
  static const String _fieldPlayer2Score = 'player2Score';
  static const String _fieldPlayer1Answers = 'player1Answers';
  static const String _fieldPlayer2Answers = 'player2Answers';
  // static const String _fieldTopicId = 'topicId'; // Reusing from pool fields
  static const String _fieldQuestionIds = 'questionIds';
  static const String _fieldCurrentQuestionIndex = 'currentQuestionIndex';
  static const String _fieldPlayer1ReadyForNext = 'player1ReadyForNext';
  static const String _fieldPlayer2ReadyForNext = 'player2ReadyForNext';
  static const String _fieldCreatedAt = 'createdAt';
  static const String _fieldStatus = 'status'; // e.g., 'pending', 'active', 'finished'

  // Field names - Users Collection
  static const String _fieldCurrentMatchId = 'currentMatchId';

  MatchmakingRepositoryImpl({required FirebaseFirestore firestore})
      : _firestore = firestore;

  @override
  Future<void> enterPool({required String userId, required String topicId}) async {
    try {
      final poolDocRef = _firestore
          .collection(_matchmakingPoolCollection)
          .doc(userId); // Use userId as doc ID for easy lookup/removal

      // Set the document with user info and timestamp
      await poolDocRef.set({
        _fieldUserId: userId,
        _fieldTopicId: topicId,
        _fieldTimestamp: FieldValue.serverTimestamp(), // Use server time
      });
      print('User $userId entered pool for topic $topicId');
    } catch (e) {
      print('Error entering matchmaking pool: $e');
      // Re-throw as a custom exception or handle appropriately
      // For now, just rethrowing the original exception
      rethrow;
    } // TODO: Add more specific error handling/custom exceptions
  }

  @override
  Future<String?> findOpponent({required String userId, required String topicId}) async {
    print('User $userId searching for opponent in topic $topicId');
    try {
      final querySnapshot = await _firestore
          .collection(_matchmakingPoolCollection)
          .where(_fieldTopicId, isEqualTo: topicId)
          // .where(_fieldUserId, isNotEqualTo: userId) // Firestore limitation: Inequality on different field than order/range
          .orderBy(_fieldTimestamp)
          // .limit(1) // Fetch more to filter client-side due to limitation
          .get();

      // Client-side filtering for userId inequality
      final potentialOpponents = querySnapshot.docs
          .where((doc) => doc.id != userId)
          .toList();

      if (potentialOpponents.isNotEmpty) {
        // The first one after filtering is the oldest opponent
        final opponentDoc = potentialOpponents.first;
        final opponentId = opponentDoc.id; // or opponentDoc.data()[_fieldUserId]
        print('Found opponent $opponentId for user $userId in topic $topicId');
        return opponentId;
      } else {
        print('No opponent found for user $userId in topic $topicId');
        return null;
      }
    } catch (e) {
      print('Error finding opponent: $e');
      // Re-throw as a custom exception or handle appropriately
      rethrow;
    } // TODO: Add more specific error handling/custom exceptions
  }

  @override
  Future<String?> createGame({
    required String userId1,
    required String userId2,
    required String topicId,
    required List<String> questionIds,
  }) async {
    print('Attempting to create game for $userId1 and $userId2 in topic $topicId');
    final gameDocRef = _firestore.collection(_gamesCollection).doc(); // Generate new doc ID

    try {
      await _firestore.runTransaction((transaction) async {
        // 1. Define references
        final player1PoolRef = _firestore.collection(_matchmakingPoolCollection).doc(userId1);
        final player2PoolRef = _firestore.collection(_matchmakingPoolCollection).doc(userId2);
        final player1UserRef = _firestore.collection(_usersCollection).doc(userId1);
        final player2UserRef = _firestore.collection(_usersCollection).doc(userId2);

        // 2. Verify players are still in the pool (optional but safer)
        // final player1PoolSnap = await transaction.get(player1PoolRef);
        // final player2PoolSnap = await transaction.get(player2PoolRef);
        // if (!player1PoolSnap.exists || !player2PoolSnap.exists) {
        //   throw Exception('One or both players left the matchmaking pool.');
        // }

        // 3. Define initial game data
        final gameData = {
          _fieldPlayer1Id: userId1,
          _fieldPlayer2Id: userId2,
          _fieldPlayer1Score: 0,
          _fieldPlayer2Score: 0,
          _fieldPlayer1Answers: {},
          _fieldPlayer2Answers: {},
          _fieldTopicId: topicId,
          _fieldQuestionIds: questionIds,
          _fieldCurrentQuestionIndex: 0,
          _fieldPlayer1ReadyForNext: false,
          _fieldPlayer2ReadyForNext: false,
          _fieldCreatedAt: FieldValue.serverTimestamp(),
          _fieldStatus: 'active', // Start game immediately
        };

        // 4. Perform writes within the transaction
        transaction.set(gameDocRef, gameData);
        transaction.delete(player1PoolRef);
        transaction.delete(player2PoolRef);
        transaction.update(player1UserRef, {_fieldCurrentMatchId: gameDocRef.id});
        transaction.update(player2UserRef, {_fieldCurrentMatchId: gameDocRef.id});
      });

      print('Game ${gameDocRef.id} created successfully for $userId1 and $userId2.');
      return gameDocRef.id;
    } catch (e) {
      print('Error creating game: $e');
      // Transaction failed or other error occurred
      // Returning null as per method signature
      return null;
      // Consider logging the error or throwing a custom exception
    } // TODO: Add more specific error handling/custom exceptions
  }

  @override
  Future<void> leavePool({required String userId, required String topicId}) async {
    try {
      final poolDocRef = _firestore
          .collection(_matchmakingPoolCollection)
          .doc(userId); // Use userId as doc ID

      await poolDocRef.delete();
      print('User $userId left pool for topic $topicId');
    } catch (e) {
      print('Error leaving matchmaking pool: $e');
      // Re-throw as a custom exception or handle appropriately
      rethrow;
    } // TODO: Add more specific error handling/custom exceptions
  }
} 