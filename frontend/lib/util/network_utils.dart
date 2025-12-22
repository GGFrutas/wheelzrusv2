import 'package:http/http.dart' as http;

Future<bool> hasInternetConnection() async {
    try {
      final response = await http.get(Uri.parse("https://www.google.com"));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
}