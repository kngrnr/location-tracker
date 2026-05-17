import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:location_tracker/core/services/location_service.dart';

part 'readiness_state.dart';

class ReadinessCubit extends Cubit<ReadinessState> {
  ReadinessCubit(this._service) : super(const ReadinessInitial());

  final LocationService _service;

  Future<void> check() async {
    emit(const ReadinessLoading());
    try {
      final readiness = await _service.checkReadiness();
      emit(ReadinessLoaded(readiness));
    } catch (e) {
      emit(ReadinessError(e.toString()));
    }
  }

  Future<void> requestPermission() async {
    emit(const ReadinessLoading());
    try {
      await _service.requestPermission();
      final readiness = await _service.checkReadiness();
      emit(ReadinessLoaded(readiness));
    } catch (e) {
      emit(ReadinessError(e.toString()));
    }
  }
}
