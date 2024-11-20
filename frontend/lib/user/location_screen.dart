import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/provider/location_provider.dart';
import 'package:location/location.dart';
import 'package:permission_handler/permission_handler.dart' as handler;

class LocationService {
  LocationService.init();
  static final LocationService instance = LocationService.init();

  final Location _location = Location();

  Future<bool> checkForServiceAvailability() async {
    bool isEnabled = await _location.serviceEnabled();
    if (!isEnabled) {
      isEnabled = await _location.requestService();
    }
    return isEnabled;
  }

  Future<bool> checkForPermission(BuildContext context, WidgetRef ref) async {
    PermissionStatus status = await _location.hasPermission();

    if (status == PermissionStatus.denied) {
      status = await _location.requestPermission();
      return status == PermissionStatus.granted;
    }

    if (status == PermissionStatus.deniedForever) {
      // Display a snackbar using Riverpod to handle opening app settings
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
              'We need permission to get your location to provide services.'),
          action: SnackBarAction(
            label: 'Open Settings',
            onPressed: () async {
              await handler.openAppSettings();
            },
          ),
        ),
      );
      return false;
    }

    return true;
  }

  Future<void> getUserLocation({
    required WidgetRef ref,
    required BuildContext context,
  }) async {
    final locationNotifier = ref.read(locationProvider.notifier);
    locationNotifier.updateIsAccessingLocation(true);

    // Check if the service is available
    if (!(await checkForServiceAvailability())) {
      locationNotifier.updateErrorDescription("Service not enabled");
      locationNotifier.updateIsAccessingLocation(false);
      return;
    }

    // Check for location permission
    if (!(await checkForPermission(context, ref))) {
      locationNotifier.updateErrorDescription("Permission not given");
      locationNotifier.updateIsAccessingLocation(false);
      return;
    }

    // Get the user location and update the state
    final LocationData data = await _location.getLocation();
    locationNotifier.updateUserLocation(data);
    locationNotifier.updateIsAccessingLocation(false);
  }
}
