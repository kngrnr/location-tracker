import 'dart:convert';

import 'package:equatable/equatable.dart';

class LocationEntry extends Equatable {
  const LocationEntry({
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    this.accuracy,
    this.speed,
    this.altitude,
    this.heading,
    this.odometer,
    this.isMoving = false,
    this.source = LocationSource.foreground,
    this.batteryLevel,
  });

  final double latitude;
  final double longitude;
  final DateTime timestamp;
  final double? accuracy;
  final double? speed;
  final double? altitude;
  final double? heading;
  final double? odometer;
  final bool isMoving;
  final LocationSource source;
  final double? batteryLevel;

  Map<String, dynamic> toJson() => {
        'lat': latitude,
        'lng': longitude,
        'ts': timestamp.toIso8601String(),
        'acc': accuracy,
        'spd': speed,
        'alt': altitude,
        'hdg': heading,
        'odo': odometer,
        'mov': isMoving,
        'src': source.name,
        'bat': batteryLevel,
      };

  factory LocationEntry.fromJson(Map<String, dynamic> j) => LocationEntry(
        latitude: (j['lat'] as num).toDouble(),
        longitude: (j['lng'] as num).toDouble(),
        timestamp: DateTime.parse(j['ts'] as String),
        accuracy: (j['acc'] as num?)?.toDouble(),
        speed: (j['spd'] as num?)?.toDouble(),
        altitude: (j['alt'] as num?)?.toDouble(),
        heading: (j['hdg'] as num?)?.toDouble(),
        odometer: (j['odo'] as num?)?.toDouble(),
        isMoving: (j['mov'] as bool?) ?? false,
        source: LocationSource.values.byName(
          (j['src'] as String?) ?? LocationSource.foreground.name,
        ),
        batteryLevel: (j['bat'] as num?)?.toDouble(),
      );

  static String encodeList(List<LocationEntry> entries) =>
      jsonEncode(entries.map((e) => e.toJson()).toList());

  static List<LocationEntry> decodeList(String raw) {
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => LocationEntry.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  String get latString => latitude.toStringAsFixed(7);
  String get lngString => longitude.toStringAsFixed(7);
  String get speedKmh =>
      speed != null ? '${(speed! * 3.6).toStringAsFixed(1)} km/h' : '—';
  String get accuracyString =>
      accuracy != null ? '±${accuracy!.toStringAsFixed(0)} m' : '—';

  @override
  List<Object?> get props => [
        latitude,
        longitude,
        timestamp,
        accuracy,
        speed,
        altitude,
        heading,
        isMoving,
        source,
        batteryLevel,
      ];
}

enum LocationSource {
  foreground,
  background,
}
