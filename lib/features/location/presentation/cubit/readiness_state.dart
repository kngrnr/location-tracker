part of 'readiness_cubit.dart';

sealed class ReadinessState extends Equatable {
  const ReadinessState();

  @override
  List<Object?> get props => [];
}

class ReadinessInitial extends ReadinessState {
  const ReadinessInitial();
}

class ReadinessLoading extends ReadinessState {
  const ReadinessLoading();
}

class ReadinessLoaded extends ReadinessState {
  const ReadinessLoaded(this.readiness);

  final TrackingReadiness readiness;

  @override
  List<Object?> get props => [readiness];
}

class ReadinessError extends ReadinessState {
  const ReadinessError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
