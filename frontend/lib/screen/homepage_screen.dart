// homepage_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/notifiers/navigation_notifier.dart';
import 'package:frontend/provider/theme_provider.dart';
import 'package:frontend/screen/login_screen.dart';
import 'package:frontend/screen/navigation_menu.dart';
import 'package:frontend/user/homepage_screen.dart';
import 'package:frontend/user/transaction_screen.dart';
import 'package:frontend/user/updateuser_screen.dart';
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
    return 'http://10.0.2.2:8000/storage/$picture'; // Correct URL for the emulator
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // final isLightTheme = ref.watch(themeProvider);
    final selectedIndex = ref.watch(navigationNotifierProvider);

    // Define the different pages based on navigation index
    final List<Widget> pages = [
      TransactionScreen(user: user),
      HomepageScreen(user: user),
      UpdateUserScreen(user: user),
    ];

    return Scaffold(
      // appBar: AppBar(
      //   title: Text(
      //     'Wheelzrus',
      //     style: GoogleFonts.poppins(
      //       fontSize: 24,
      //       fontWeight: FontWeight.bold,
      //     ),
      //   ),
      // actions: [
      //   Padding(
      //     padding: const EdgeInsets.all(10.0),
      //     child: SizedBox(
      //       width: 55,
      //       height: 30,
      //       child: AnimatedToggleSwitch<bool>.dual(
      //         current: isLightTheme,
      //         first: false,
      //         second: true,
      //         spacing: 1,
      //         style: ToggleStyle(
      //           backgroundColor:
      //               isLightTheme ? Colors.white : Colors.grey[800],
      //           borderColor: Colors.transparent,
      //           boxShadow: [
      //             const BoxShadow(
      //               color: Colors.black26,
      //               spreadRadius: 1,
      //               blurRadius: 2,
      //               offset: Offset(0, 1.5),
      //             ),
      //           ],
      //         ),
      //         borderWidth: 4,
      //         height: 50,
      //         onChanged: (b) {
      //           // Update the theme state without setState
      //           ref.read(themeProvider.notifier).state = b;
      //         },
      //         styleBuilder: (b) => ToggleStyle(
      //           indicatorColor: !b ? Colors.blue : Colors.green,
      //         ),
      //         iconBuilder: (value) => value
      //             ? const FittedBox(
      //                 fit: BoxFit.contain,
      //                 child: Icon(
      //                   Icons.wb_sunny,
      //                   color: Colors.white,
      //                   size: 18,
      //                 ),
      //               )
      //             : const FittedBox(
      //                 fit: BoxFit.contain,
      //                 child: Icon(
      //                   Icons.nights_stay,
      //                   // color: Colors.white,
      //                   size: 18,
      //                 ),
      //               ),
      //       ),
      //     ),
      //   ),
      // ],
      // ),
      // drawer: Drawer(
      //   child: ListView(
      //     padding: EdgeInsets.zero,
      //     children: <Widget>[
      //       UserAccountsDrawerHeader(
      //         accountName: Text(
      //           user['name'] ?? 'Guest',
      //           style: GoogleFonts.poppins(
      //             textStyle: const TextStyle(
      //               fontWeight: FontWeight.bold,
      //               fontSize: 16,
      //             ),
      //           ),
      //         ),
      //         accountEmail: Text(
      //           user['email'] ?? 'No Email',
      //           style: GoogleFonts.poppins(
      //             textStyle: const TextStyle(
      //               fontWeight: FontWeight.bold,
      //               fontSize: 12,
      //             ),
      //           ),
      //         ),
      //         currentAccountPicture: CircleAvatar(
      //           radius: 30,
      //           child: (user['picture'] != null &&
      //                   (user['picture'] as String).isNotEmpty)
      //               ? ClipOval(
      //                   child: Image.network(
      //                     _getProfileImageUrl(user['picture']),
      //                     fit: BoxFit.cover,
      //                     width: 100,
      //                     height: 100,
      //                   ),
      //                 )
      //               : Text(
      //                   (user['name'] as String).isNotEmpty
      //                       ? (user['name'] as String)[0].toUpperCase()
      //                       : '?',
      //                   style: const TextStyle(fontSize: 40.0),
      //                 ),
      //         ),
      //       ),
      //       ListTile(
      //         leading: const Icon(Icons.edit),
      //         title: const Text('Update Profile'),
      //         onTap: () {
      //           Navigator.push(
      //             context,
      //             MaterialPageRoute(
      //               builder: (context) => UpdateUserScreen(user: user),
      //             ),
      //           );
      //         },
      //       ),
      //       ListTile(
      //         leading: const Icon(Icons.logout),
      //         title: const Text('Logout'),
      //         onTap: () => _logout(context, ref),
      //       ),
      //     ],
      //   ),
      // ),
      body: IndexedStack(
        index: selectedIndex,
        children: pages,
      ),
      bottomNavigationBar: const NavigationMenu(),
    );
  }
}
