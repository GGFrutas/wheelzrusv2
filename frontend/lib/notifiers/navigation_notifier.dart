// navigation_notifier.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Define a StateNotifier for navigation index
class NavigationNotifier extends StateNotifier<int> {
  NavigationNotifier() : super(1); // Default to Home (index 1)

  void setSelectedIndex(int index) {
    state = index;
  }
}

// Define a provider for NavigationNotifier
final navigationNotifierProvider =
    StateNotifierProvider<NavigationNotifier, int>(
  (ref) => NavigationNotifier(),
);
