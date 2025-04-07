// ignore_for_file: unused_import

import 'dart:io';

import 'package:animated_toggle_switch/animated_toggle_switch.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/provider/theme_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';

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
      title: Text(title, style: TextStyle(color: textColor ?? Theme.of(context).textTheme.bodyLarge?.color)),
      trailing: endIcon ? const Icon(Icons.arrow_forward_ios, size: 16) : null,
    );
  }
}

class _ProfileScreenPageState extends ConsumerState<ProfileScreen>{

  // Define tPrimaryColor
  final Color tPrimaryColor = Colors.green; // Replace Colors.green with your desired color
  
  // Define tDarkColor

  // @override
  // Widget build(BuildContext context) {
  //   return Scaffold(
  //     appBar: AppBar(
  //       iconTheme: const IconThemeData(color: Colors.white),
  //       title: Text(
  //         'Profile',
  //         style: GoogleFonts.poppins(
  //           fontSize: 24,
  //           color: Colors.white,
  //           fontWeight: FontWeight.bold,
  //         ),
  //       ),
  //       backgroundColor: const Color(0xFF1d3c34),
  //       centerTitle: true,
  //     ),
  //     body: SingleChildScrollView (
  //       child: Container(
  //         padding: const EdgeInsets.all(16),
  //         child: Column(
  //           children:[
  //             SizedBox(
  //               width: 120, height: 120,
  //               child:
  //                 ClipRRect(
  //                   borderRadius: BorderRadius.circular(100),
  //                   child:
  //                     const Image(image: AssetImage('assets/xlogo.png')),
  //                 )
  //             ),
  //             const SizedBox(height: 10),
  //             Text('Initials', style: Theme.of(context).textTheme.headlineMedium),
  //           ]
            
  //         ),
  //       )
          
  //     )
  //   );
  // }  
  @override
  Widget build(BuildContext context) {
   
    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          'Profile',
          style: GoogleFonts.poppins(
            fontSize: 24,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF1d3c34),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [

              /// -- IMAGE
              Stack(
                children: [
                  SizedBox(
                    width: 120,
                    height: 120,
                    child: ClipRRect(
                        borderRadius: BorderRadius.circular(100), child: const Image(image: AssetImage('assets/xlogo.png'))),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 35,
                      height: 35,
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(100), color: tPrimaryColor),
                      // child: const Icon(
                      //   LineAwesomeIcons.alternate_pencil,
                      //   color: Colors.black,
                      //   size: 20,
                      // ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text("initials", style: Theme.of(context).textTheme.headlineMedium),
              Text("Email", style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 20),

              /// -- BUTTON
              SizedBox(
                width: 200,
                child: ElevatedButton(
                  onPressed: null,
                  style: ElevatedButton.styleFrom(
                      backgroundColor: tPrimaryColor, side: BorderSide.none, shape: const StadiumBorder()),
                  child: const Text("Edit Profile", style: TextStyle(color: Color(0xFF1d3c34))),
                ),
              ),
              const SizedBox(height: 30),
              const Divider(),
              const SizedBox(height: 10),

              /// -- MENU
              ProfileMenuWidget(title: "Settings", icon: LineAwesomeIcons.cogs_solid, onPress: () {}),
              ProfileMenuWidget(title: "Billing Details", icon: LineAwesomeIcons.wallet_solid, onPress: () {}),
              ProfileMenuWidget(title: "User Management", icon: LineAwesomeIcons.user, onPress: () {}),
              const Divider(),
              const SizedBox(height: 10),
              ProfileMenuWidget(title: "Information", icon: LineAwesomeIcons.info_solid, onPress: () {}),
              ProfileMenuWidget(
                  title: "Logout",
                  icon: LineAwesomeIcons.copy,
                  textColor: Colors.red,
                  endIcon: false,
                  onPress: () {
                    // Get.defaultDialog(
                    //   title: "LOGOUT",
                    //   titleStyle: const TextStyle(fontSize: 20),
                    //   content: const Padding(
                    //     padding: EdgeInsets.symmetric(vertical: 15.0),
                    //     child: Text("Are you sure, you want to Logout?"),
                    //   ),
                    //   confirm: Expanded(
                    //     child: ElevatedButton(
                    //       onPressed: () => AuthenticationRepository.instance.logout(),
                    //       style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, side: BorderSide.none),
                    //       child: const Text("Yes"),
                    //     ),
                    //   ),
                    //   cancel: OutlinedButton(onPressed: () => Get.back(), child: const Text("No")),
                    // );
                  }),
            ],
          ),
        ),
      ),
    );
  }
}



