import 'dart:convert';

import 'package:frontend/models/transaction_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/provider/transaction_list_notifier.dart';
import 'package:http/http.dart' as http;


class AcceptedTransactionNotifier extends StateNotifier<Set<Transaction>> {
  AcceptedTransactionNotifier():super({});

  void addProduct(Transaction transaction) {
    // final uniqueKey = "$id-$requestNumber";
    if (!state.contains(transaction)){
      state = {...state,transaction};
    }
    // if (!state.contains(transaction)) {
    //   final updatedTransaction =
    //       transaction.copyWith(status: 'Ongoing', isAccepted: true);
    //   state = {...state, updatedTransaction};

    //   // Update status in the main transaction list
    //   ref
    //       .read(transactionListProvider.notifier)
    //       .updateTransactionStatus(transaction.id, 'Ongoing');
    // }
  }
  bool isAccepted(int id, String requestNumber){
    return state.any((transaction) {
      return transaction.id.toString() == id.toString() && transaction.requestNumber == requestNumber;
    });
  }

Future<void> updateStatus(String transactionId, String requestNumber, String newStatus) async {
  // Call the method to update the status in the database
  await updateTransactionStatusInDatabase(transactionId, requestNumber, newStatus, http.Client());

  // Continue updating local state as shown earlier
  final updatedSet = state.map((transaction) {
    if (transaction.id.toString() == transactionId && 
        transaction.requestNumber.toString() == requestNumber) {
      return transaction.copyWith(requestStatus: newStatus);  // Update status
    }
    return transaction;
  }).toSet();

  state = updatedSet;
}

Future<void> updateTransactionStatusInDatabase(
  String transactionId, String requestNumber, String newStatus, http.Client httpClient) async {
  final url = Uri.parse('http://10.0.2.2:8000/api/odoo/$transactionId/status'); // Adjust URL as needed

  final payload = jsonEncode({
    'requestNumber': requestNumber,
    'requestStatus': newStatus,  // Send the correct status
  });

  try {
    final response = await httpClient.post(
      url,
      body: payload,
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      print('Status updated successfully in backend');
    } else {
      print('Failed to update status: ${response.statusCode}, ${response.body}');
    }
  } catch (e) {
    print('Error updating database: $e');
  }
}


}

// Provider for AcceptedTransactionNotifier
final acceptedTransactionProvider =
    StateNotifierProvider<AcceptedTransactionNotifier, Set<Transaction>>((ref) {
  return AcceptedTransactionNotifier();
});

final unacceptedTransactionsProvider = Provider<Set<Transaction>>((ref) {
  final acceptedTransactions = ref.watch(acceptedTransactionProvider);
  final allTransactions = ref.watch(transactionListProvider);
  // Filter out transactions where isAccepted is true
  return allTransactions
      .where((transaction) {
        return !acceptedTransactions.contains(transaction);
      }).toSet();
});

Future<void> updateTransactionStatusInDatabase(
  String transactionId, String newStatus, http.Client httpClient, dynamic json) async {
  // Convert the transactionId to an integer for backend processing
  await updateTransactionStatusInDatabase(
  transactionId.toString(), // Pass the ID as a string
  'Accepted', // Set status to 'Accepted'
  http.Client(),
  json,
);}