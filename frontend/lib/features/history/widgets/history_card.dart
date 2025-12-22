import 'package:flutter/material.dart';
import 'package:frontend/models/transaction_model.dart';
import 'package:frontend/theme/colors.dart';
import 'package:frontend/theme/text_styles.dart';


class HistoryCard extends StatelessWidget {
  final Transaction transaction;
  final String statusLabel;
  final String date;
  final String time;
  final Color statusColor;
  final VoidCallback onTap;

  const HistoryCard ({
    super.key,
    required this.transaction,
    required this.statusLabel,
    required this.statusColor,
    required this.date,
    required this.onTap,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container (
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.all(6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _row(
              "Dispatch No.: ",
              transaction.bookingRefNo,
              labelStyle: AppTextStyles.caption.copyWith(
                color: darkerBgColor
              ),
              valueStyle:AppTextStyles.caption.copyWith(
                color: mainColor, 
                fontWeight: FontWeight.bold
              ),
              trailing: _statusChip(),
              
            ),
            _row(
              "Request ID: ", 
              transaction.requestNumber?.toString(),
              labelStyle: AppTextStyles.caption.copyWith(
                color: darkerBgColor
              ),
              valueStyle:AppTextStyles.caption.copyWith(
                color: mainColor, 
                fontWeight: FontWeight.bold
              ),
              trailingText: date,
              
              trailingTextStyle: AppTextStyles.caption.copyWith(
                color: mainColor,
                fontWeight: FontWeight.bold
              )
            ),
            _row(
              "View Details → ", 
              null, 
              trailingText: time,
              labelStyle: AppTextStyles.caption.copyWith(
                color: mainColor, 
                fontWeight: FontWeight.bold
              ),
              trailingTextStyle: AppTextStyles.caption.copyWith(
                color: mainColor,
                fontWeight: FontWeight.bold
              )
            ),
            
          ],
        ),
      ),
    );
  }

  Widget _statusChip() {
    return Container (
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: statusColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        statusLabel,
        style: AppTextStyles.caption.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.bold
        ),
      ),
    );
  }

  Widget _row(String label, String? value, {Widget? trailing, String? trailingText, TextStyle? labelStyle, TextStyle? valueStyle, TextStyle? trailingTextStyle}) {
    return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (label.isNotEmpty)
          Text(
            label,
            style: labelStyle ??
                const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
          ),

        if (value != null)
          Text(
            value,
            style: valueStyle ??
                const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
          ),

        const Spacer(),

        if (trailing != null) trailing,

        if (trailingText != null)
          Text(
            trailingText,
            style: trailingTextStyle ??
                const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
          ),
      ],
    ),
  );
  }
}