import 'package:equatable/equatable.dart';

abstract class SnaEvent extends Equatable {
  const SnaEvent();

  @override
  List<Object?> get props => [];
}

class LoadSnaVisualization extends SnaEvent {
  final String source;
  final int mode;
  final int limit;

  const LoadSnaVisualization({
    required this.source,
    required this.mode,
    this.limit = 500,
  });

  @override
  List<Object?> get props => [source, mode, limit];
}
