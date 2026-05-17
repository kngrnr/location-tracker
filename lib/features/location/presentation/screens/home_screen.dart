import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:location_tracker/features/location/domain/location_entry.dart';
import 'package:location_tracker/features/location/presentation/cubit/location_log_cubit.dart';
import 'package:location_tracker/features/location/presentation/cubit/readiness_cubit.dart';
import 'package:location_tracker/features/location/presentation/widgets/current_location_card.dart';
import 'package:location_tracker/features/location/presentation/widgets/location_log_list.dart';
import 'package:location_tracker/features/location/presentation/widgets/tracking_control_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      context.read<ReadinessCubit>().check();
      context.read<LocationLogCubit>().refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.location_on, color: theme.colorScheme.primary, size: 20),
            const SizedBox(width: 8),
            const Text('Location Tracker'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh log',
            onPressed: () => context.read<LocationLogCubit>().refresh(),
          ),
          BlocBuilder<LocationLogCubit, LocationLogState>(
            builder: (context, state) {
              final entries =
                  state is LocationLogLoaded ? state.entries : <LocationEntry>[];
              if (entries.isEmpty) return const SizedBox.shrink();
              return IconButton(
                icon: const Icon(Icons.delete_outline),
                tooltip: 'Clear log',
                onPressed: () => _confirmClear(context),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => context.read<LocationLogCubit>().refresh(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: const [
            CurrentLocationCard(),
            SizedBox(height: 12),
            TrackingControlCard(),
            SizedBox(height: 24),
            LocationLogList(),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmClear(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear Log'),
        content: const Text(
          'This will delete all recorded location entries, including the '
          "plugin's internal database. This cannot be undone.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Clear', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      await context.read<LocationLogCubit>().clearLog();
    }
  }
}
