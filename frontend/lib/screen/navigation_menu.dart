// navigation_menu.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/notifiers/navigation_notifier.dart';

class NavigationMenu extends ConsumerWidget {
  const NavigationMenu({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = ref.watch(navigationNotifierProvider);

    return NavigationBar(
      selectedIndex: index,
      onDestinationSelected: (value) {
        ref.read(navigationNotifierProvider.notifier).setSelectedIndex(value);
      },
      destinations: const [
        NavigationDestination(
          selectedIcon: Icon(Icons.paid),
          icon: Icon(Icons.paid_outlined),
          label: 'Transactions',
        ),
        NavigationDestination(
          selectedIcon: Icon(Icons.home),
          icon: Icon(Icons.home_outlined),
          label: 'Home',
        ),
        NavigationDestination(
          selectedIcon: Icon(Icons.person),
          icon: Icon(Icons.person_outline),
          label: 'Account',
        ),
      ],
    );
  }
}
