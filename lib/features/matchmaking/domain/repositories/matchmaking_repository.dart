abstract class MatchmakingRepository {
  /// Adds the user to the matchmaking pool for a specific topic.
  Future<void> enterPool({required String userId, required String topicId});

  /// Attempts to find an opponent in the pool for the given topic by performing
  /// a single query for the oldest waiting user on the same topic.
  /// Returns the opponent's user ID if found, otherwise null.
  Future<String?> findOpponent({required String userId, required String topicId});

  /// Creates a new game document in Firestore for the matched players.
  /// This should ideally be part of a transaction that also removes players from the pool.
  /// Returns the ID of the created game document, or null if creation failed.
  Future<String?> createGame({
    required String userId1,
    required String userId2,
    required String topicId,
    required List<String> questionIds, // Need questions for the game
  });

  /// Removes the user from the matchmaking pool (e.g., if they cancel matchmaking).
  Future<void> leavePool({required String userId, required String topicId});

  // TODO: Consider adding a method to listen for game creation confirmation
  // specifically tied to the user, perhaps listening to the user's document
  // for `currentMatchId` updates, as suggested in PRD Task 3.5.
  // This might live in a UserRepository or here, depending on design.
} 