import 'package:flutter/material.dart';
import 'package:frontend/models/transaction_model.dart';
import 'package:frontend/theme/colors.dart';
import 'booking_card.dart';

class BookingList extends StatelessWidget {
  final List<Transaction> transactions;
  final Future<void> Function(Transaction) onTap;

  const BookingList({
    super.key,
    required this.transactions,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (transactions.isEmpty) {
      return const Center(
        child: Text("No bookings available."),
      );
    }

    return ListView.builder(
      itemCount: transactions.length,
      itemBuilder: (context, index) {
        final item = transactions[index];
        return BookingCard(
          transaction: item,
          onTap: () => onTap(item),
          color: mainColor, // you can vary color based on status if needed
        );
      },
    );
  }
}
