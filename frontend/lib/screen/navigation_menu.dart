// navigation_menu.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/notifiers/navigation_notifier.dart';

class NavigationMenu extends ConsumerWidget {
  const NavigationMenu({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = ref.watch(navigationNotifierProvider);

    return Container (
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Colors.grey,
            width: 1,
          ),
        ),
      ),
      child: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (value) {
          ref.read(navigationNotifierProvider.notifier).setSelectedIndex(value);
        },
        destinations: const [
          NavigationDestination(
            selectedIcon: Icon(Icons.paid),
            icon: Icon(Icons.attach_money_rounded),
            label: '',
          ),
          NavigationDestination(
            selectedIcon: Icon(Icons.home_outlined),
            icon: Icon(Icons.home_outlined),
            label: '',
          ),
          NavigationDestination(
            selectedIcon: Icon(Icons.receipt),
            icon: Icon(Icons.receipt_long_outlined),
            label: '',
          ),
          // NavigationDestination(
          //   selectedIcon: Icon(Icons.person),
          //   icon: Icon(Icons.person_outline),
          //   label: 'Account',
          // ),
        ],
      ),
    );
  }
}
