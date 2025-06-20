// ignore_for_file: avoid_print

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:frontend/models/transaction_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/notifiers/auth_notifier.dart';
import 'package:frontend/provider/base_url_provider.dart';
import 'package:frontend/provider/transaction_list_notifier.dart';
import 'package:frontend/theme/colors.dart';
import 'package:frontend/theme/text_styles.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';



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

Future<bool> updateStatus(String transactionId, String requestNumber, String newStatus,  WidgetRef ref, BuildContext context) async {
  // Call the method to update the status in the database
  final success = await updateTransactionStatusInDatabase(transactionId, requestNumber, newStatus, http.Client(), ref, context);

  if (success) {
     // Continue updating local state as shown earlier
    final updatedSet = state.map((transaction) {
      if (transaction.id.toString() == transactionId && 
          transaction.requestNumber.toString() == requestNumber) {
        return transaction.copyWith(requestStatus: newStatus);  // Update status
      }
      return transaction;
    }).toSet();

    state = updatedSet;

    final transactionListNotifier =
        ref.read(transactionListProvider.notifier);
    transactionListNotifier.updateTransactionStatus(
      int.parse(transactionId),
      newStatus,
    );
  }
  return success;
 
}

Future<bool> updateTransactionStatusInDatabase(
  String transactionId, String requestNumber, String newStatus, http.Client httpClient, WidgetRef ref, BuildContext context) async {

    final uid = ref.watch(authNotifierProvider).uid;
    final password = ref.watch(authNotifierProvider).password ?? '';
    final baseUrl = ref.watch(baseUrlProvider);
    final login = ref.watch(authNotifierProvider).login ?? '';

    if (uid == null || uid.isEmpty) {
      // print('❌ UID not found or empty!');
      throw Exception('UID is missing. Please log in.');
    }
    // print('✅ Retrieved UID: $uid'); // Debugging UID
  final url = Uri.parse('$baseUrl/api/odoo/$transactionId/status?uid=$uid'); // Adjust URL as needed

    final now = DateTime.now();
    final timestamp = DateFormat("yyyy-MM-dd HH:mm:ss.SSSSSS").format(now);


  final payload = jsonEncode({
    'requestNumber': requestNumber,
    'requestStatus': newStatus,  // Send the correct status
    'timestamp': timestamp, // Include the timestamp
  });

  try {
    final response = await httpClient.post(
      url,
      body: payload,
      headers: {'Content-Type': 'application/json','password': password, 'login': login},
    );

    return response.statusCode == 200;

    // if (response.statusCode == 200) {
    //   print('Status updated successfully in backend');
     
    //   showDialog(
    //     context: context,
    //     builder: (context) {
    //       return AlertDialog(
    //         title: Text(
    //           'Success!', 
    //           style: AppTextStyles.subtitle.copyWith(
    //             fontWeight: FontWeight.bold
    //           ),
    //           textAlign: TextAlign.center,
    //         ),
    //         content: Column(
    //           mainAxisSize: MainAxisSize.min,
    //           crossAxisAlignment: CrossAxisAlignment.center,
    //           children: [
    //             Text(
    //               'Booking has been accepted',
    //               style: AppTextStyles.body.copyWith(
    //                 color: Colors.black87
    //               ),
    //               textAlign: TextAlign.center,
    //             ),
    //             const SizedBox(height: 16),
    //             const Icon (
    //               Icons.check_circle,
    //               color: mainColor,
    //               size: 100
    //             )
    //           ],
    //         ),
    //         actions: [
    //           Padding(
    //             padding: const EdgeInsets.only(bottom: 12.0),
    //             child: Center(
    //               child: SizedBox(
    //                 width: 200,
    //                 child: ElevatedButton(
    //                 onPressed: () {
    //                   Navigator.of(context).pop();
    //                 }, 
    //                 style: ElevatedButton.styleFrom(
    //                   backgroundColor: mainColor,
    //                   padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
    //                   shape: RoundedRectangleBorder(
    //                     borderRadius: BorderRadius.circular(25),
    //                   ),
    //                 ),
    //                 child: Text(
    //                   "Continue",
    //                   style: AppTextStyles.body.copyWith(
    //                     color: Colors.white,
    //                   )
    //                 )
    //               ),
    //               )
    //             )
    //           )
    //         ],
    //       );
    //     }
    //   );
    // } else {
    //   showDialog(
    //     context: context,
    //     builder: (context) {
    //       return AlertDialog(
    //         title: Text(
    //           'Error!', 
    //           style: AppTextStyles.subtitle.copyWith(
    //             fontWeight: FontWeight.bold
    //           ),
    //           textAlign: TextAlign.center,
    //         ),
    //         content: Column(
    //           mainAxisSize: MainAxisSize.min,
    //           crossAxisAlignment: CrossAxisAlignment.center,
    //           children: [
    //             Text(
    //               'There seems to be an issue. Please try again.',
    //               style: AppTextStyles.body.copyWith(
    //                 color: Colors.black87
    //               ),
    //               textAlign: TextAlign.center,
    //             ),
    //             const SizedBox(height: 16),
    //             const Icon (
    //               Icons.highlight_off_rounded,
    //               color: Colors.red,
    //               size: 100
    //             )
    //           ],
    //         ),
    //         actions: [
    //           Padding(
    //             padding: const EdgeInsets.only(bottom: 12.0),
    //             child: Center(
    //               child: SizedBox(
    //                 width: 200,
    //                 child: ElevatedButton(
    //                 onPressed: () {
    //                   Navigator.of(context).pop();
    //                 }, 
    //                 style: ElevatedButton.styleFrom(
    //                   backgroundColor: Colors.red,
    //                   padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
    //                   shape: RoundedRectangleBorder(
    //                     borderRadius: BorderRadius.circular(25),
    //                   ),
    //                 ),
    //                 child: Text(
    //                   "Try Again",
    //                   style: AppTextStyles.body.copyWith(
    //                     color: Colors.white,
    //                   )
    //                 )
    //               ),
    //               )
    //             )
    //           )
    //         ],
    //       );
    //     }
    //   );
    // }
  } catch (e) {
    print('Error updating database: $e');
    return false;
    // showDialog(
    //   context: context,
    //   builder: (context) {
    //     return AlertDialog(
    //       title: Text(
    //         'Error!', 
    //         style: AppTextStyles.subtitle.copyWith(
    //           fontWeight: FontWeight.bold
    //         ),
    //         textAlign: TextAlign.center,
    //       ),
    //       content: Column(
    //         mainAxisSize: MainAxisSize.min,
    //         crossAxisAlignment: CrossAxisAlignment.center,
    //         children: [
    //           Text(
    //             'There seems to be an issue. Please try again.',
    //             style: AppTextStyles.body.copyWith(
    //               color: Colors.black87
    //             ),
    //             textAlign: TextAlign.center,
    //           ),
    //           const SizedBox(height: 16),
    //           const Icon (
    //             Icons.highlight_off_rounded,
    //             color: mainColor,
    //             size: 100
    //           )
    //         ],
    //       ),
    //       actions: [
    //         Padding(
    //           padding: const EdgeInsets.only(bottom: 12.0),
    //           child: Center(
    //             child: SizedBox(
    //               width: 200,
    //               child: ElevatedButton(
    //               onPressed: () {
    //                 Navigator.of(context).pop();
    //               }, 
    //               style: ElevatedButton.styleFrom(
    //                 backgroundColor: Colors.red,
    //                 padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
    //                 shape: RoundedRectangleBorder(
    //                   borderRadius: BorderRadius.circular(25),
    //                 ),
    //               ),
    //               child: Text(
    //                 "Try Again",
    //                 style: AppTextStyles.body.copyWith(
    //                   color: Colors.white,
    //                 )
    //               )
    //             ),
    //             )
    //           )
    //         )
    //       ],
    //     );
    //   }
    // );
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

// Future<void> updateTransactionStatusInDatabase(
//   String transactionId, String newStatus, http.Client httpClient, dynamic json) async {
//   // Convert the transactionId to an integer for backend processing
//   await updateTransactionStatusInDatabase(
//   transactionId.toString(), // Pass the ID as a string
//   'Accepted', // Set status to 'Accepted'
//   http.Client(),
//   json,
// );}