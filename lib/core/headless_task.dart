import 'dart:developer' as dev;

import 'package:flutter_background_geolocation/flutter_background_geolocation.dart'
    as bg;
import 'package:location_tracker/features/location/data/location_log_repository.dart';
import 'package:location_tracker/features/location/domain/location_entry.dart';
import 'package:shared_preferences/shared_preferences.dart';


@pragma('vm:entry-point')
Future<void> backgroundGeolocationHeadlessTask(bg.HeadlessEvent event) async {
  dev.log(
    'headless: event=${event.name}',
    name: 'HeadlessTask',
  );

  switch (event.name) {
    case bg.Event.LOCATION:
      final location = event.event as bg.Location;
      await _persistLocation(location, LocationSource.background);

    case bg.Event.MOTIONCHANGE:
      final location = event.event as bg.Location;
      await _persistLocation(location, LocationSource.background);

    case bg.Event.HEARTBEAT:
      try {
        final location = await bg.BackgroundGeolocation.getCurrentPosition(
          samples: 1,
          persist: false,
          extras: {'source': 'heartbeat'},
        );
        await _persistLocation(location, LocationSource.background);
      } catch (e) {
        dev.log('headless heartbeat getCurrentPosition error: $e',
            name: 'HeadlessTask',);
      }

    default:
      break;
  }
}

Future<void> _persistLocation(
  bg.Location location,
  LocationSource source,
) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final repo = LocationLogRepository(prefs);

    final entry = LocationEntry(
      latitude: location.coords.latitude,
      longitude: location.coords.longitude,
      timestamp: DateTime.tryParse(location.timestamp as String) ?? DateTime.now(),
      accuracy: location.coords.accuracy,
      speed: location.coords.speed >= 0 ? location.coords.speed : null,
      altitude: location.coords.altitude,
      heading: location.coords.heading >= 0 ? location.coords.heading : null,
      odometer: location.odometer,
      isMoving: location.isMoving,
      source: source,
      batteryLevel: location.battery.level >= 0
          ? location.battery.level * 100
          : null,
    );

    await repo.add(entry);
  } catch (e, st) {
    dev.log(
      'headless _persistLocation error',
      error: e,
      stackTrace: st,
      name: 'HeadlessTask',
    );
  }
}
