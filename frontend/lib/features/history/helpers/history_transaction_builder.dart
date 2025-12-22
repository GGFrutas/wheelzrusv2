import 'package:frontend/models/transaction_model.dart';
import 'package:frontend/util/transaction_utils.dart';

class HistoryTransactionBuilder {
  static List<Transaction> build({
    required List<Transaction> transactionList,
    required String driverId,
    required String currentDriverName,
  }) {
    //  / Step 1: Expand all normal transactions for this driver
    final expandedTransactions = TransactionUtils.expandTransactions(
      transactionList, // your normal transactions list
      driverId,
    );

    // ✅ STEP 2: Collect ALL reassigned items from every transaction
    final allReassignments = transactionList
        .where((t) => t.reassigned != null && t.reassigned!.isNotEmpty)
        .expand((t) => t.reassigned!)
        .toList();

    // ✅ STEP 3: Expand them for the current driver
    final reassignedTransactions = TransactionUtils.expandReassignments(
      allReassignments,
      driverId,
      currentDriverName,
      transactionList, // pass all transactions for parent lookup
    );


    // Step 3: Merge normal + reassigned
    final allTransactions = [
      ...expandedTransactions,
      ...reassignedTransactions
    ];

     final deduped = <Transaction>[];
    for (final tx in allTransactions) {
      final exists = deduped.any(
        (t) => t.id == tx.id && t.requestNumber == tx.requestNumber,
      );
      if (!exists) {
        deduped.add(tx);
      }
    }
    return deduped;
  }
}