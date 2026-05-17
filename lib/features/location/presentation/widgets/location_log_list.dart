import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import 'package:location_tracker/features/location/domain/location_entry.dart';
import 'package:location_tracker/features/location/presentation/cubit/location_log_cubit.dart';

class LocationLogList extends StatelessWidget {
  const LocationLogList({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocBuilder<LocationLogCubit, LocationLogState>(
      builder: (context, state) {
        if (state is! LocationLogLoaded || state.entries.isEmpty) {
          return const SizedBox.shrink();
        }
        final entries = state.entries;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Location Log',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(width: 8),
                _CountBadge(count: entries.length),
              ],
            ),
            const SizedBox(height: 10),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: entries.length,
              separatorBuilder: (_, __) => const SizedBox(height: 6),
              itemBuilder: (ctx, i) => _LogTile(entry: entries[i], index: i),
            ),
          ],
        );
      },
    );
  }
}

class _CountBadge extends StatelessWidget {
  const _CountBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$count',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }
}

class _LogTile extends StatelessWidget {
  const _LogTile({required this.entry, required this.index});

  final LocationEntry entry;
  final int index;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isBg = entry.source == LocationSource.background;
    final borderColor = isBg ? Colors.deepPurple.shade100 : Colors.green.shade100;
    final bgColor = isBg
        ? Colors.deepPurple.shade50.withValues(alpha: 0.5)
        : Colors.green.shade50.withValues(alpha: 0.5);
    final accentColor = isBg ? Colors.deepPurple.shade400 : Colors.green.shade600;

    final absTime = DateFormat('HH:mm:ss').format(entry.timestamp);
    final relTime = _relative(entry.timestamp);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 28,
            child: Text(
              '#${index + 1}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade400,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: entry.latString,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                      TextSpan(
                        text: ',  ',
                        style: TextStyle(color: Colors.grey.shade400),
                      ),
                      TextSpan(
                        text: entry.lngString,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Text(
                      '$relTime  ·  $absTime',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: Colors.grey.shade500),
                    ),
                    if (entry.accuracy != null)
                      Text(
                        '  ·  ${entry.accuracyString}',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: Colors.grey.shade500),
                      ),
                    if (entry.isMoving)
                      Text(
                        '  ·  ${entry.speedKmh}',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: Colors.grey.shade500),
                      ),
                  ],
                ),
              ],
            ),
          ),
          Icon(
            isBg ? Icons.nightlight_round : Icons.wb_sunny_outlined,
            size: 16,
            color: accentColor,
          ),
        ],
      ),
    );
  }

  String _relative(DateTime dt) {
    final d = DateTime.now().difference(dt);
    if (d.inSeconds < 60) return '${d.inSeconds}s ago';
    if (d.inMinutes < 60) return '${d.inMinutes}m ago';
    if (d.inHours < 24) return '${d.inHours}h ago';
    return '${d.inDays}d ago';
  }
}
