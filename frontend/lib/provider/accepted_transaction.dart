import 'package:frontend/models/transaction_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/provider/transaction_list_notifier.dart';

class AcceptedTransactionNotifier extends StateNotifier<Set<Transaction>> {
  final Ref ref;

  AcceptedTransactionNotifier(this.ref) : super({});

  void addProduct(Transaction transaction) {
    if (!state.contains(transaction)) {
      final updatedTransaction =
          transaction.copyWith(status: 'Ongoing', isAccepted: true);
      state = {...state, updatedTransaction};

      // Update status in the main transaction list
      ref
          .read(transactionListProvider.notifier)
          .updateTransactionStatus(transaction.id, 'Ongoing');
    }
  }

  void removeProduct(Transaction transaction) {
    if (state.contains(transaction)) {
      state = state.where((p) => p.id != transaction.id).toSet();

      // Update status in the main transaction list
      ref
          .read(transactionListProvider.notifier)
          .updateTransactionStatus(transaction.id, 'Pending');
    }
  }
}

// Provider for AcceptedTransactionNotifier
final acceptedTransactionProvider =
    StateNotifierProvider<AcceptedTransactionNotifier, Set<Transaction>>((ref) {
  return AcceptedTransactionNotifier(ref);
});

final unacceptedTransactionsProvider = Provider<Set<Transaction>>((ref) {
  final acceptedTransactions = ref.watch(acceptedTransactionProvider);
  // Filter out transactions where isAccepted is true
  return acceptedTransactions
      .where((transaction) => transaction.isAccepted != true)
      .toSet();
});
