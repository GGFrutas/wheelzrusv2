// ignore_for_file: deprecated_member_use

import 'dart:convert';
import 'package:frontend/models/transaction_model.dart';
import 'package:frontend/notifiers/auth_notifier.dart';
import 'package:frontend/provider/base_url_provider.dart';
import 'package:frontend/user/map_api.dart';
import 'package:http/http.dart' as http;
import 'package:frontend/models/reject_reason_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


class RejectedTransactionNotifier extends StateNotifier<Set<Transaction>> {
  RejectedTransactionNotifier():super({});

}
// Fetch rejection reasons from the API
Future<List<RejectionReason>> fetchReasons(FutureProviderRef<List<RejectionReason>> ref, {required uid}) async {
  try {
    final uid = ref.watch(authNotifierProvider).uid;
    final password = ref.watch(authNotifierProvider).password ?? '';
    final baseUrl = ref.watch(baseUrlProvider);

    if (uid == null || uid.isEmpty) {
      // print('❌ UID not found or empty!');
      throw Exception('UID is missing. Please log in.');
    }
    // print('✅ Retrieved UID: $uid'); // Debugging UID
    final response = await http.get(Uri.parse('$baseUrl/api/odoo/reason?uid=$uid'), 
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'password': password,
      },
    );

    if (response.statusCode == 200) {
      Map<String, dynamic> decodedResponse = json.decode(response.body); // Decode as a Map

      if (decodedResponse.containsKey("result") && decodedResponse["result"] is List) {
        List<dynamic> data = decodedResponse["result"]; // Extract the list from "result"
        return data.map((json) => RejectionReason.fromJson(json)).toList();
      } else {
        throw Exception('Invalid response format: "result" key missing or not a list.');
      }
    } else {
      throw Exception('Failed to load reasons: ${response.statusCode}');
    }  } catch (e) {
    throw Exception('Error fetching reasons: $e');
  }
}

final selectedReasonsProvider = StateProvider<String?>((ref) => null);

// Define the provider that fetches the rejection reasons
final rejectionReasonsProvider = FutureProvider<List<RejectionReason>>((ref) async {
  return fetchReasons(ref, uid: null);
});

final rejectedTransactionProvider =
    StateNotifierProvider<RejectedTransactionNotifier, Set<Transaction>>((ref) {
  return RejectedTransactionNotifier();
});

Future<List<Transaction>> fetchReject(FutureProviderRef<List<Transaction>> ref, {required uid}) async {
  try {
    final uid = ref.watch(authNotifierProvider).uid;
    final password = ref.watch(authNotifierProvider).password ?? '';

  
    if (uid == null || uid.isEmpty) {
      throw Exception('UID is missing. Please log in.');
    }
    // print('✅ Retrieved UID: $uid'); // Debugging UID

    final response = await http.get(
      Uri.parse('$baseUrl/api/odoo/booking?uid=$uid'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'password': password,
      },
    );

    // print("Response Status: ${response.statusCode}");
    // print("Response Body: ${response.body}");

    if (response.statusCode == 200) {
      if (response.body.isEmpty) {
        // print("🚨 Empty response body.");
        throw Exception('Empty response body.');
      }
      final decodedData = json.decode(response.body);
      // print("🔍 Decoded Response: $decodedData"); // Debugging

      if (decodedData is Map && decodedData.containsKey("data")) {
        final data = decodedData["data"];

        // print("🔍 Data object: $data"); // Debugging: Print the entire "data" object

        if (data is Map) {
          if (data.containsKey("transactions")) {
            // print("🔍 'transactions' found: ${data['transactions']}"); // Debugging
            
            final transactions = data["transactions"];

            // Check what type "transactions" actually is
            // print("🔍 Type of 'transactions': ${transactions.runtimeType}");

            if (transactions is Map<String, dynamic>) {
              final transactionsList = transactions.values.toList();
              // print("✅ Parsed transactions count: ${transactionsList.length}");
              return transactionsList.map((json) => Transaction.fromJson(json)).toList();
            } 
            else if (transactions is List) {
              // print("✅ Transactions is a List with ${transactions.length} items.");
              return transactions.map((json) => Transaction.fromJson(json)).toList();
            } 
            else {
              // print("🚨 'transactions' is neither a Map nor a List.");
              return [];
            }
          } else {
            // print("🚨 'transactions' key not found in 'data'.");
          }
        } else {
          // print("🚨 'data' is not a Map.");
        }
      }
    }
  } catch (e) {
    throw Exception('Error fetching transactions: $e');
  }
  throw Exception('Unexpected error occurred.');
}


final rejectedProvider = FutureProvider<List<Transaction>>((ref) async {
  final authState = ref.watch(authNotifierProvider); // Get full auth state
  // print('🟡 Auth State: $authState'); // Debugging
  
  final uid = authState.uid;
  
  if (uid == null || uid.isEmpty) {
    // print('❌ UID not found inside authNotifierProvider!');
    throw Exception('UID not found. Please log in.');
  }

  // print('✅ Retrieved UID in rejectedProvider: $uid'); // Debugging

  return fetchReject(ref, uid: uid); // ✅ Pass uid properly
});

final filteredRejected = FutureProvider<List<Transaction>>((ref) async {
  final transactions = await ref.watch(rejectedProvider.future);

  // print("🔍 Total transactions before filtering: ${transactions.length}");

  final filtered = transactions.where((t) {
    final isRejected = t.deRequestStatus == 'Rejected' || 
                         t.plRequestStatus == 'Rejected' ||
                         t.dlRequestStatus == 'Rejected' ||
                         t.peRequestStatus == 'Rejected';

    final isNotFFDispatch = t.dispatchType != "ff";

    return isRejected && isNotFFDispatch;
  }).toList();

  return filtered;
});
