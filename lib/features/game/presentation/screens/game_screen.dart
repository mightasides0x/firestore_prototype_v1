import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firestore_prototype_v1/features/game/presentation/cubit/game_cubit.dart';
import 'package:firestore_prototype_v1/features/game/presentation/cubit/game_state.dart';
import 'package:firestore_prototype_v1/features/game/presentation/screens/results_screen.dart';
import 'package:go_router/go_router.dart';

// Changed to StatefulWidget
class GameScreen extends StatefulWidget {
  static const routeName = '/game';

  final String gameId;

  const GameScreen({super.key, required this.gameId});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  final Stopwatch _stopwatch = Stopwatch();
  String? _currentQuestionId;

  @override
  void dispose() {
    _stopwatch.stop(); // Ensure stopwatch is stopped when screen is disposed
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Game'),
      ),
      body: BlocListener<GameCubit, GameState>(
        listener: (context, state) {
          if (state is GameFinished) {
            // Navigate to ResultsScreen when game is finished
            // Pass the final game state as an extra parameter
            context.go(ResultsScreen.routeName, extra: state.finalGameState);
          }
        },
        child: BlocBuilder<GameCubit, GameState>(
          builder: (context, state) {
            // --- Stopwatch Management ---
            if (state is GameReady) {
              // Start stopwatch only when a *new* question is displayed
              if (state.currentQuestion.id != _currentQuestionId) {
                _currentQuestionId = state.currentQuestion.id;
                _stopwatch.reset();
                _stopwatch.start();
              }
            } else {
              // Stop stopwatch if not in ready state (loading, finished, error)
              _stopwatch.stop();
              _currentQuestionId = null; // Reset question tracking
            }
            // --- End Stopwatch Management ---

            // Loading State
            if (state is GameLoading || state is GameInitial) {
              return const Center(
                child: Column(
                   mainAxisSize: MainAxisSize.min,
                   children: [
                     CircularProgressIndicator(),
                     SizedBox(height: 16),
                     Text('Loading Game...'),
                   ],
                 ),
              );
            }
            // Error State
            if (state is GameError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Error: ${state.message}',
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }
            // Game Ready State
            if (state is GameReady) {
              final game = state.game;
              final question = state.currentQuestion;
              final isPlayer1 = state.isPlayer1;
              // Check if current player has already answered this question
              final answers = isPlayer1 ? game.player1Answers : game.player2Answers;
              final bool alreadyAnswered = answers.containsKey(question.id);

              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Top Row: Timer & Scores (Placeholder)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Timer Widget
                        SizedBox(
                          width: 60,
                          height: 60,
                          child: TweenAnimationBuilder<double>(
                            tween: Tween<double>(begin: 1.0, end: 0.0),
                            duration: state.totalDuration,
                            key: ValueKey(question.id), // Add key to restart animation on new question
                            builder: (context, value, child) {
                              // value goes from 1.0 down to 0.0
                              int remainingSeconds = (value * state.totalDuration.inSeconds).ceil();
                              return Stack(
                                fit: StackFit.expand,
                                alignment: Alignment.center,
                                children: [
                                  CircularProgressIndicator(
                                    value: value,
                                    strokeWidth: 5,
                                    backgroundColor: Colors.grey.shade300,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      // Color changes as time runs out (e.g., green -> orange -> red)
                                      value > 0.5 ? Colors.green :
                                      value > 0.2 ? Colors.orange : Colors.red,
                                    ),
                                  ),
                                  Center(
                                    child: Text(
                                      remainingSeconds.toString(),
                                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              );
                            },
                            onEnd: () {
                              // Call Cubit method when timer ends
                              // Ensure it's only called if the stopwatch was running (i.e., question was active)
                              if (_stopwatch.isRunning) {
                                 _stopwatch.stop(); // Stop it here to prevent multiple calls if state changes slowly
                                 print('Timer ended for question: ${_currentQuestionId}');
                                 context.read<GameCubit>().handleQuestionTimeout();
                              }
                            },
                          ),
                        ),
                        // Scores Placeholder (Align to the right)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('P1: ${game.player1Score}'),
                            Text('P2: ${game.player2Score}'),
                            const SizedBox(height: 4),
                            if (isPlayer1 && game.player2ReadyForNext)
                              const Text('Opponent Ready', style: TextStyle(fontSize: 12, color: Colors.green))
                            else if (!isPlayer1 && game.player1ReadyForNext)
                              const Text('Opponent Ready', style: TextStyle(fontSize: 12, color: Colors.green)),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Question Text
                    Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          question.text,
                          style: Theme.of(context).textTheme.headlineSmall,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Answer Options
                    Column(
                       mainAxisSize: MainAxisSize.min, // Prevent Column from taking max height
                       children: question.options.asMap().entries.map((entry) {
                        int index = entry.key;
                        String optionText = entry.value;

                        final playerAnswers = isPlayer1 ? game.player1Answers : game.player2Answers;
                        final Map<String, dynamic>? playerAnswerData = playerAnswers[question.id];
                        final int? playerSelectedOptionIndex = playerAnswerData?['answerIndex'] as int?;

                        final bool revealResults = game.player1ReadyForNext && game.player2ReadyForNext;
                        
                        bool isSelectedByPlayer = playerSelectedOptionIndex == index;
                        bool isCorrectOption = question.correctAnswerIndex == index;

                        Color? activeBackgroundColor;
                        Color? activeForegroundColor;
                        Color? disabledBackgroundColor;
                        Color? disabledForegroundColor;
                        Widget? iconWidget;
                        
                        bool isButtonEnabled = !alreadyAnswered && !revealResults;

                        if (revealResults) {
                          // When revealing results, buttons are disabled, so we style their disabled state
                          if (isCorrectOption) {
                            disabledBackgroundColor = Colors.green;
                            disabledForegroundColor = Colors.white;
                            iconWidget = const Icon(Icons.check, color: Colors.white);
                          } else if (isSelectedByPlayer) { // Incorrectly selected by player
                            disabledBackgroundColor = Colors.red;
                            disabledForegroundColor = Colors.white;
                            iconWidget = const Icon(Icons.close, color: Colors.white);
                          } else { // Other incorrect options
                            disabledBackgroundColor = Colors.grey.shade400;
                            disabledForegroundColor = Colors.grey.shade700;
                          }
                          // Keep active colors as null or default if you want, or set them too
                          activeBackgroundColor = disabledBackgroundColor; // So it looks consistent
                          activeForegroundColor = disabledForegroundColor;
                        } else if (isSelectedByPlayer) {
                          // Player has selected this, but results not revealed yet (button is active)
                          activeBackgroundColor = Theme.of(context).colorScheme.secondary;
                          activeForegroundColor = Theme.of(context).colorScheme.onSecondary;
                        } else {
                          // Default active state (not selected, not revealing)
                          activeBackgroundColor = Theme.of(context).colorScheme.primary;
                          activeForegroundColor = Theme.of(context).colorScheme.onPrimary;
                        }

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6.0),
                          child: ElevatedButton.icon(
                            icon: iconWidget ?? const SizedBox.shrink(),
                            label: Text(optionText, textAlign: TextAlign.center),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: activeBackgroundColor,
                              foregroundColor: activeForegroundColor,
                              disabledBackgroundColor: disabledBackgroundColor,
                              disabledForegroundColor: disabledForegroundColor,
                              padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 12.0),
                              textStyle: Theme.of(context).textTheme.titleMedium,
                              minimumSize: const Size(double.infinity, 0),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                            ),
                            onPressed: isButtonEnabled ? () {
                               _stopwatch.stop();
                               final timeTakenMs = _stopwatch.elapsedMilliseconds;
                               print('Selected option $index: $optionText in ${timeTakenMs}ms');
                               context.read<GameCubit>().submitAnswer(index, timeTakenMs);
                            } : null,
                          ),
                        );
                       }).toList(),
                    ),

                    // Placeholder for Question Progress
                    Padding(
                       padding: const EdgeInsets.only(top: 20.0),
                       child: Text(
                        'Q: ${game.currentQuestionIndex + 1}/${game.questionIds.length}',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              );
            }
            // Game Finished State - UI will be handled by ResultsScreen now
            // The listener above will navigate away before this part of the builder is typically reached
            // for GameFinished state. However, keep a fallback or loading indicator if needed.
            if (state is GameFinished) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Transitioning to results...'),
                  ],
                ),
              );
            }

            // Fallback (should not be reached if listener navigates)
            return const Center(child: Text('Unknown game state.'));
          },
        ),
      ),
    );
  }
} 