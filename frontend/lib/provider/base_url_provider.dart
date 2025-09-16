import 'package:flutter_riverpod/flutter_riverpod.dart';

final baseUrlProvider = Provider<String>((ref) {
  // You can change the base URL here
  return 'http://192.168.118.102:8000'; // Replace with your actual base URL
});