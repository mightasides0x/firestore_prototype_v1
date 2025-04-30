import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:firestore_prototype_v1/core/domain/entities/topic.dart'; // Import Topic model
import 'package:firestore_prototype_v1/features/home/domain/repositories/topic_repository.dart';
import 'package:logging/logging.dart';

part 'topic_selection_state.dart';

class TopicSelectionCubit extends Cubit<TopicSelectionState> {
  final TopicRepository _topicRepository;
  static final _log = Logger('TopicSelectionCubit');

  TopicSelectionCubit({required TopicRepository topicRepository})
      : _topicRepository = topicRepository,
        super(TopicSelectionInitial());

  Future<void> loadTopics() async {
    if (state is TopicSelectionLoading) return; // Prevent concurrent loads

    emit(TopicSelectionLoading());
    _log.info('Loading topics...');
    try {
      final topics = await _topicRepository.getTopics();
      emit(TopicSelectionLoaded(topics));
      _log.info('Topics loaded successfully.');
    } catch (e, stackTrace) {
      _log.severe('Error loading topics', e, stackTrace);
      emit(TopicSelectionError(e.toString()));
    }
  }
} 