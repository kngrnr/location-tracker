import 'dart:developer' as dev;

import 'package:shared_preferences/shared_preferences.dart';

import 'package:location_tracker/core/constants/app_constants.dart';
import 'package:location_tracker/features/location/domain/location_entry.dart';

class LocationLogRepository {
  LocationLogRepository(this._prefs);

  final SharedPreferences _prefs;

  List<LocationEntry> getAll() {
    final raw = _prefs.getString(AppConstants.prefLocationLog);
    if (raw == null || raw.isEmpty) return [];
    try {
      final entries = LocationEntry.decodeList(raw);
      entries.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return entries;
    } catch (e, st) {
      dev.log(
        'LocationLogRepository.getAll: decode error',
        error: e,
        stackTrace: st,
        name: 'LocationLogRepository',
      );
      return [];
    }
  }

  Future<void> add(LocationEntry entry) async {
    final current = getAll();
    final updated = [entry, ...current];
    final pruned = updated.length > AppConstants.maxLogEntries ? updated.sublist(0, AppConstants.maxLogEntries) : updated;

    await _prefs.setString(
      AppConstants.prefLocationLog,
      LocationEntry.encodeList(pruned),
    );

    dev.log(
      'add: ${entry.latString}, ${entry.lngString} (${entry.source.name})',
      name: 'LocationLogRepository',
    );
  }

  Future<void> clearAll() async {
    await _prefs.remove(AppConstants.prefLocationLog);
    dev.log('clearAll', name: 'LocationLogRepository');
  }

  Future<void> setTrackingEnabled({required bool enabled}) => _prefs.setBool(AppConstants.prefTrackingEnabled, enabled);

  bool getTrackingEnabled() => _prefs.getBool(AppConstants.prefTrackingEnabled) ?? false;
}
