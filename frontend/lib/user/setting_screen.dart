import 'package:animated_toggle_switch/animated_toggle_switch.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/provider/theme_provider.dart';
import 'package:frontend/user/profile_screen.dart';
import 'package:google_fonts/google_fonts.dart';

class SettingScreen extends ConsumerStatefulWidget{
  final String uid;

  const SettingScreen({super.key, required this.uid});

  @override
  // ignore: library_private_types_in_public_api
  // _SettingPageState createState() => _SettingPageState();
  ConsumerState<SettingScreen> createState() => _SettingPageState();
}

class _SettingPageState extends ConsumerState<SettingScreen>{
  @override
  Widget build(BuildContext context) {
    final isLightTheme = ref.watch(themeProvider);
    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          'Settings',
          style: GoogleFonts.poppins(
            fontSize: 24,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF1d3c34),
        centerTitle: true,
      ),
      body:ListView (
        children: [
          _buildSectionHeader("Appearance"),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.dark_mode, color: Colors.blue),
                    const SizedBox(width:10),
                    Text(
                      "Dark Mode",
                      style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w500 ),
                    ),
                  ],
                ),
                SizedBox(
                  width: 55,
                  height: 30,
                  child: AnimatedToggleSwitch<bool>.dual(
                    current: isLightTheme,
                    first:false,
                    second:true,
                    spacing:1,
                    style:ToggleStyle(
                      backgroundColor: isLightTheme ? Colors.white : Colors.grey[800],
                      borderColor: Colors.transparent,
                      boxShadow: [
                        const BoxShadow(
                          color:Colors.black26,
                          spreadRadius: 1,
                          blurRadius: 2,
                          offset: Offset(0, 1.5),
                        ),
                      ],
                    ),
                    borderWidth: 4,
                    height: 50,
                    onChanged:(b){
                      ref.read(themeProvider.notifier).state = b;
                    },
                    styleBuilder:(b) => ToggleStyle(
                      indicatorColor: !b ? Colors.blue: Colors.green,
                    ),
                    iconBuilder:(value) => value
                      ? const FittedBox(
                        fit: BoxFit.contain,
                        child: Icon(Icons.wb_sunny, color: Colors.white, size: 18),
                      )
                      : const FittedBox(
                        fit: BoxFit.contain,
                        child:Icon(Icons.nights_stay,size: 18),
                      ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _buildSectionHeader("Account"),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      print("Profile pressed");
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProfileScreen(uid:widget.uid),
                        ),
                      );
                    }, 
                    child: Row(
                      children: [
                        const Icon(Icons.person, color: Colors.blue),
                        const SizedBox(width:10),
                        Text(
                          "Profile",
                          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w500 ),
                        ),
                      ],
                    ),
                  ),
                )
              ],
            ),
          ),
        ],
      )
    );
  }
  Widget _buildSectionHeader(String title){
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        title,
        style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold),
      )
    );
  }

  
  
}