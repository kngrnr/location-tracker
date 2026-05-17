import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_background_geolocation/flutter_background_geolocation.dart'
    as bg;

import 'package:location_tracker/core/services/location_service.dart';
import 'package:location_tracker/features/location/data/location_log_repository.dart';
import 'package:location_tracker/features/location/domain/location_entry.dart';

part 'location_log_state.dart';

class LocationLogCubit extends Cubit<LocationLogState> {
  LocationLogCubit(this._service, this._repo) : super(const LocationLogInitial()) {
    load();
  }

  final LocationService _service;
  final LocationLogRepository _repo;
  StreamSubscription<LocationEntry>? _sub;

  Future<void> load() async {
    emit(const LocationLogLoading());
    try {
      await _sub?.cancel();
      _sub = _service.onLocation.listen((entry) {
        final current =
            state is LocationLogLoaded ? (state as LocationLogLoaded).entries : <LocationEntry>[];
        emit(LocationLogLoaded([entry, ...current]));
      });
      emit(LocationLogLoaded(_repo.getAll()));
    } catch (e) {
      emit(LocationLogError(e.toString()));
    }
  }

  void refresh() {
    emit(LocationLogLoaded(_repo.getAll()));
  }

  Future<void> clearLog() async {
    await _repo.clearAll();
    await bg.BackgroundGeolocation.destroyLocations();
    emit(const LocationLogLoaded([]));
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
