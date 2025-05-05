import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
// Updated import path for Topic model
import 'package:firestore_prototype_v1/features/topic/domain/entities/topic.dart';
// Updated import path for TopicRepository
import 'package:firestore_prototype_v1/features/topic/domain/repositories/topic_repository.dart';
import 'package:logging/logging.dart';

import 'home_state.dart'; // Changed from part to import

// Renamed Cubit
class HomeCubit extends Cubit<HomeState> {
  final TopicRepository _topicRepository;
  static final _log = Logger('HomeCubit'); // Renamed logger

  HomeCubit({required TopicRepository topicRepository})
      : _topicRepository = topicRepository,
        super(HomeInitial()); // Use renamed initial state

  Future<void> loadTopics() async {
    if (state is HomeLoading) return; // Use renamed loading state

    emit(HomeLoading()); // Use renamed loading state
    _log.info('Loading topics...');
    try {
      final topics = await _topicRepository.getTopics();
      emit(HomeLoaded(topics)); // Use renamed loaded state
      _log.info('Topics loaded successfully.');
    } catch (e, stackTrace) {
      _log.severe('Error loading topics', e, stackTrace);
      emit(HomeError(e.toString())); // Use renamed error state
    }
  }

  // TODO: Add methods for handling other home screen logic if needed
} 