// ignore_for_file: use_build_context_synchronously

import 'dart:convert';
import 'dart:io';
import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/models/transaction_submit.dart';
import 'package:frontend/services/transaction_service.dart';
import 'dart:typed_data';

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
          transactionDate: null,
          description: '',
          transactionId: '',
          booking: '',
          location: '',
          destination: '',
          eta: null,
          etd: null,
          status: '',
          signature: Uint8List(0), // Empty Uint8List as default
          transactionImages: const [], // Initialize empty list
        ));

  Future<void> submitTransaction({
    required int userId,
    required double amount,
    DateTime? transactionDate,
    required String description,
    required String transactionId,
    required String booking,
    required String location,
    required String destination,
    DateTime? eta,
    DateTime? etd,
    required String status,
    required Uint8List signature,
    required List<File?> transactionImages,
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
          signature,
          transactionImages);

      // ignore: unused_local_variable
      final data =
          response is String ? jsonDecode(response as String) : response;

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Transaction submitted successfully!'),
        backgroundColor: Colors.green,
      ));
      Navigator.pop(context);
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
