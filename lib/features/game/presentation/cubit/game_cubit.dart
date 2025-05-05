import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firestore_prototype_v1/features/auth/domain/repositories/auth_repository.dart';
import 'package:firestore_prototype_v1/features/game/domain/entities/game.dart';
import 'package:firestore_prototype_v1/features/game/domain/entities/question.dart';
import 'package:firestore_prototype_v1/features/game/domain/repositories/game_repository.dart';
import 'package:firestore_prototype_v1/features/game/domain/repositories/question_repository.dart';
import 'package:firestore_prototype_v1/features/game/presentation/cubit/game_state.dart';
import 'package:logging/logging.dart';

class GameCubit extends Cubit<GameState> {
  final String gameId;
  final GameRepository _gameRepository;
  final QuestionRepository _questionRepository;
  final AuthRepository _authRepository;
  static final _log = Logger('GameCubit');

  StreamSubscription? _gameSubscription;
  String? _userId;
  bool _isPlayer1 = false;

  GameCubit({
    required this.gameId,
    required GameRepository gameRepository,
    required QuestionRepository questionRepository,
    required AuthRepository authRepository,
  })  : _gameRepository = gameRepository,
        _questionRepository = questionRepository,
        _authRepository = authRepository,
        super(const GameInitial()) {
    // Initialize asynchronously
    _initialize();
  }

  Future<void> _initialize() async {
    emit(GameLoading(gameId: gameId));
    // Listen to user stream to get the user ID
    // Use a Completer to wait for the first user emission if needed
    final completer = Completer<String?>();
    StreamSubscription? tempUserSub;
    tempUserSub = _authRepository.user.listen((user) {
        if (!completer.isCompleted) {
            completer.complete(user?.uid);
            tempUserSub?.cancel(); // Stop listening once we have the first value
        }
        _userId = user?.uid; // Keep updating _userId for later use
    });

    // Wait for the first user ID emission
    _userId = await completer.future;

    if (_userId == null) {
      emit(const GameError(message: 'User not authenticated.'));
      tempUserSub?.cancel(); // Ensure cancellation on error
      return;
    }
    _log.info('GameCubit initialized for user $_userId and game $gameId');
    _subscribeToGameUpdates();
  }

  void _subscribeToGameUpdates() {
    _gameSubscription?.cancel(); // Cancel previous subscription if any
    _gameSubscription = _gameRepository.getGameStream(gameId).listen(
      (game) async {
        _log.info('Received game update for $gameId. Status: ${game.status}, Index: ${game.currentQuestionIndex}');
        _isPlayer1 = game.player1Id == _userId;

        // Check if game has finished
        if (game.status == 'finished' || game.currentQuestionIndex >= game.questionIds.length) {
           _log.info('Game $gameId finished.');
           emit(GameFinished(finalGameState: game, isPlayer1: _isPlayer1));
           _gameSubscription?.cancel(); // Stop listening
           return;
        }

        // Fetch current question data
        try {
          final currentQuestionId = game.questionIds[game.currentQuestionIndex];
           _log.finer('Fetching question ${currentQuestionId} for game $gameId');
          final questions = await _questionRepository.getQuestionsByIds([currentQuestionId]);

          if (questions.isEmpty) {
            _log.severe('Could not find question $currentQuestionId for game $gameId');
            emit(const GameError(message: 'Error loading current question data.'));
             _gameSubscription?.cancel(); // Stop on critical error
          } else {
            final currentQuestion = questions.first;
            _log.finer('Question ${currentQuestionId} loaded. Emitting GameReady.');
            emit(GameReady(
              game: game,
              currentQuestion: currentQuestion,
              isPlayer1: _isPlayer1,
            ));
          }
        } catch (e, stackTrace) {
          _log.severe('Error fetching question data for game $gameId', e, stackTrace);
          emit(GameError(message: 'Error loading question: ${e.toString()}'));
           _gameSubscription?.cancel(); // Stop on critical error
        }
      },
      onError: (error, stackTrace) {
        _log.severe('Error in game stream for $gameId', error, stackTrace);
        emit(GameError(message: 'Error loading game data: ${error.toString()}'));
        _gameSubscription?.cancel(); // Stop listening on error
      },
    );
  }

  Future<void> submitAnswer(int answerIndex, int timeTakenMs) async {
     if (state is! GameReady) {
        _log.warning('submitAnswer called while not in GameReady state.');
        return;
    }
    final currentState = state as GameReady;
    final currentQuestion = currentState.currentQuestion;
    final userId = _userId;

    if (userId == null) {
        emit(const GameError(message: 'User ID not found.'));
        return;
    }

    // Check if answer already submitted for this question
    final answers = _isPlayer1 ? currentState.game.player1Answers : currentState.game.player2Answers;
    if (answers.containsKey(currentQuestion.id)) {
        _log.info('User $userId already answered question ${currentQuestion.id}');
        return; // Already submitted
    }

    final bool isCorrect = answerIndex == currentQuestion.correctAnswerIndex;
    _log.info('User $userId submitting answer for ${currentQuestion.id}: Index $answerIndex (Correct: $isCorrect) Time: ${timeTakenMs}ms');

    try {
      await _gameRepository.submitAnswer(
        gameId: gameId,
        userId: userId,
        questionId: currentQuestion.id,
        answerIndex: answerIndex,
        timeTakenMs: timeTakenMs,
        isCorrect: isCorrect,
      );
      // Game state will update via the stream listener
    } catch (e, stackTrace) {
       _log.severe('Error submitting answer for user $userId, game $gameId', e, stackTrace);
       // Optionally emit an error state specific to submission failure
       emit(GameError(message: 'Failed to submit answer: ${e.toString()}'));
       // Revert to previous ready state? Or let stream handle it?
       // For now, just emit error. The stream should eventually show the state.
    }
  }

   // TODO: Implement method for player timeout (calling setPlayerReadyStatus)
   // TODO: Implement logic for Player 1 to call advanceToNextQuestion when both ready

  @override
  Future<void> close() {
    _log.info('Closing GameCubit for game $gameId');
    _gameSubscription?.cancel();
    return super.close();
  }
} 