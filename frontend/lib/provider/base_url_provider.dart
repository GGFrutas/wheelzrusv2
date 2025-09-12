import 'package:flutter_riverpod/flutter_riverpod.dart';

final baseUrlProvider = Provider<String>((ref) {
  // You can change the base URL here
  return 'http://10.18.58.53:8000'; // Replace with your actual base URL
});