// ignore_for_file: unused_import, deprecated_member_use

import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/notifiers/navigation_notifier.dart';
import 'package:frontend/notifiers/transaction_notifier.dart';
import 'package:frontend/provider/accepted_transaction.dart' as accepted_transaction;
import 'package:frontend/provider/base_url_provider.dart';
import 'package:frontend/provider/reject_provider.dart';
import 'package:frontend/provider/transaction_list_notifier.dart';
import 'package:frontend/user/map_api.dart';
import 'package:http/http.dart' as http;
import 'package:frontend/models/transaction_model.dart';
import 'package:frontend/notifiers/auth_notifier.dart';



// part 'transaction_provider.g.dart';

// Fetch data from the API
Future<List<Transaction>> fetchTransactions(FutureProviderRef<List<Transaction>> ref, {required uid}) async {
 
   
  final password = ref.watch(authNotifierProvider).password ?? '';
  final baseUrl = ref.watch(baseUrlProvider);
  final login = ref.watch(authNotifierProvider).login ?? '';


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
      'login': login
    },
  );


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
          print("🔍 Type of 'transactions': ${transactions.runtimeType}");

          if (transactions is Map<String, dynamic>) {
            final transactionsList = transactions.values.toList();
            print("✅ Parsed transactions count: ${transactionsList.length}");
            return transactionsList.map((json) => Transaction.fromJson(json)).toList();
          } 
          else if (transactions is List) {
            print("✅ Transactions is a List with ${transactions.length} items.");
            return transactions.map((json) => Transaction.fromJson(json)).toList();
          } 
          
        } 
      } 
    }
  }
  throw Exception("Unable to fetch data.");
}

// Future<Transaction> fetchTransactionDetails(FutureProviderRef<List<Transaction>> ref, {required uid, required bookingId}) async {
final transactionDetailProvider = FutureProvider.family<Transaction, Map<String, dynamic>>((ref, args) async {
  final password = ref.watch(authNotifierProvider).password ?? '';
  final baseUrl = ref.watch(baseUrlProvider);
  final login = ref.watch(authNotifierProvider).login ?? '';

  final uid = args['uid'];
  final bookingId = args['bookingId'];

  print('📤 Calling API with UID: $uid, BookingID: $bookingId');
  print('🔐 Headers -> login: $login | password: $password');
  print('🌐 URL: $baseUrl/api/odoo/booking_details?uid=$uid&booking_id=$bookingId');

  final response = await http.get(
    Uri.parse('$baseUrl/api/odoo/booking_details?uid=$uid&booking_id=$bookingId'),
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'password': password,
      'login': login
    },
  );

  print('📥 Response status: ${response.statusCode}');
  print('📥 Response body: ${response.body}');

  if (response.statusCode == 200) {
    final decoded = json.decode(response.body);
    if (decoded is Map && decoded.containsKey("data")) {
  final data = decoded["data"] as Map<String, dynamic>;
  final list = data["transactions"] as List<dynamic>?;

  if (list != null && list.isNotEmpty) {
    final transactionJson = list.first as Map<String, dynamic>;
    return Transaction.fromJson(transactionJson);
  } else {
    throw Exception('No transaction found in response');
  }
} else {
  throw Exception("Invalid response format: ${response.body}");
}

  } else {
    throw Exception("Failed to fetch transaction details: ${response.statusCode}");
  }
});


// Future<Transaction> fetchTransactionStatus(WidgetRef ref, String baseUrl, String transactionId) async {
//   try {
//     // print("Fetching Transactions status for ID : $transactionId");
//     final uid = ref.watch(authNotifierProvider).uid;
//     final password = ref.watch(authNotifierProvider).password ?? '';
//     final login = ref.watch(authNotifierProvider).login ?? '';
    
//     if (uid == null || uid.isEmpty) {
//       throw Exception('UID is missing. Please log in.');
//     }

//     final response = await http.get(
//       Uri.parse('$baseUrl/api/odoo/booking?uid=$uid&transaction_id=$transactionId'),
//       headers: {
//         'Content-Type': 'application/json',
//         'Accept': 'application/json',
//         'password': password,
//         'login': login
//       },
//     );

//     if (response.statusCode == 200) {
//       final decodeData = json.decode(response.body);
//       if (decodeData is Map && decodeData.containsKey("transaction")) {
//         return Transaction.fromJson(decodeData["transaction"]);
//       }
//     }
//   } catch (e) {
//     throw Exception("Error fetching transaction status: $e");
//   }
//   throw Exception("Unexpected error: Transaction not found. here?");
// }
Future<Transaction> fetchTransactionStatus(WidgetRef ref, String baseUrl, String transactionId) async {
  try {
    final uid = ref.watch(authNotifierProvider).uid;
    final password = ref.watch(authNotifierProvider).password ?? '';
    final login = ref.watch(authNotifierProvider).login ?? '';

    if (uid == null || uid.isEmpty) {
      throw Exception('UID is missing. Please log in.');
    }

    final url = '$baseUrl/api/odoo/booking?uid=$uid&transaction_id=$transactionId';
    print('🔸 Fetching: $url');
    print('🔸 Transaction ID: $transactionId');

    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'password': password,
        'login': login
      },
    );

    if (response.statusCode == 200) {
      final decodeData = json.decode(response.body);
   

      if (decodeData is Map &&
    decodeData.containsKey("data") &&
    decodeData["data"].containsKey("transactions") &&
    decodeData["data"]["transactions"] is List &&
    decodeData["data"]["transactions"].isNotEmpty) {

  final firstTransaction = decodeData["data"]["transactions"][0];
  return Transaction.fromJson(firstTransaction);
} else {
  throw Exception("API did not return a valid 'transactions' list.");
}

    } else {
      throw Exception("Failed to fetch transaction. Status code: ${response.statusCode}");
    }
  } catch (e) {
    throw Exception("Error fetching transaction status: $e");
  }
}


// // Define a Riverpod provider to fetch transactions asynchronously
// @riverpod
// Future<List<Transaction>> booking(BookingRef ref) async {
//   return fetchTransactions();
// }
// FutureProvider to manage the fetching of transactions
final bookingProvider = FutureProvider<List<Transaction>>((ref) async {
  final authState = ref.watch(authNotifierProvider); // Get full auth state
  // print('🟡 Auth State: $authState'); // Debugging
  
  final uid = authState.uid;
  
  if (uid == null || uid.isEmpty) {
    // print('❌ UID not found inside authNotifierProvider!');
    throw Exception('UID not found. Please log in.');
  }

  // print('✅ Retrieved UID in bookingProvider: $uid'); // Debugging

  return fetchTransactions(ref, uid: uid); // ✅ Pass uid properly
});

final filteredItemsProvider = FutureProvider<List<Transaction>>((ref) async {
  final transactions = await ref.watch(bookingProvider.future);
  // final authPartnerId = ref.watch(authNotifierProvider).partnerId;

  // print("🔍 Total transactions before filtering: ${transactions.length}");

  final filtered = transactions.where((t) {
    
    final isAllPending =  t.deRequestStatus == 'Pending' || t.deRequestStatus == 'Accepted' ||
                          t.deRequestStatus == 'Rejected' || t.deRequestStatus == 'Completed' || t.deRequestStatus == 'Ongoing' ||
                          // t.deTruckDriverName == authPartnerId || 

                          t.plRequestStatus == 'Pending' || t.plRequestStatus == 'Accepted' ||
                          t.plRequestStatus == 'Rejected' || t.plRequestStatus == 'Completed' || t.plRequestStatus == 'Ongoing' ||
                          // t.plTruckDriverName == authPartnerId ||

                          t.dlRequestStatus == 'Pending' || t.dlRequestStatus == 'Accepted' ||
                          t.dlRequestStatus == 'Rejected' || t.dlRequestStatus == 'Completed' || t.dlRequestStatus == 'Ongoing' ||
                          // t.dlTruckDriverName == authPartnerId ||

                          t.peRequestStatus == 'Pending' || t.peRequestStatus == 'Accepted' ||
                          t.peRequestStatus == 'Rejected' || t.peRequestStatus == 'Completed'  || t.peRequestStatus == 'Ongoing';
                          // t.peTruckDriverName == authPartnerId;
    // final isAllPending = [
    //   if(t.deTruckDriverName == authPartnerId) "de",
    //   if(t.plTruckDriverName == authPartnerId) "pl",
    //   if(t.dlTruckDriverName == authPartnerId) "dl",
    //   if(t.peTruckDriverName == authPartnerId) "pe",
    // ];
    // if(isAllPending.isNotEmpty){
    //   print("Assigned to: ${isAllPending.first} for ${t.id}");
    //   return true;
    // }


    final isNotFFDispatch = t.dispatchType != "ff";

    return isAllPending && isNotFFDispatch;
  }).toList();

  return filtered;
});

