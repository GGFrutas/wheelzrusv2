// homepage_screen.dart

// ignore_for_file: unused_import

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

   final ongoingTransactions = ref.watch(filteredItemsProvider);

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

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
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
                      leading: const Icon(Icons.bookmark_border_rounded),
                      iconColor: mainColor,
                      title: Text(
                        'Ongoing Delivery',
                        style: AppTextStyles.body.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      trailing: ongoingTransactions.when(
                        data: (transactions) => transactions.isNotEmpty
                            ? Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: const BoxDecoration(
                                  color: Color.fromARGB(255, 152, 203, 186),
                                ),
                                child: Text(
                                  transactions.length.toString(),
                                  style: AppTextStyles.caption.copyWith(
                                    color: mainColor,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              )
                            : null,
                        loading: () => const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        error: (error, stack) => const Icon(Icons.error, color: Colors.red),
                      ),
                      onTap: () {
                        ref.read(navigationNotifierProvider.notifier).setSelectedIndex(0);
                        Navigator.pop(context); // Close the drawer
                      },
                    ),

                    const Divider(), // Add a divider for better separation

                    ListTile(
                      leading: const Icon(Icons.settings_outlined),
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
                    ListTile(
                      leading: const Icon(Icons.pie_chart_outline_rounded),
                      iconColor: mainColor,
                      title: Text(
                        'Analytics',
                        style: AppTextStyles.body.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onTap: () {},
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: const BoxDecoration(
                  border: Border(top:BorderSide(color: Colors.grey, width: 0.2)),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 8),
                    const CircleAvatar(
                      radius: 24,
                      backgroundImage: NetworkImage(
                      'assets/xlogo.png', // Replace with user['profileImage'] if available
                      ),
                    ),
                    const SizedBox(width: 8),
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
            ],
          ),
        ),
        body: IndexedStack(
          index: selectedIndex,
          children: pages,
        ),
      bottomNavigationBar: const NavigationMenu(),
      ),
    );
  }
}
