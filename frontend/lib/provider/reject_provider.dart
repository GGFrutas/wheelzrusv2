import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:frontend/models/reject_reason_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Fetch rejection reasons from the API
Future<List<RejectionReason>> fetchReasons() async {
  try {
    final response = await http.get(Uri.parse('http://10.0.2.2:8000/api/odoo/reason'));

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((json) => RejectionReason.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load reasons: ${response.statusCode}');
    }
  } catch (e) {
    throw Exception('Error fetching reasons: $e');
  }
}

// Define the provider that fetches the rejection reasons
final rejectionReasonsProvider = FutureProvider<List<RejectionReason>>((ref) async {
  return fetchReasons();
});
