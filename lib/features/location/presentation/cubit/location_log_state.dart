part of 'location_log_cubit.dart';

sealed class LocationLogState extends Equatable {
  const LocationLogState();

  @override
  List<Object?> get props => [];
}

class LocationLogInitial extends LocationLogState {
  const LocationLogInitial();
}

class LocationLogLoading extends LocationLogState {
  const LocationLogLoading();
}

class LocationLogLoaded extends LocationLogState {
  const LocationLogLoaded(this.entries);

  final List<LocationEntry> entries;

  @override
  List<Object?> get props => [entries];
}

class LocationLogError extends LocationLogState {
  const LocationLogError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
