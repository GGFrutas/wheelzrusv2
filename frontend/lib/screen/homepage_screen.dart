// homepage_screen.dart

// ignore_for_file: unused_import, depend_on_referenced_packages

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/notifiers/auth_notifier.dart';
import 'package:frontend/notifiers/navigation_notifier.dart';
import 'package:frontend/provider/theme_provider.dart';
import 'package:frontend/provider/transaction_list_notifier.dart';
import 'package:frontend/provider/transaction_provider.dart';
import 'package:frontend/screen/login_screen.dart';
import 'package:frontend/screen/navigation_menu.dart';
import 'package:frontend/theme/colors.dart';
import 'package:frontend/theme/text_styles.dart';
import 'package:frontend/user/history_screen.dart';
import 'package:frontend/user/homepage_screen.dart';
import 'package:frontend/user/profile_screen.dart';
import 'package:frontend/user/setting_screen.dart';
import 'package:frontend/user/transaction_screen.dart';
import 'package:frontend/user/updateuser_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class HomePage extends ConsumerWidget {
  final Map<String, dynamic> user;

  const HomePage({super.key, required this.user});

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    // Update the theme state
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


  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = ref.watch(navigationNotifierProvider);
    final authState = ref.watch(authNotifierProvider);
    final String uid = authState.uid ?? '';

  //  final ongoingTransactions = ref.watch(filteredItemsProvider);
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

    // Define the different pages based on navigation index
    

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if(!didPop) {
          if(selectedIndex != 1) {
            ref.read(navigationNotifierProvider.notifier).setSelectedIndex(1);
          } else {
            SystemNavigator.pop();
          }
        }
      },
      child: Scaffold(
        appBar: AppBar(
          iconTheme: const IconThemeData(color: mainColor),
          title: Image.asset(
            'assets/Yello X.png',
            height: 40,
          ),
          backgroundColor: const Color.fromARGB(255, 255, 255, 255),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.notifications_none, color: mainColor),
              onPressed: () {
                // Handle notification tap
              },
            ),
          ],
        ),

        drawer: Drawer(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          elevation: 0,
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    Container(
                      color: Colors.white,
                      padding: const EdgeInsets.fromLTRB(16, 100, 16, 16), // Top padding for status bar
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Image.asset(
                                'assets/xlogo.png',
                                width: 50,
                                height: 50,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'YXE Driver App',
                                style: AppTextStyles.title.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: mainColor,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            decoration: InputDecoration(
                                hintText: 'Search',
                                hintStyle: AppTextStyles.caption.copyWith(color: Colors.black, fontWeight: FontWeight.w500),
                                prefixIcon: const Icon(Icons.search),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8.0),
                                  borderSide: const BorderSide(color: mainColor),
                                ),
                              ),
                          ),
                        ],
                      ),
                    ),

                    ListTile(
                      leading: const Icon(Icons.bar_chart_rounded),
                      iconColor: mainColor,
                      title: Text(
                        'Dashboard',
                        style: AppTextStyles.body.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      onTap: () {
                        ref.read(navigationNotifierProvider.notifier).setSelectedIndex(1);
                        Navigator.pop(context); // Close the drawer
                      },
                    ),
                    ListTile(
                      leading: const FaIcon(FontAwesomeIcons.bookmark),
                      iconColor: mainColor,
                      title: Text(
                        'Ongoing Delivery',
                        style: AppTextStyles.body.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      
                      onTap: () {
                        ref.read(navigationNotifierProvider.notifier).setSelectedIndex(0);
                        Navigator.pop(context); // Close the drawer
                      },
                    ),

                    // const Divider(), // Add a divider for better separation

                    ListTile(
                      leading: const FaIcon(FontAwesomeIcons.gear),
                      iconColor: mainColor,
                      title: Text(
                        'Settings',
                        style: AppTextStyles.body.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SettingScreen(uid: uid),
                          ),
                        );
                      },
                    ),
                    // ListTile(
                    //   leading: const FaIcon(FontAwesomeIcons.paperPlane),
                    //   iconColor: mainColor,
                    //   title: Text(
                    //     'Dispatch',
                    //     style: AppTextStyles.body.copyWith(
                    //       fontWeight: FontWeight.bold,
                    //     ),
                    //   ),
                    //   onTap: () {},
                    // ),
                    // ListTile(
                    //   leading: const FaIcon(FontAwesomeIcons.ban),
                    //   iconColor: mainColor,
                    //   title: Text(
                    //     'Declined',
                    //     style: AppTextStyles.body.copyWith(
                    //       fontWeight: FontWeight.bold,
                    //     ),
                    //   ),
                    //   onTap: () {},
                    // ),
                    // ListTile(
                    //   leading: const FaIcon(FontAwesomeIcons.circleCheck),
                    //   iconColor: mainColor,
                    //   title: Text(
                    //     'Completed',
                    //     style: AppTextStyles.body.copyWith(
                    //       fontWeight: FontWeight.bold,
                    //     ),
                    //   ),
                    //   onTap: () {},
                    // ),
                    // ListTile(
                    //   leading: const Icon(FontAwesomeIcons.chartPie),
                    //   iconColor: mainColor,
                    //   title: Text(
                    //     'Analytics',
                    //     style: AppTextStyles.body.copyWith(
                    //       fontWeight: FontWeight.bold,
                    //     ),
                    //   ),
                    //   onTap: () {},
                    // ),
                  ],
                ),
              ),
              InkWell(
                onTap:(){
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProfileScreen(uid: uid),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: const BoxDecoration(
                    border: Border(top:BorderSide(color: Colors.grey, width: 0.2)),
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(100), 
                        child: authState.partnerImageBase64 != null && authState.partnerImageBase64!.isNotEmpty && imageBytes != null
                          ? Image.memory(
                              imageBytes,
                              fit: BoxFit.cover,
                              width: 50,
                              height: 50,
                            )
                          : Image.asset(
                              'assets/xlogo.png',
                              fit: BoxFit.cover,
                              width: 50,
                              height: 50,
                            ), 
                    
                      ), 
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              authState.driverName ?? 'No Name',
                              style: AppTextStyles.subtitle.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              user['login'] ?? 'No Email',
                              style: AppTextStyles.caption.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.logout, color: mainColor),
                        onPressed: () => _logout(context, ref),
                      ),
                    ],
                  ),
                ),
              
              ),
             
            ],
          ),
        ),
       body: Builder(
        builder: (_) {
          switch (selectedIndex) {
            case 0:
              return TransactionScreen(user: user);
            case 1:
              return HomepageScreen(user: user);
            case 2:
              return HistoryScreen(user: user, transaction: null,);
            default:
              return const SizedBox.shrink();
          }
        },
      ),
      bottomNavigationBar: const NavigationMenu(),
      ),
    );
  }
}
