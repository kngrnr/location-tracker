import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/constants/app_constants.dart';
import 'core/services/location_service.dart';
import 'core/utils/app_theme.dart';
import 'features/location/data/location_log_repository.dart';
import 'features/location/presentation/cubit/location_log_cubit.dart';
import 'features/location/presentation/cubit/readiness_cubit.dart';
import 'features/location/presentation/cubit/tracking_cubit.dart';
import 'features/location/presentation/screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  final repo = LocationLogRepository(prefs);
  final service = LocationService(repository: repo);

  await service.initialise();
  final pluginState = await service.getState();

  runApp(
    LocationTrackerApp(
      service: service,
      repository: repo,
      initiallyTracking: pluginState.enabled,
    ),
  );
}

class LocationTrackerApp extends StatelessWidget {
  const LocationTrackerApp({
    required this.service,
    required this.repository,
    required this.initiallyTracking,
    super.key,
  });

  final LocationService service;
  final LocationLogRepository repository;
  final bool initiallyTracking;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => LocationLogCubit(service, repository)),
        BlocProvider(
          create: (_) => TrackingCubit(
            service,
            initiallyTracking: initiallyTracking,
          ),
        ),
        BlocProvider(create: (_) => ReadinessCubit(service)..check()),
      ],
      child: MaterialApp(
        title: AppConstants.appTitle,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const HomeScreen(),
      ),
    );
  }
}
