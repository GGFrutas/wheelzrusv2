import 'package:frontend/models/transaction_model.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'transaction_provider.g.dart';

const List<Transaction> allTransactions = [
  Transaction(
      id: 1,
      amount: 0,
      booking: 'BKCEB2200123',
      location: 'Cebu City',
      destination: 'Mandaue',
      eta: '2022-01-15 03:32:00.000',
      etd: '2022-01-15 03:32:00.000',
      status: 'Pending'),
  Transaction(
      id: 2,
      amount: 0,
      booking: 'BKCEB2202222',
      location: 'Cebu City',
      destination: 'Talisay City',
      eta: '2022-01-15 03:32:00.000',
      etd: '2022-01-15 03:32:00.000',
      status: 'Pending'),
  Transaction(
      id: 3,
      amount: 0,
      booking: 'BKCEB2201233',
      location: 'Cebu City',
      destination: 'Mandaue',
      eta: '2022-01-15 03:32:00.000',
      etd: '2022-01-15 03:32:00.000',
      status: 'Pending'),
  Transaction(
      id: 4,
      amount: 0,
      booking: 'BKCEB2206588',
      location: 'Cebu City',
      destination: 'Carcar City',
      eta: '2022-01-15 03:32:00.000',
      etd: '2022-01-15 03:32:00.000',
      status: 'Pending'),
  Transaction(
      id: 5,
      amount: 0,
      booking: 'BKCEB2209998',
      location: 'Cebu City',
      destination: 'Danao City',
      eta: '2022-01-15 03:32:00.000',
      etd: '2022-01-15 03:32:00.000',
      status: 'Pending'),
  Transaction(
      id: 6,
      amount: 0,
      booking: 'BKCEB22002217',
      location: 'Cebu City',
      destination: 'Toledo City',
      eta: '2022-01-15 03:32:00.000',
      etd: '2022-01-15 03:32:00.000',
      status: 'Pending')
];

final pendingTransactionProvider = Provider((ref) {
  return allTransactions.where((q) => q.status == 'Pending').toList();
});

@riverpod
List<Transaction> booking(ref) {
  return allTransactions;
}
