import 'package:equatable/equatable.dart';

abstract class MatchmakingState extends Equatable {
  const MatchmakingState();

  @override
  List<Object?> get props => [];
}

/// Initial state, nothing is happening.
class MatchmakingInitial extends MatchmakingState {
  const MatchmakingInitial();
}

/// User has selected a topic and is actively searching for an opponent.
class MatchmakingSearching extends MatchmakingState {
  final String topicId;
  const MatchmakingSearching({required this.topicId});

  @override
  List<Object?> get props => [topicId];
}

/// Match found and game successfully created.
class MatchmakingSuccess extends MatchmakingState {
  final String gameId;
  final String opponentId; // Good to know who we matched with

  const MatchmakingSuccess({required this.gameId, required this.opponentId});

  @override
  List<Object?> get props => [gameId, opponentId];
}

/// An error occurred during the matchmaking process.
class MatchmakingFailure extends MatchmakingState {
  final String message;
  const MatchmakingFailure({required this.message});

  @override
  List<Object?> get props => [message];
}

/// User explicitly cancelled the matchmaking process.
class MatchmakingCancelled extends MatchmakingState {
  const MatchmakingCancelled();
} 