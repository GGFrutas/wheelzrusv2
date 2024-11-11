import 'dart:convert';
import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/models/transaction_submit.dart';
import 'package:frontend/services/transaction_service.dart';

final transactionNotifierProvider =
    StateNotifierProvider<TransactionNotifier, TransactionSub>(
  (ref) {
    final transactionService = ref.watch(transactionServiceProvider);
    return TransactionNotifier(transactionService);
  },
);

class TransactionNotifier extends StateNotifier<TransactionSub> {
  final TransactionService _transactionService;

  TransactionNotifier(this._transactionService)
      : super(TransactionSub(
          userId: '',
          amount: 0.0,
          transactionDate: DateTime.now(),
          description: '',
          transactionId: '',
          booking: '',
          location: '',
          destination: '',
          eta: DateTime.now(),
          etd: DateTime.now(),
          status: '',
        ));

  Future<void> submitTransaction({
    required int userId,
    required double amount,
    required DateTime transactionDate,
    required String description,
    required String transactionId,
    required String booking,
    required String location,
    required String destination,
    required DateTime eta,
    required DateTime etd,
    required String status,
    required BuildContext context,
  }) async {
    try {
      final response = await _transactionService.submit(
        userId,
        amount,
        transactionDate,
        description,
        transactionId,
        booking,
        location,
        destination,
        eta,
        etd,
        status,
      );

      final data =
          response is String ? jsonDecode(response as String) : response;

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Transaction submitted successfully!'),
        backgroundColor: Colors.green,
      ));
    } catch (e) {
      print("Error: $e");
      if (context.mounted) {
        const snackBar = SnackBar(
          elevation: 0,
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.transparent,
          content: AwesomeSnackbarContent(
            title: 'Transaction Error!',
            message: 'Failed to submit transaction. Please try again.',
            contentType: ContentType.failure,
          ),
        );
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(snackBar);
      }
    }
  }
}
