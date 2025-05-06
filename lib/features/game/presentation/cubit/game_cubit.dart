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
  Timer? _advanceQuestionTimer; // Timer for delaying question advancement

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

        // Check if it's time to advance to the next question
        if (game.player1ReadyForNext && game.player2ReadyForNext) {
          if (_isPlayer1) {
            _log.info('Both players ready. Player 1 will advance question shortly for game $gameId.');
            _advanceQuestionTimer?.cancel(); // Cancel any existing timer
            _advanceQuestionTimer = Timer(const Duration(seconds: 3), () async {
              // Check again if still player 1 and game is in a state that expects advancement
              // This is a safety check, as state might have changed during the timer.
              if (_isPlayer1 && state is GameReady && (state as GameReady).game.id == gameId && (state as GameReady).game.player1ReadyForNext && (state as GameReady).game.player2ReadyForNext) {
                _log.info('Advancing to next question for game $gameId after delay.');
                try {
                  await _gameRepository.advanceToNextQuestion(gameId);
                  // Firestore will send a new game state via the stream.
                } catch (e, stackTrace) {
                  _log.severe('Error advancing to next question (after delay) for game $gameId', e, stackTrace);
                  // Emit an error. The game might be stuck if P1 can't advance.
                  if (this.state is GameReady || this.state is GameLoading) { // Only emit if game is active
                     emit(GameError(message: 'Error advancing to next question: ${e.toString()}'));
                  }
                }
              } else {
                 _log.info('State changed during advance question timer, not advancing. Current state: $state');
              }
            });
          } else {
            _log.info('Both players ready. Player 2 is waiting for Player 1 to advance for game $gameId.');
          }
          // DO NOT return here yet if P1. Let the current game state (with both players ready)
          // be processed by the code below to emit GameReady, showing revealed answers.
          // The timer will trigger the actual advance, which will then push a new state.
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
    // More specific log for actual submission
    _log.info('CUBIT: SUBMITTING ACTUAL ANSWER for user $userId, question ${currentQuestion.id}: Index $answerIndex, Correct: $isCorrect');

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

  Future<void> handleQuestionTimeout() async {
    _log.info('Handling question timeout for game $gameId, user $_userId');
    if (state is! GameReady) {
      _log.warning('handleQuestionTimeout called while not in GameReady state.');
      return;
    }
    final currentState = state as GameReady;
    final currentQuestion = currentState.currentQuestion;

    if (_userId == null) {
      _log.severe('User ID not found during question timeout handling.');
      // Optionally emit an error, though the game might be stuck if user is gone
      return;
    }

    // Check if answer already submitted for this question
    final answers = _isPlayer1 ? currentState.game.player1Answers : currentState.game.player2Answers;
    if (answers.containsKey(currentQuestion.id)) {
      _log.info('User $_userId already answered question ${currentQuestion.id} before timeout.');
      // If they answered, their ready flag should have been set by submitAnswer.
      // However, ensure their ready flag is set if somehow missed.
      // This part might be redundant if submitAnswer always sets ready flag.
      try {
        await _gameRepository.setPlayerReadyStatus(
          gameId: gameId,
          userId: _userId!,
          isReady: true,
        );
      } catch (e) {
        _log.warning('Failed to ensure ready status for already answered user on timeout: $e');
      }
      return; 
    }

    _log.info('User $_userId timed out on question ${currentQuestion.id}. Submitting timeout answer.');
    // More specific log for timeout submission
    _log.info('CUBIT: SUBMITTING TIMEOUT ANSWER for user $_userId, question ${currentQuestion.id}.');
    try {
      await _gameRepository.submitAnswer(
        gameId: gameId,
        userId: _userId!,
        questionId: currentQuestion.id,
        answerIndex: -1, // Indicates a timeout or no answer selected
        timeTakenMs: currentState.totalDuration.inMilliseconds, // Full duration
        isCorrect: false,
      );
      // Game state will update via the stream listener, which should then also reflect player as ready.
    } catch (e, stackTrace) {
      _log.severe('Error submitting timeout answer for user $_userId, game $gameId', e, stackTrace);
      // Even if submission fails, try to mark player as ready to not stall the game.
      // This is a failsafe; ideally, submitAnswer should be robust.
      try {
        await _gameRepository.setPlayerReadyStatus(
          gameId: gameId,
          userId: _userId!,
          isReady: true,
        );
         _log.info('Fallback: Marked player $_userId as ready after timeout submission failure.');
      } catch (e_ready) {
         _log.severe('Fallback: Failed to mark player $_userId as ready after timeout submission failure: $e_ready');
      }
      // Optionally emit an error state specific to submission failure
      // emit(GameError(message: 'Failed to submit timeout answer: ${e.toString()}'));
    }
  }

   // TODO: Implement method for player timeout (calling setPlayerReadyStatus)
   // TODO: Implement logic for Player 1 to call advanceToNextQuestion when both ready

  @override
  Future<void> close() {
    _log.info('Closing GameCubit for game $gameId');
    _gameSubscription?.cancel();
    _advanceQuestionTimer?.cancel(); // Cancel timer on close
    return super.close();
  }
} 