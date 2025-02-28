import 'package:flutter/material.dart';

class UsersScreen extends StatelessWidget {
  final List<Map<String, dynamic>> users;

  const UsersScreen({Key? key, required this.users}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Odoo Users'),
      ),
      body: ListView.builder(
        itemCount: users.length,
        itemBuilder: (context, index) {
          final user = users[index];
          return ListTile(
            title: Text(user['name'] ?? 'Unknown Name'),
            subtitle: Text(user['email'] ?? 'No Email'),
          );
        },
      ),
    );
  }
}
