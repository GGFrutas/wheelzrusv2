import 'package:flutter/foundation.dart';

class UserModel extends ChangeNotifier {
  String? _name;
  String? _email;
  String? _token;

  String? get name => _name;
  String? get email => _email;
  String? get token => _token;

  void updateUser({String? name, String? email, String? token}) {
    if (name != null) _name = name;
    if (email != null) _email = email;
    if (token != null) _token = token;
    notifyListeners(); // Notify listeners to rebuild UI
  }
}
