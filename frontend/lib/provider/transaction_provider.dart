// ignore_for_file: unused_import, deprecated_member_use, depend_on_referenced_packages

import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/models/week_query.dart';
import 'package:frontend/notifiers/navigation_notifier.dart';
import 'package:frontend/notifiers/paginated_notifier.dart';
import 'package:frontend/notifiers/paginated_state.dart';
import 'package:frontend/notifiers/transaction_notifier.dart';
import 'package:frontend/provider/accepted_transaction.dart' as accepted_transaction;
import 'package:frontend/provider/base_url_provider.dart';
import 'package:frontend/provider/reject_provider.dart';
import 'package:frontend/provider/transaction_list_notifier.dart';
import 'package:frontend/user/map_api.dart';
import 'package:http/http.dart' as http;
import 'package:frontend/models/transaction_model.dart';
import 'package:frontend/notifiers/auth_notifier.dart';
import 'package:http/http.dart';




Future<List<Transaction>> fetchFilteredTransactions( {
  required FutureProviderRef<List<Transaction>> ref,
  required String endpoint, required Map<String, dynamic> queryParams,
}) async {
  final baseUrl = ref.watch(baseUrlProvider);
  final auth = ref.watch(authNotifierProvider);
  final uid = auth.uid;
  final password = auth.password ?? '';
  final login = auth.login ?? '';

  if (uid == null || uid.isEmpty) {
    throw Exception('UID is missing. Please log in.');
  }

  final url = '$baseUrl/api/odoo/booking/$endpoint?uid=$uid';
  // print("URL: $url" );



  try {
    final response = await http.get(Uri.parse(url), headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'password': password,
      'login': login,
    });
    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      final transactions = decoded['data']['transactions'] as List;
      return transactions.map((json) => Transaction.fromJson(json)).toList();
    }

    throw Exception("An error occured in the system.");
  } on SocketException {
    throw Exception("Please check your internet connection.");
  } on ClientException {
    throw Exception("Connection lost. Please try again.");
  }
}

// Future<Transaction> fetchTransactionDetails(FutureProviderRef<List<Transaction>> ref, {required uid, required bookingId}) async {
final transactionDetailProvider = FutureProvider.family<Transaction, Map<String, dynamic>>((ref, args) async {
  final password = ref.watch(authNotifierProvider).password ?? '';
  final baseUrl = ref.watch(baseUrlProvider);
  final login = ref.watch(authNotifierProvider).login ?? '';

  final uid = args['uid'];
  final bookingId = args['bookingId'];

  // print('📤 Calling API with UID: $uid, BookingID: $bookingId');
  // print('🔐 Headers -> login: $login | password: $password');
  // print('🌐 URL: $baseUrl/api/odoo/booking_details?uid=$uid&booking_id=$bookingId');

  final response = await http.get(
    Uri.parse('$baseUrl/api/odoo/booking_details?uid=$uid&booking_id=$bookingId'),
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'password': password,
      'login': login
    },
  );


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


Future<Transaction> fetchTransactionStatus(WidgetRef ref, String baseUrl, String transactionId) async {
  try {
    final uid = ref.watch(authNotifierProvider).uid;
    final password = ref.watch(authNotifierProvider).password ?? '';
    final login = ref.watch(authNotifierProvider).login ?? '';

    if (uid == null || uid.isEmpty) {
      throw Exception('UID is missing. Please log in.');
    }

    final url = '$baseUrl/api/odoo/booking?uid=$uid&transaction_id=$transactionId';
   
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

  return fetchFilteredTransactions(ref: ref, endpoint: 'today', queryParams: {}); // Provide required named parameters
});

final filteredItemsProvider = FutureProvider<List<Transaction>>((ref) async {
  
   final transactions = await fetchFilteredTransactions(ref: ref, endpoint: 'today', queryParams: {});
  // final filtered = transactions
  //     .where((tx) => tx.dispatchType.toLowerCase() != 'ff')
  //     .toList();
  ref.read(transactionListProvider.notifier).loadTransactions(transactions);
  return transactions;
});

final filteredItemsProviderForTransactionScreen = FutureProvider<List<Transaction>>((ref) async {
  
  return fetchFilteredTransactions(ref: ref, endpoint: 'ongoing', queryParams: {});
});

final filteredItemsProviderForHistoryScreen = FutureProvider<List<Transaction>>((ref) async {
 
  return fetchFilteredTransactions(ref: ref, endpoint: 'history', queryParams: {});
});

// final allTransactionProvider = FutureProvider.family<List<Transaction>, WeekQuery>((ref, query) async {
//   return fetchFilteredTransactions(
// ref: ref, endpoint: 'all-bookings',  queryParams: {
//       'start': query.start.toIso8601String(),
//       'end': query.end.toIso8601String(),
//       'page': query.page.toString(),
//       'limit': query.limit.toString(),
//     },);
// });

// final allTransactionProvider = FutureProvider<List<Transaction>>((ref) async {
  

//   return fetchFilteredTransactions(ref: ref, endpoint: 'all-bookings', queryParams: {});
// });

final allHistoryProvider = FutureProvider<List<Transaction>>((ref) async {
  

  return fetchFilteredTransactions(ref: ref, endpoint: 'all-history', queryParams: {});
});


final paginatedTransactionProvider = StateNotifierProvider.family<PaginatedNotifier, PaginatedTransactionState, String>((ref, endpoint) {
  return PaginatedNotifier(ref, endpoint);
});

final allTransactionProvider = FutureProvider<List<Transaction>>((ref) async {
  final transactions = await fetchFilteredTransactions(ref: ref, endpoint: 'all-bookings', queryParams: {});
  // final filtered = transactions
  //     .where((tx) => tx.dispatchType.toLowerCase() != 'ff')
  //     .toList();
  ref.read(transactionListProvider.notifier).loadTransactions(transactions);
  return transactions;
});

final allTransactionFilteredProvider = FutureProvider<List<Transaction>>((ref) async {
  final transactions = await ref.watch(allTransactionProvider.future);

  final filtered = transactions
      .where((tx) => tx.dispatchType.toLowerCase() != 'ff')
      .toList();

  return filtered;
});


final relatedFFProvider = Provider.family<Transaction?, String>((ref, bookingNumber) {
  final allTransactions = ref.watch(transactionListProvider);
  return allTransactions.cast<Transaction?>().firstWhere(
    (tx) =>
      tx?.bookingRefNumber?.trim() == bookingNumber.trim() &&
      tx?.dispatchType?.toLowerCase().trim() == 'ff',
    orElse: () => null,
  );
});


final combinedTransactionProvider = FutureProvider<List<Transaction>>((ref) async {
  final todayTx = await ref.refresh(filteredItemsProvider.future);
  final allTx = await ref.refresh(allTransactionProvider.future);

  // Combine and deduplicate by bookingRefNumber
  final combined = [
    ...todayTx,
    ...allTx.where((tx) =>
      !todayTx.any((t) => t.bookingRefNumber == tx.bookingRefNumber))
  ];

  ref.read(transactionListProvider.notifier).loadTransactions(combined);
  return combined;
});


