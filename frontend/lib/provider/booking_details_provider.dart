import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class BookingDetailProvider with ChangeNotifier {
  final String baseUrl;

  BookingDetailProvider(this.baseUrl);

  Map<String, dynamic>? dispatch;
  List<dynamic> history = [];
  Map<String, dynamic>? consolidation;

  bool isLoading = false;
  String? errorMessage;

  Future<void> fetchBookingDetail(String id, String uid, String password) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/booking_detail?id=$id&include=history,consolidation'),
        headers: {
          'uid': uid,
          'password': password,
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body)['data'];
        dispatch = data['dispatch'];
        history = data['history'];
        consolidation = data['consolidation'];
      } else {
        errorMessage = 'Failed to load booking details (${response.statusCode})';
      }
    } catch (e) {
      errorMessage = 'Error: ${e.toString()}';
    }

    isLoading = false;
    notifyListeners();
  }
}
