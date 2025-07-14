import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/screen/navigation_menu.dart';

class PodNav extends ConsumerWidget {
  final Widget child;
  const PodNav({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: child,
      bottomNavigationBar: const NavigationMenu(),
    );
  }
}