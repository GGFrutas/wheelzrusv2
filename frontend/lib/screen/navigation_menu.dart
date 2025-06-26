// navigation_menu.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/notifiers/navigation_notifier.dart';
import 'package:frontend/provider/transaction_provider.dart';
import 'package:frontend/theme/colors.dart';

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
      child: Theme (
        data:Theme.of(context).copyWith(
          navigationBarTheme: NavigationBarThemeData(
            indicatorColor: mainColor,
            iconTheme: MaterialStateProperty.resolveWith<IconThemeData>((states) {
              if(states.contains(MaterialState.selected)) {
                return const IconThemeData(
                  color: Colors.white,
                  size: 30,
                );
              }
              return const IconThemeData(
                color: Colors.black,
                size: 24,
              );
            }),
          ),
        ),
        child: NavigationBar(
          selectedIndex: index,
          onDestinationSelected: (value) {
            ref.invalidate(bookingProvider);
            ref.invalidate(filteredItemsProvider);
            ref.read(navigationNotifierProvider.notifier).setSelectedIndex(value);
          },
          destinations: const [
            NavigationDestination(
              selectedIcon: Icon(Icons.receipt_long_rounded),
              icon: Icon(Icons.receipt_long_outlined),
              label: '',
            ),
            NavigationDestination(
              selectedIcon: Icon(Icons.home),
              icon: Icon(Icons.home_outlined),
              label: '',
            ),
            NavigationDestination(
              selectedIcon: Icon(Icons.history_rounded),
              icon: Icon(Icons.history_outlined),
              label: '',
            ),
            // NavigationDestination(
            //   selectedIcon: Icon(Icons.person),
            //   icon: Icon(Icons.person_outline),
            //   label: 'Account',
            // ),
          ],
        ),
      ),
    );
  }
}
