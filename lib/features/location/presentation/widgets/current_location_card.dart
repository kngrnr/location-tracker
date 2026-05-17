import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import 'package:location_tracker/features/location/domain/location_entry.dart';
import 'package:location_tracker/features/location/presentation/cubit/location_log_cubit.dart';
import 'package:location_tracker/features/location/presentation/cubit/tracking_cubit.dart';

class CurrentLocationCard extends StatelessWidget {
  const CurrentLocationCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: BlocBuilder<LocationLogCubit, LocationLogState>(
          builder: (context, logState) {
            return BlocBuilder<TrackingCubit, TrackingState>(
              builder: (context, trackingState) {
                if (logState is LocationLogInitial || logState is LocationLogLoading) {
                  return const _Shimmer();
                }
                if (logState is LocationLogError) {
                  return _ErrorView(message: logState.message);
                }
                final entries = (logState as LocationLogLoaded).entries;
                return entries.isEmpty
                    ? const _EmptyView()
                    : _DataView(
                        entry: entries.first,
                        isMoving: trackingState.isMoving,
                      );
              },
            );
          },
        ),
      ),
    );
  }
}

class _Shimmer extends StatelessWidget {
  const _Shimmer();

  @override
  Widget build(BuildContext context) => const SizedBox(
        height: 100,
        child: Center(child: CircularProgressIndicator()),
      );
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Icon(Icons.location_searching, size: 44, color: Colors.grey.shade400),
        const SizedBox(height: 12),
        Text(
          'No location yet',
          style: theme.textTheme.titleMedium?.copyWith(color: Colors.grey.shade600),
        ),
        const SizedBox(height: 4),
        Text(
          'Enable tracking below to start.',
          style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade500),
        ),
      ],
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message, style: const TextStyle(color: Colors.red)),
          ),
        ],
      );
}

class _DataView extends StatelessWidget {
  const _DataView({required this.entry, required this.isMoving});

  final LocationEntry entry;
  final bool isMoving;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isBg = entry.source == LocationSource.background;
    final ts = DateFormat('MMM d  HH:mm:ss').format(entry.timestamp);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.my_location, size: 18, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              'Current Location',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const Spacer(),
            _Chip(
              label: isBg ? 'Background' : 'Foreground',
              icon: isBg ? Icons.nightlight_round : Icons.wb_sunny_outlined,
              color: isBg ? Colors.deepPurple : Colors.orange,
            ),
          ],
        ),
        const SizedBox(height: 16),
        _Row(label: 'Latitude', value: entry.latString),
        const SizedBox(height: 6),
        _Row(label: 'Longitude', value: entry.lngString),
        const SizedBox(height: 6),
        _Row(label: 'Accuracy', value: entry.accuracyString),
        const SizedBox(height: 6),
        _Row(label: 'Speed', value: entry.speedKmh),
        const Divider(height: 20),
        Row(
          children: [
            Icon(Icons.schedule, size: 13, color: Colors.grey.shade500),
            const SizedBox(width: 4),
            Text(
              ts,
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
            ),
            const Spacer(),
            _Chip(
              label: isMoving ? 'Moving' : 'Stationary',
              icon: isMoving ? Icons.directions_run : Icons.pause_circle_outline,
              color: isMoving ? Colors.green : Colors.grey,
            ),
          ],
        ),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Text(
          '$label:',
          style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
        ),
        const Spacer(),
        Text(
          value,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w600,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.icon, required this.color});

  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
