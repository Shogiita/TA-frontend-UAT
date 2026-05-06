import 'package:equatable/equatable.dart';

import '../models/sna_graph_model.dart';

abstract class SnaState extends Equatable {
  const SnaState();

  @override
  List<Object?> get props => [];
}

class SnaInitial extends SnaState {}

class SnaLoading extends SnaState {}

class SnaLoaded extends SnaState {
  final SnaGraphModel graph;
  final String source;
  final int mode;

  const SnaLoaded({
    required this.graph,
    required this.source,
    required this.mode,
  });

  @override
  List<Object?> get props => [graph, source, mode];
}

class SnaError extends SnaState {
  final String message;

  const SnaError(this.message);

  @override
  List<Object?> get props => [message];
}
