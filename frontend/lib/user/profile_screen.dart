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
import 'package:frontend/user/about_me_pfp_screen.dart';
import 'package:frontend/user/licensing_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import 'package:frontend/theme/colors.dart';
import 'package:frontend/theme/text_styles.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileScreen extends ConsumerStatefulWidget{
  final String uid;

  const ProfileScreen({super.key, required this.uid});

  @override

  ConsumerState<ProfileScreen> createState() => _ProfileScreenPageState();
}

// Custom widget for Profile Menu
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

class _ProfileScreenPageState extends ConsumerState<ProfileScreen>{

  // Define tPrimaryColor
  final Color tPrimaryColor = Colors.green; // Replace Colors.green with your desired color

  @override
  Widget build(BuildContext context) {
  
    final authState = ref.watch(authNotifierProvider);
    Uint8List? imageBytes;
    if (authState.partnerImageBase64 != null &&
        authState.partnerImageBase64!.isNotEmpty) {
      try {
        imageBytes = base64Decode(authState.partnerImageBase64!);
      } catch (e) {
        // Handle invalid base64
        imageBytes = null;
      }
    }
    
   
    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: mainColor),
        title: Text(
          'Profile',
          style: AppTextStyles.title.copyWith(
            color: mainColor,
          ),
        ),
        // backgroundColor: const Color(0xFF1d3c34),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [

              /// -- IMAGE
              Stack(
                alignment: Alignment.topCenter,
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color:Colors.grey.shade300,
                      shape: BoxShape.circle,
                    ),
                   
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(100), 
                      child: authState.partnerImageBase64 != null && authState.partnerImageBase64!.isNotEmpty && imageBytes != null
                        ? Image.memory(
                            imageBytes,
                            fit: BoxFit.cover,
                            width: 120,
                            height: 120,
                          )
                        : Image.asset(
                            'assets/xlogo.png',
                            fit: BoxFit.cover,
                            width: 120,
                            height: 120,
                          ), 
                  
                    ) 
                  
                  )
                ],
              ),
              const SizedBox(height: 10),
              Text(
                authState.driverName ?? 'No Name',
                style: AppTextStyles.subtitle.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                authState.login  ?? 'No Email',
                style: AppTextStyles.caption.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height:50),


              /// -- MENU
              ProfileMenuWidget(
                title: "About Me", 
                icon: LineAwesomeIcons.users_solid, 
                onPress: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AboutMeScreen(uid: widget.uid),
                    ),
                  );
                }),
              ProfileMenuWidget(
                title: "License & ID Verification",
                 icon: LineAwesomeIcons.id_card, 
                 onPress: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => LicenseScreen(uid: widget.uid),
                    ),
                  );
                 }),
              ProfileMenuWidget(title: "Vehicle Details", icon: LineAwesomeIcons.truck_solid, onPress: () {}),
            
             
            ],
          ),
        ),
      ),
      bottomNavigationBar: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column (
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: (() => _logout(context, ref)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: mainColor,
                        padding: const EdgeInsets.symmetric(horizontal: 100, vertical: 20),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30.0),
                        ),
                      ),
                      child: Text(
                        "Log out",
                        style: AppTextStyles.body.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  )
                ],
              )
              
            ),
          ],
          
        )
    );
  }
  
  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    ref.read(themeProvider.notifier).state = true;

    // Remove token from shared preferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');

    if (!context.mounted) return; // Ensure the widget is still mounted

    // Navigate to the Login screen
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const LoginScreen(),
      ),
    );
  }
}



