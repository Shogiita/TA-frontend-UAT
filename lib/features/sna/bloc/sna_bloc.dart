import 'package:flutter_bloc/flutter_bloc.dart';

import '../services/sna_service.dart';
import 'sna_event.dart';
import 'sna_state.dart';

class SnaBloc extends Bloc<SnaEvent, SnaState> {
  final SnaService snaService;

  SnaBloc({required this.snaService}) : super(SnaInitial()) {
    on<LoadSnaVisualization>(_onLoadSnaVisualization);
  }

  Future<void> _onLoadSnaVisualization(
    LoadSnaVisualization event,
    Emitter<SnaState> emit,
  ) async {
    emit(SnaLoading());

    try {
      final graph = await snaService.getVisualization(
        source: event.source,
        mode: event.mode,
        limit: event.limit,
      );

      emit(SnaLoaded(graph: graph, source: event.source, mode: event.mode));
    } catch (e) {
      emit(SnaError(e.toString()));
    }
  }
}
