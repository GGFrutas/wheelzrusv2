import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/color_palette.dart';
import 'package:frontend/provider/theme_provider.dart';
import 'package:frontend/splashscreen.dart';

void main() {
  runApp(const ProviderScope(child: MainApp()));
}

class MainApp extends ConsumerWidget {
  const MainApp({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLightTheme = ref.watch(themeProvider);
    return MaterialApp(
      theme: isLightTheme
          ? ThemeData.from(colorScheme: lightColorScheme) // Use light theme
          : ThemeData.from(colorScheme: darkColorScheme), // Use dark theme
      home: const Splashscreen(), // Start with the splash screen
      debugShowCheckedModeBanner: false,
    );
  }
}