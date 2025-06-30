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
Future<List<Transaction>> fetchHistory(FutureProviderRef<List<Transaction>> ref, {required uid}) async {
 
   
  final password = ref.watch(authNotifierProvider).password ?? '';
  final baseUrl = ref.watch(baseUrlProvider);
  final login = ref.watch(authNotifierProvider).login ?? '';


  if (uid == null || uid.isEmpty) {
    throw Exception('UID is missing. Please log in.');
  }
  // print('✅ Retrieved UID: $uid'); // Debugging UID

  final response = await http.get(
    Uri.parse('$baseUrl/api/odoo/history?uid=$uid'),
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
          print("🔍 'transactions' found: ${data['transactions']}"); // Debugging
          
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



final historyProvider = FutureProvider<List<Transaction>>((ref) async {
  final authState = ref.watch(authNotifierProvider); // Get full auth state
  // print('🟡 Auth State: $authState'); // Debugging
  
  final uid = authState.uid;
  
  if (uid == null || uid.isEmpty) {
    // print('❌ UID not found inside authNotifierProvider!');
    throw Exception('UID not found. Please log in.');
  }

  // print('✅ Retrieved UID in historyProvider: $uid'); // Debugging

  return fetchHistory(ref, uid: uid); // ✅ Pass uid properly
});

final filteredHistory = FutureProvider<List<Transaction>>((ref) async {
  final transactions = await ref.watch(historyProvider.future);
  // final authPartnerId = ref.watch(authNotifierProvider).partnerId;

  // print("🔍 Total transactions before filtering: ${transactions.length}");

  final filtered = transactions.where((t) {
    
    final isHistory = 
                          t.deRequestStatus == 'Rejected' || t.deRequestStatus == 'Completed' || 
                          // t.deTruckDriverName == authPartnerId || 

                      
                          t.plRequestStatus == 'Rejected' || t.plRequestStatus == 'Completed' ||
                          // t.plTruckDriverName == authPartnerId ||

                     
                          t.dlRequestStatus == 'Rejected' || t.dlRequestStatus == 'Completed' || 
                          // t.dlTruckDriverName == authPartnerId ||

                         
                          t.peRequestStatus == 'Rejected' || t.peRequestStatus == 'Completed' ;
                         

    final isNotFFDispatch = t.dispatchType != "ff";

    return isHistory && isNotFFDispatch;
  }).toList();

  return filtered;
});

