// ignore_for_file: unused_import

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:animated_toggle_switch/animated_toggle_switch.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/notifiers/auth_notifier.dart';
import 'package:frontend/provider/theme_provider.dart';
import 'package:frontend/screen/login_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import 'package:frontend/theme/colors.dart';
import 'package:frontend/theme/text_styles.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LicenseScreen extends ConsumerStatefulWidget{
  final String uid;

  const LicenseScreen({super.key, required this.uid});

  @override

  ConsumerState<LicenseScreen> createState() => _LicenseScreenPageState();
}

class ProfileMenuWidget extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onPress;
  final Color? textColor;
  final bool endIcon;

  const ProfileMenuWidget({
    super.key,
    required this.title,
    required this.icon,
    required this.onPress,
    this.textColor,
    this.endIcon = true,
  });
  
  

  @override
  Widget build(BuildContext context) {
    
    return ListTile(
      onTap: onPress,
      leading: Icon(icon, color: textColor ?? Theme.of(context).iconTheme.color),
      title: Text(title, style: AppTextStyles.subtitle.copyWith(color: textColor ?? Theme.of(context).textTheme.bodyLarge?.color)),
      trailing: endIcon ? const Icon(Icons.arrow_forward_ios, size: 16) : null,
    );
  }
  
}
String formatDateTime(String? dateString) {
  if (dateString == null || dateString.isEmpty) return "—"; // Handle null values
  
  try {
    DateTime dateTime = DateTime.parse(dateString).toLocal();
      // Convert string to DateTime
      return DateFormat('MMMM d, yyyy').format(dateTime); // Format date-time
  } catch (e) {
    return "Invalid Date"; // Handle errors gracefully
  }
} 

  

class _LicenseScreenPageState extends ConsumerState<LicenseScreen>{

  // Define tPrimaryColor
  final Color tPrimaryColor = Colors.green; // Replace Colors.green with your desired color

  @override
  Widget build(BuildContext context) {
  
    final authState = ref.watch(authNotifierProvider);
  
   
    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: mainColor),
        title: Text(
          'License Information',
          style: AppTextStyles.subtitle.copyWith(
            color: mainColor,
          ),
        ),
        // backgroundColor: const Color(0xFF1d3c34),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 50),
                  Text(
                    "License Number",
                    style: AppTextStyles.caption.copyWith(
                      fontWeight: FontWeight.bold,  
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    readOnly: true,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                        borderSide: BorderSide.none,
                      ),
                      hintText: authState.licenseNumber ?? '',
                      filled: true,
                      fillColor: const Color.fromARGB(255, 234, 240, 238),
                      hintStyle: AppTextStyles.body, // Use caption style for hint text
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "License Expiry Date",
                    style: AppTextStyles.caption.copyWith(
                      fontWeight: FontWeight.bold,  
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    readOnly: true,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                        borderSide: BorderSide.none,
                      ),
                      hintText: (formatDateTime(authState.licenseExpiry)),
                      filled: true,
                      fillColor: const Color.fromARGB(255, 234, 240, 238),
                      hintStyle: AppTextStyles.body, // Use caption style for hint text
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "License Status",
                    style: AppTextStyles.caption.copyWith(
                      fontWeight: FontWeight.bold,  
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    readOnly: true,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                        borderSide: BorderSide.none,
                      ),
                      hintText: authState.licenseStatus ?? '' .toUpperCase(),
                      filled: true,
                      fillColor: const Color.fromARGB(255, 234, 240, 238),
                      hintStyle: AppTextStyles.body, // Use caption style for hint text
                    ),
                  ),
                   const SizedBox(height: 20)
                ]
              )
            ),
          ]
        ),
      ),
     
    );
  }
  

}



