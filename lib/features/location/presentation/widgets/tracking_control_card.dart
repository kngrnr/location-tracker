import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:location_tracker/core/services/location_service.dart';
import 'package:location_tracker/features/location/presentation/cubit/readiness_cubit.dart';
import 'package:location_tracker/features/location/presentation/cubit/tracking_cubit.dart';

class TrackingControlCard extends StatelessWidget {
  const TrackingControlCard({super.key});

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
        padding: const EdgeInsets.all(18),
        child: BlocBuilder<TrackingCubit, TrackingState>(
          builder: (context, trackingState) {
            return BlocBuilder<ReadinessCubit, ReadinessState>(
              builder: (context, readinessState) {
                final isReady = readinessState is ReadinessLoaded &&
                    readinessState.readiness == TrackingReadiness.ready;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: trackingState.isTracking
                                ? theme.colorScheme.primaryContainer
                                : theme.colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            trackingState.isTracking
                                ? Icons.gps_fixed
                                : Icons.gps_off,
                            color: trackingState.isTracking
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurfaceVariant,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Background Tracking',
                                style: theme.textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              Text(
                                trackingState.isTracking
                                    ? 'Recording — foreground, background & terminated'
                                    : 'Disabled — tap to start',
                                style: theme.textTheme.bodySmall
                                    ?.copyWith(color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        ),
                        if (trackingState.isToggling)
                          const SizedBox(
                            width: 36,
                            height: 20,
                            child: Center(
                              child: SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            ),
                          )
                        else
                          Switch(
                            value: trackingState.isTracking,
                            onChanged: isReady
                                ? (_) => _toggle(context, trackingState.isTracking)
                                : null,
                          ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const Divider(height: 1),
                    const SizedBox(height: 12),
                    _buildReadinessRow(context, readinessState, trackingState.isTracking),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  void _toggle(BuildContext context, bool isTracking) {
    if (isTracking) {
      context.read<TrackingCubit>().stopTracking();
    } else {
      context.read<TrackingCubit>().startTracking();
    }
  }

  Widget _buildReadinessRow(
    BuildContext context,
    ReadinessState state,
    bool isTracking,
  ) {
    if (state is ReadinessInitial || state is ReadinessLoading) {
      return const LinearProgressIndicator();
    }
    if (state is ReadinessError) {
      return Text('Error: ${state.message}', style: const TextStyle(color: Colors.red));
    }
    final readiness = (state as ReadinessLoaded).readiness;
    return _ReadinessRow(
      readiness: readiness,
      isTracking: isTracking,
      onRequestPermission: () => context.read<ReadinessCubit>().requestPermission(),
    );
  }
}

class _ReadinessRow extends StatelessWidget {
  const _ReadinessRow({
    required this.readiness,
    required this.isTracking,
    required this.onRequestPermission,
  });

  final TrackingReadiness readiness;
  final bool isTracking;
  final VoidCallback onRequestPermission;

  @override
  Widget build(BuildContext context) {
    switch (readiness) {
      case TrackingReadiness.ready:
        return _StatusRow(
          icon: isTracking ? Icons.fiber_manual_record : Icons.check_circle_outline,
          label: isTracking ? 'Tracking active' : 'Ready to track',
          color: isTracking ? Colors.green : Colors.blueGrey,
        );

      case TrackingReadiness.serviceDisabled:
        return const _StatusRow(
          icon: Icons.location_disabled,
          label: 'Location services are off — enable in device Settings',
          color: Colors.red,
        );

      case TrackingReadiness.permissionDenied:
        return Row(
          children: [
            const Icon(Icons.warning_amber_rounded, size: 15, color: Colors.orange),
            const SizedBox(width: 6),
            const Expanded(
              child: Text(
                'Location permission required',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.orange,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            TextButton(
              onPressed: onRequestPermission,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('Grant', style: TextStyle(fontSize: 12)),
            ),
          ],
        );

      case TrackingReadiness.permissionDeniedForever:
        return const _StatusRow(
          icon: Icons.block,
          label: 'Permission permanently denied — open app settings',
          color: Colors.red,
        );
    }
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({required this.icon, required this.label, required this.color});

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      );
}
