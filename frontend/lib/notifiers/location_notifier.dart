import 'package:location/location.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LocationState {
  final bool isAccessingLocation;
  final String errorDescription;
  final LocationData? userLocation;

  LocationState({
    required this.isAccessingLocation,
    required this.errorDescription,
    this.userLocation,
  });

  // A copyWith method for easy state updates
  LocationState copyWith({
    bool? isAccessingLocation,
    String? errorDescription,
    LocationData? userLocation,
  }) {
    return LocationState(
      isAccessingLocation: isAccessingLocation ?? this.isAccessingLocation,
      errorDescription: errorDescription ?? this.errorDescription,
      userLocation: userLocation ?? this.userLocation,
    );
  }
}

class LocationNotifier extends StateNotifier<LocationState> {
  LocationNotifier()
      : super(LocationState(
          isAccessingLocation: false,
          errorDescription: '',
          userLocation: null,
        ));

  void updateIsAccessingLocation(bool value) {
    state = state.copyWith(isAccessingLocation: value);
  }

  void updateUserLocation(LocationData data) {
    state = state.copyWith(userLocation: data);
  }

  void updateErrorDescription(String error) {
    state = state.copyWith(errorDescription: error);
  }
}
