import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTextStyles {
  static final title = GoogleFonts.montserrat(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: Colors.black,
      );

  static final subtitle = GoogleFonts.montserrat(
        fontSize: 18,
        fontWeight: FontWeight.w500,
      );

  static final body = GoogleFonts.montserrat(
        fontSize: 16,
        color: Colors.black87,
      );

  static final caption = GoogleFonts.montserrat(
        fontSize: 12,
        color: Colors.black54,
      );
}