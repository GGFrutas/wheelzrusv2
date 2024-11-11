import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/notifiers/location_notifier.dart';
import 'package:frontend/user/location_screen.dart';

final locationProvider = StateNotifierProvider<LocationNotifier, LocationState>(
  (ref) => LocationNotifier(),
);

final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService.init();
});
