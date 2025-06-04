import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTextStyles {
  static late TextStyle title;
  static late TextStyle subtitle;
  static late TextStyle body;
  static late TextStyle caption;


 static void init(BuildContext context) {
  final theme = Theme.of(context).textTheme;

    title = GoogleFonts.montserrat(
      fontSize: 24,
      fontWeight: FontWeight.w600,
      color: theme.titleLarge?.color ?? Colors.black,
    );

    subtitle = GoogleFonts.montserrat(
      fontSize: 18,
      fontWeight: FontWeight.w500,
      color: theme.titleLarge?.color ?? Colors.black,
    );

    body = GoogleFonts.montserrat(
      fontSize: 16,
      color: theme.titleLarge?.color ?? Colors.black,
    );

    caption = GoogleFonts.montserrat(
      fontSize: 12,
      color: theme.titleLarge?.color ?? Colors.black,
    );
  }

}