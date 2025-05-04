import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:firestore_prototype_v1/features/auth/domain/repositories/auth_repository.dart';
import 'package:firestore_prototype_v1/features/game/domain/repositories/question_repository.dart';
import 'package:firestore_prototype_v1/features/matchmaking/domain/repositories/matchmaking_repository.dart';
import 'package:firestore_prototype_v1/features/matchmaking/presentation/cubit/matchmaking_state.dart';

class MatchmakingCubit extends Cubit<MatchmakingState> {
  final MatchmakingRepository _matchmakingRepository;
  final AuthRepository _authRepository;
  final QuestionRepository _questionRepository;

  Timer? _pollingTimer;
  StreamSubscription<firebase_auth.User?>? _userSubscription;
  StreamSubscription<String?>? _matchIdSubscription; // Listener for external match
  firebase_auth.User? _currentUser;

  bool _isSearching = false;
  String? _currentSearchTopicId;

  // Constants for polling
  static const Duration _pollingInterval = Duration(seconds: 3);
  static const int _maxPollingAttempts = 10; // e.g., 30 seconds timeout

  MatchmakingCubit({
    required MatchmakingRepository matchmakingRepository,
    required AuthRepository authRepository,
    required QuestionRepository questionRepository,
  })  : _matchmakingRepository = matchmakingRepository,
        _authRepository = authRepository,
        _questionRepository = questionRepository,
        super(const MatchmakingInitial()) {
    // Listen to user authentication changes
    _userSubscription = _authRepository.user.listen((user) {
      _currentUser = user;
      if (user == null && _isSearching) {
        cancelSearch('User logged out during matchmaking.');
      }
      // If user changes, cancel any existing match ID listener
      _matchIdSubscription?.cancel();
      _matchIdSubscription = null;
      if(user != null && _isSearching) {
         // If user logged back in *while* searching (unlikely edge case), restart listener
         _listenForExternalMatch();
      }
    });
  }

  void _listenForExternalMatch() {
    _matchIdSubscription?.cancel(); // Cancel previous listener if any
    _matchIdSubscription = _authRepository.onMatchIdChanged.listen((gameId) async {
      if (_isSearching && gameId != null) {
        print('External match detected! Game ID: $gameId');
        // Match found externally, stop local polling and search
        _pollingTimer?.cancel();

        // Need opponentId for the Success state - fetch from game doc
        // This requires adding a method to GameRepository (Phase 4) or
        // potentially making MatchmakingRepository responsible for fetching
        // opponent ID from game doc after match is found externally.
        // For now, let's emit success without opponentId, or use a placeholder.
        // TODO: Fetch actual opponentId from game document
        String opponentId = "unknown";

        emit(MatchmakingSuccess(gameId: gameId, opponentId: opponentId));
        _resetSearchState(cancelMatchIdSubscription: false); // Keep listening until close
      }
    });
  }

  Future<void> findMatch(String topicId) async {
    if (_isSearching) return;

    if (_currentUser == null) {
      emit(const MatchmakingFailure(message: 'User not logged in.'));
      emit(const MatchmakingInitial());
      return;
    }
    final userId = _currentUser!.uid;

    _isSearching = true;
    _currentSearchTopicId = topicId;
    emit(MatchmakingSearching(topicId: topicId));

    try {
      // Start listening for external match creation *before* entering pool
      _listenForExternalMatch();

      await _matchmakingRepository.enterPool(userId: userId, topicId: topicId);

      int attempts = 0;
      _pollingTimer?.cancel();
      _pollingTimer = Timer.periodic(_pollingInterval, (timer) async {
        if (!_isSearching || _currentUser == null || state is! MatchmakingSearching) {
          timer.cancel();
          return;
        }

        if (attempts >= _maxPollingAttempts) {
          timer.cancel();
          await cancelSearch('Matchmaking timed out.');
          return;
        }
        attempts++;

        print('Polling attempt #$attempts for opponent...');
        try {
          // Check if an external match was found *before* trying to find one yourself
          if (state is MatchmakingSuccess) {
             timer.cancel();
             return; // Already handled by the listener
          }

          final opponentId = await _matchmakingRepository.findOpponent(
            userId: userId,
            topicId: topicId,
          );

          // Check again if external match found or search cancelled while finding opponent
          if (state is! MatchmakingSearching || !_isSearching || _currentUser == null) {
             timer.cancel();
             return;
          }

          if (opponentId != null) {
            timer.cancel();
            print('Opponent found via polling: $opponentId. Attempting to create game...');

            final questionIds = await _questionRepository.getQuestionIdsByTopic(topicId, limit: 5);
            if (questionIds.isEmpty) {
              throw Exception('No questions found for topic $topicId');
            }

            if (_currentUser == null || !_isSearching || state is! MatchmakingSearching) return;

            final gameId = await _matchmakingRepository.createGame(
              userId1: _currentUser!.uid,
              userId2: opponentId,
              topicId: topicId,
              questionIds: questionIds,
            );

            // Check _isSearching and state again in case cancelled/externally matched during createGame
            if (gameId != null && _isSearching && state is MatchmakingSearching) {
              print('Game created successfully: $gameId');
              emit(MatchmakingSuccess(gameId: gameId, opponentId: opponentId));
              _resetSearchState();
            } else if (_isSearching && state is MatchmakingSearching) {
              print('Game creation failed (likely opponent left or external match race condition). Failing search...');
              await cancelSearch('Failed to create game. Please try again.');
            }
          } else {
            print('No opponent found yet...');
          }
        } catch (innerEx) {
          print('Error during polling/game creation attempt: $innerEx');
          timer.cancel();
          await cancelSearch('An error occurred during matchmaking: ${innerEx.toString()}');
        }
      });
    } catch (e) {
      print('Error starting matchmaking: $e');
      await cancelSearch('An error occurred: ${e.toString()}');
    }
  }

  Future<void> cancelSearch([String? reason]) async {
    final userId = _currentUser?.uid;
    final topicId = _currentSearchTopicId;

    if (!_isSearching || userId == null || topicId == null) {
      _resetSearchState();
      if (state is! MatchmakingInitial) emit(const MatchmakingInitial());
      return;
    }

    print('Cancelling search... Reason: ${reason ?? 'User cancelled'}');
    bool wasSearching = _isSearching;
    _resetSearchState(); // Reset flags & timers, including matchId listener

    try {
       await _matchmakingRepository.leavePool(userId: userId, topicId: topicId);
    } catch (e) {
        print('Error leaving pool during cancellation: $e');
    }

    if (wasSearching) {
        if (reason != null) {
            emit(MatchmakingFailure(message: reason));
        } else {
            emit(const MatchmakingCancelled());
        }
        emit(const MatchmakingInitial());
    }
  }

  void _resetSearchState({bool cancelMatchIdSubscription = true}) {
    _pollingTimer?.cancel();
    _pollingTimer = null;
    if (cancelMatchIdSubscription) {
        _matchIdSubscription?.cancel();
        _matchIdSubscription = null;
    }
    _isSearching = false;
    _currentSearchTopicId = null;
  }

  @override
  Future<void> close() {
    _userSubscription?.cancel();
    _resetSearchState(); // Cancels timers and matchId listener
    return super.close();
  }
} 