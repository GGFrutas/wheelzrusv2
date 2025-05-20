// homepage_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/notifiers/auth_notifier.dart';
import 'package:frontend/notifiers/navigation_notifier.dart';
import 'package:frontend/provider/theme_provider.dart';
import 'package:frontend/screen/login_screen.dart';
import 'package:frontend/screen/navigation_menu.dart';
import 'package:frontend/user/history_screen.dart';
import 'package:frontend/user/homepage_screen.dart';
import 'package:frontend/user/profile_screen.dart';
import 'package:frontend/user/setting_screen.dart';
import 'package:frontend/user/transaction_screen.dart';
import 'package:frontend/user/updateuser_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  String _getProfileImageUrl(String picture) {
    return 'http://192.168.18.53:8000/storage/$picture'; // Correct URL for the emulator
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = ref.watch(navigationNotifierProvider);
    final authState = ref.watch(authNotifierProvider);
    final String uid = authState.uid ?? '';

    // Define the different pages based on navigation index
    final List<Widget> pages = [
      TransactionScreen(user: user),
      HomepageScreen(user: user),
      HistoryScreen(user: user),
      UpdateUserScreen(user: user, uid: uid,),
      SettingScreen(uid: uid),
      // ProofOfDeliveryScreen(uid: uid, transaction: null, base64Images: base64Image), // Replace with a valid transaction object
      ProfileScreen(uid: uid),
    ];

    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Color.fromARGB(255, 39, 142, 78)),
        title: Image.asset(
          'assets/Yello X.png',
          height: 40,
        ),
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Color.fromARGB(255, 46, 90, 83)),
            onPressed: () {
              // Handle notification tap
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            UserAccountsDrawerHeader(
              accountName: Text(
                user['name'] ?? 'Driver',
                style: GoogleFonts.montserrat(
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              accountEmail: Text(
                user['login'] ?? 'No Email',
                style: GoogleFonts.montserrat(
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              currentAccountPicture: CircleAvatar(
                radius: 30,
                child: (user['picture'] != null &&
                        (user['picture'] as String).isNotEmpty)
                    ? ClipOval(
                        child: Image.network(
                          _getProfileImageUrl(user['picture']),
                          fit: BoxFit.cover,
                          width: 100,
                          height: 100,
                        ),
                      )
                    // : Text(
                    //     (user['name'] as String).isNotEmpty
                    //         ? (user['name'] as String)[0].toUpperCase()
                    //         : '?',
                    //     style: const TextStyle(fontSize: 40.0),
                    //   ),
                    : Image.asset(
                      'assets/xlogo.png',
                      width: 50,
                      height:  50,
                    ),
              ),
            ),
            // ListTile(
            //   leading: const Icon(Icons.edit),
            //   title: const Text('Update Profile'),
            //   onTap: () {
            //     Navigator.push(
            //       context,
            //       MaterialPageRoute(
            //         builder: (context) => UpdateUserScreen(user: user, uid: uid),
            //       ),
            //     );
            //   },
            // ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SettingScreen(uid: uid),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () => _logout(context, ref),
            ),
          ],
        ),
      ),
      body: IndexedStack(
        index: selectedIndex,
        children: pages,
      ),
      bottomNavigationBar: const NavigationMenu(),
    );
  }
}
