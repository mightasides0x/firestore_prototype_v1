import 'package:equatable/equatable.dart';
import 'package:firestore_prototype_v1/features/topic/domain/entities/topic.dart';

abstract class HomeState extends Equatable {
  const HomeState();

  @override
  List<Object> get props => [];
}

// Renamed States
class HomeInitial extends HomeState {}

class HomeLoading extends HomeState {}

class HomeLoaded extends HomeState {
  final List<Topic> topics;

  const HomeLoaded(this.topics);

  @override
  List<Object> get props => [topics];
}

class HomeError extends HomeState {
  final String message;

  const HomeError(this.message);

  @override
  List<Object> get props => [message];
} 