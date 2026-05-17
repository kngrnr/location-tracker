import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:location_tracker/core/services/location_service.dart';

part 'tracking_state.dart';

class TrackingCubit extends Cubit<TrackingState> {
  TrackingCubit(this._service, {required bool initiallyTracking})
      : super(TrackingState(isTracking: initiallyTracking)) {
    _motionSub = _service.onMotionChange.listen(
      (isMoving) => emit(state.copyWith(isMoving: isMoving)),
    );
  }

  final LocationService _service;
  StreamSubscription<bool>? _motionSub;

  Future<void> startTracking() async {
    emit(state.copyWith(isToggling: true));
    try {
      await _service.start();
      emit(state.copyWith(isTracking: true, isToggling: false));
    } catch (_) {
      emit(state.copyWith(isToggling: false));
    }
  }

  Future<void> stopTracking() async {
    emit(state.copyWith(isToggling: true));
    try {
      await _service.stop();
      emit(state.copyWith(isTracking: false, isToggling: false));
    } catch (_) {
      emit(state.copyWith(isToggling: false));
    }
  }

  @override
  Future<void> close() {
    _motionSub?.cancel();
    return super.close();
  }
}
