part of 'tracking_cubit.dart';

class TrackingState extends Equatable {
  const TrackingState({
    this.isTracking = false,
    this.isMoving = false,
    this.isToggling = false,
  });

  final bool isTracking;
  final bool isMoving;
  final bool isToggling;

  TrackingState copyWith({
    bool? isTracking,
    bool? isMoving,
    bool? isToggling,
  }) =>
      TrackingState(
        isTracking: isTracking ?? this.isTracking,
        isMoving: isMoving ?? this.isMoving,
        isToggling: isToggling ?? this.isToggling,
      );

  @override
  List<Object?> get props => [isTracking, isMoving, isToggling];
}
