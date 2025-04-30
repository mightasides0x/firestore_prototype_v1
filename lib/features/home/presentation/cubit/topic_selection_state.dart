part of 'topic_selection_cubit.dart';

abstract class TopicSelectionState extends Equatable {
  const TopicSelectionState();

  @override
  List<Object> get props => [];
}

class TopicSelectionInitial extends TopicSelectionState {}

class TopicSelectionLoading extends TopicSelectionState {}

class TopicSelectionLoaded extends TopicSelectionState {
  final List<Topic> topics;

  const TopicSelectionLoaded(this.topics);

  @override
  List<Object> get props => [topics];
}

class TopicSelectionError extends TopicSelectionState {
  final String message;

  const TopicSelectionError(this.message);

  @override
  List<Object> get props => [message];
} 