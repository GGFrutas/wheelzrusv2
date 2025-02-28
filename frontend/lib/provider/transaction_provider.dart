import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:frontend/models/transaction_model.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

// part 'transaction_provider.g.dart';

// Fetch data from the API
Future<List<Transaction>> fetchTransactions() async {
  try {
    final response = await http.get(Uri.parse('http://10.0.2.2:8000/api/odoo/booking'));

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((json) => Transaction.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load transactions: ${response.statusCode}');
    }
  } catch (e) {
    throw Exception('Error fetching transactions: $e');
  }
}
// // Define a Riverpod provider to fetch transactions asynchronously
// @riverpod
// Future<List<Transaction>> booking(BookingRef ref) async {
//   return fetchTransactions();
// }
// FutureProvider to manage the fetching of transactions
final bookingProvider = FutureProvider<List<Transaction>>((ref) async {
  return fetchTransactions();
});

final filteredItemsProvider = FutureProvider<List<Transaction>>((ref) async {
  final transactions = await ref.watch(bookingProvider.future);
  return transactions.where((t) {
    final isAllPending = t.deRequestStatus == 'Pending' ||
                         t.plRequestStatus == 'Pending' ||
                         t.dlRequestStatus == 'Pending' &&
                         t.peRequestStatus == 'Pending';

    final isNotFFDispatch = t.dispatchType != "ff";
   
    // return isNotFFDispatch;
    return isAllPending && isNotFFDispatch;
  }).toList();
});
