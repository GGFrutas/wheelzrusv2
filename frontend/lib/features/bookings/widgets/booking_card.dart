import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:frontend/models/transaction_model.dart';
import 'package:frontend/theme/text_styles.dart';
import 'package:intl/intl.dart';

class BookingCard extends StatelessWidget {
  final Transaction transaction;
  final VoidCallback onTap;
  final Color color;

  const BookingCard({
    super.key,
    required this.transaction,
    required this.onTap,
    required this.color
  });

   String formatDateTime(String? dateString) {
    if (dateString == null || dateString.isEmpty) return "N/A"; // Handle null values
    
    try {
      DateTime dateTime = DateTime.parse("${dateString}Z").toLocal();// Convert string to DateTime
      return DateFormat('d MMMM, yyyy').format(dateTime); // Format date-time
    } catch (e) {
      return "Invalid Date"; // Handle errors gracefully
    }
  } 

   @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(transaction.name ?? 'No Name',
                  style: AppTextStyles.body.copyWith(
                      color: Colors.white, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              _row("Bkg Ref.: ", transaction.freightBookingNumber),
              _row("Request No.: ", transaction.requestNumber),
              _row("Date Assigned: ", formatDateTime(transaction.assignedDate)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(String label, String? value) {
    return Row(
      children: [
        Text(label,
            style: AppTextStyles.caption
                .copyWith(fontWeight: FontWeight.bold, color: Colors.white)),
        Flexible(
          child: Text(value ?? "N/A",
              style: AppTextStyles.caption.copyWith(color: Colors.white)),
        )
      ],
    );
  }
}