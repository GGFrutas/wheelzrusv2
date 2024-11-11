import 'package:flutter/material.dart';

const ColorScheme lightColorScheme = ColorScheme.light(
  primary: Color(0xFF1d3c34), // Custom primary color
  primaryContainer: Color(0xFFdbe4de), // Lighter variant of primary
  secondary: Color(0xFF64ffda), // Accent color
  onPrimary: Colors.white, // Text color on primary
  surface: Colors.white, // Card and sheet color
  onSurface: Colors.black, // Text color on surface
);

const ColorScheme darkColorScheme = ColorScheme.dark(
  // primary: Color(0xFF64ffda), // Custom primary color
  primary: Colors.blue,
  primaryContainer: Color(0xFF1d3c34), // Dark variant of primary
  secondary: Color(0xFF03dac6), // Accent color
  onPrimary: Colors.black, // Text color on primary
  surface: Color(0xFF1d1d1d), // Dark surface color
  onSurface: Colors.white, // Text color on surface
);
