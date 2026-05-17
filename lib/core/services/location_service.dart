import 'dart:async';
import 'dart:developer' as dev;

import 'package:flutter/foundation.dart';
import 'package:flutter_background_geolocation/flutter_background_geolocation.dart'
    as bg;

import 'package:location_tracker/core/constants/app_constants.dart';
import 'package:location_tracker/core/headless_task.dart';
import 'package:location_tracker/features/location/data/location_log_repository.dart';
import 'package:location_tracker/features/location/domain/location_entry.dart';

enum TrackingReadiness {
  ready,
  serviceDisabled,
  permissionDenied,
  permissionDeniedForever,
}

class LocationService {
  LocationService({required this.repository});

  final LocationLogRepository repository;

  final _locationController = StreamController<LocationEntry>.broadcast();
  final _motionController = StreamController<bool>.broadcast();

  Stream<LocationEntry> get onLocation => _locationController.stream;

  Stream<bool> get onMotionChange => _motionController.stream;

  bool _initialised = false;

  Future<void> initialise() async {
    if (_initialised) return;

    bg.BackgroundGeolocation.registerHeadlessTask(
      backgroundGeolocationHeadlessTask,
    );

    bg.BackgroundGeolocation.onLocation(_onLocation, _onLocationError);
    bg.BackgroundGeolocation.onMotionChange(_onMotionChange);
    bg.BackgroundGeolocation.onProviderChange(_onProviderChange);
    bg.BackgroundGeolocation.onHeartbeat(_onHeartbeat);

    await bg.BackgroundGeolocation.ready(
      bg.Config(
        geolocation: bg.GeoConfig(
          desiredAccuracy: bg.DesiredAccuracy.high,
          distanceFilter: AppConstants.distanceFilter,
          stationaryRadius: AppConstants.stationaryRadius.toInt(),
          locationUpdateInterval: 10000,
          fastestLocationUpdateInterval: 5000,
          stopTimeout: 5,
        ),
        app: bg.AppConfig(
          stopOnTerminate: false,
          startOnBoot: true,
          enableHeadless: true,
          heartbeatInterval: 60,
          preventSuspend: false,
          backgroundPermissionRationale: bg.PermissionRationale(
            title:
                "Allow location_tracker to access this device's location in the background?",
            message:
                'To track your activity in the background, please enable location access.',
            positiveAction: 'Change to Always Allow',
            negativeAction: 'Cancel',
          ),
          notification: bg.Notification(
            title: AppConstants.notifTitle,
            text: AppConstants.notifText,
            sticky: true,
            channelName: AppConstants.notifChannelId,
          ),
        ),
        logger: const bg.LoggerConfig(
          logLevel: kDebugMode ? bg.LogLevel.verbose : bg.LogLevel.off,
          debug: kDebugMode,
        ),
      ),
    );

    _initialised = true;
    dev.log('initialise: plugin ready', name: 'LocationService');

    if (repository.getTrackingEnabled()) {
      await start();
    }
  }

  Future<void> start() async {
    await bg.BackgroundGeolocation.start();
    await repository.setTrackingEnabled(enabled: true);
    dev.log('start: tracking started', name: 'LocationService');
  }

  Future<void> stop() async {
    await bg.BackgroundGeolocation.stop();
    await repository.setTrackingEnabled(enabled: false);
    dev.log('stop: tracking stopped', name: 'LocationService');
  }

  Future<bg.State> getState() => bg.BackgroundGeolocation.state;

  Future<LocationEntry?> getCurrentPosition() async {
    try {
      final location = await bg.BackgroundGeolocation.getCurrentPosition(
        samples: 3,
        persist: false,
        timeout: 30,
        extras: {'source': 'manual'},
      );
      return _locationToEntry(location, LocationSource.foreground);
    } catch (e) {
      dev.log('getCurrentPosition error: $e', name: 'LocationService');
      return null;
    }
  }

  Future<void> requestPermission() =>
      bg.BackgroundGeolocation.requestPermission();

  Future<TrackingReadiness> checkReadiness() async {
    final provider = await bg.BackgroundGeolocation.providerState;

    if (!provider.enabled) return TrackingReadiness.serviceDisabled;

    switch (provider.status) {
      case 2:
        return TrackingReadiness.permissionDenied;
      case 1:
        return TrackingReadiness.permissionDeniedForever;
      default:
        return TrackingReadiness.ready;
    }
  }

  Future<void> _onLocation(bg.Location location) async {
    dev.log(
      '_onLocation: ${location.coords.latitude}, ${location.coords.longitude}'
      ' isMoving=${location.isMoving}',
      name: 'LocationService',
    );

    final entry = _locationToEntry(
      location,
      location.isMoving ? LocationSource.foreground : LocationSource.background,
    );

    await repository.add(entry);
    _locationController.add(entry);
  }

  void _onLocationError(bg.LocationError error) {
    dev.log('_onLocationError: $error', name: 'LocationService');
  }

  Future<void> _onMotionChange(bg.Location location) async {
    dev.log(
      '_onMotionChange: isMoving=${location.isMoving}',
      name: 'LocationService',
    );
    _motionController.add(location.isMoving);
    final entry = _locationToEntry(location, LocationSource.foreground);
    await repository.add(entry);
    _locationController.add(entry);
  }

  void _onProviderChange(bg.ProviderChangeEvent event) {
    dev.log(
      '_onProviderChange: enabled=${event.enabled}, status=${event.status}',
      name: 'LocationService',
    );
  }

  Future<void> _onHeartbeat(bg.HeartbeatEvent event) async {
    dev.log('_onHeartbeat', name: 'LocationService');
    try {
      final location = await bg.BackgroundGeolocation.getCurrentPosition(
        samples: 1,
        persist: false,
        extras: {'source': 'heartbeat'},
      );
      final entry = _locationToEntry(location, LocationSource.background);
      await repository.add(entry);
      _locationController.add(entry);
    } catch (e) {
      dev.log(
        '_onHeartbeat getCurrentPosition error: $e',
        name: 'LocationService',
      );
    }
  }

  LocationEntry _locationToEntry(bg.Location loc, LocationSource source) =>
      LocationEntry(
        latitude: loc.coords.latitude,
        longitude: loc.coords.longitude,
        timestamp: DateTime.tryParse(loc.timestamp as String) ?? DateTime.now(),
        accuracy: loc.coords.accuracy,
        speed: loc.coords.speed >= 0 ? loc.coords.speed : null,
        altitude: loc.coords.altitude,
        heading: loc.coords.heading >= 0 ? loc.coords.heading : null,
        odometer: loc.odometer,
        isMoving: loc.isMoving,
        source: source,
        batteryLevel: loc.battery.level >= 0 ? loc.battery.level * 100 : null,
      );

  void dispose() {
    _locationController.close();
    _motionController.close();
  }
}
