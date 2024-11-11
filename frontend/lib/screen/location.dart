import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/provider/location_provider.dart';

class LocationScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locationState = ref.watch(locationProvider);
    final locationNotifier = ref.read(locationProvider.notifier);
    final locationService = ref.read(locationServiceProvider);

    return Scaffold(
      appBar: AppBar(title: Text('Location Example')),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Accessing Location: ${locationState.isAccessingLocation}'),
          Text(
              'User Location: ${locationState.userLocation?.latitude}, ${locationState.userLocation?.longitude}'),
          Text('Error: ${locationState.errorDescription}'),
          ElevatedButton(
            onPressed: () async {
              await locationService.getUserLocation(
                ref: ref,
                context: context,
              );
            },
            child: Text('Get Location'),
          ),
        ],
      ),
    );
  }
}
