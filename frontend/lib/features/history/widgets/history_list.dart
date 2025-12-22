import "package:flutter/material.dart";
import "package:frontend/features/history/helpers/history_helpers.dart";
import "package:frontend/features/history/widgets/history_card.dart";
import "package:frontend/models/transaction_model.dart";
import "package:frontend/theme/text_styles.dart";


class HistoryList extends StatelessWidget {
  final List<Transaction> transactions;
  final String currentDriverId;
  final String currentDriverName;
  final HistoryHelpers helpers;
  final void Function(Transaction) onTap;

  const HistoryList({
    super.key,
    required this.transactions,
    required this.currentDriverId,
    required this.currentDriverName,
    required this.helpers,
    required this.onTap
  });

  @override
  Widget build(BuildContext context) {
    if(transactions.isEmpty) {
      return Center(
        child: Text(
          'No history transactions yet.',
          style: AppTextStyles.subtitle,
          textAlign: TextAlign.center,
        ),
      );
    }
    return ListView.builder(
      itemCount: transactions.length,
      itemBuilder:  (context, index) {
        final tx = transactions[index];
        final statusLabel = helpers.getStatusLabel(tx, currentDriverId, currentDriverName);
        final datetime = helpers.getCompletedTransactionDatetime(tx);

        return HistoryCard(
          transaction: tx, 
          statusLabel: statusLabel, 
          statusColor: helpers.getStatusColor(statusLabel), 
          date: datetime['date']!, 
          onTap: () => onTap(tx), 
          time: datetime['time']!,
        );
      }
    );
  }
}
