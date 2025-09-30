import 'package:frontend/models/transaction_model.dart';

class TransactionView {
  final Transaction transaction;
  final Map<String, dynamic> rawJson;

  TransactionView({
    required this.transaction,
    required this.rawJson,
  });
}

