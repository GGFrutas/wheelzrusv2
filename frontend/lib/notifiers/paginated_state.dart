import 'package:frontend/models/transaction_model.dart';

class PaginatedTransactionState {
  final List<Transaction> transactions;
  final int currentPage;
  final bool isLoading;
  final bool hasMore;

  PaginatedTransactionState({
    required this.transactions,
    required this.currentPage,
    required this.isLoading,
    required this.hasMore,
  });

  factory PaginatedTransactionState.initial() {
    return PaginatedTransactionState(
      transactions: [],
      currentPage: 0,
      isLoading: false,
      hasMore: true,
    );
  }

  PaginatedTransactionState copyWith({
    List<Transaction>? transactions,
    bool? hasMore,
    int? currentPage,
    bool? isLoading,
  }) {
    return PaginatedTransactionState(
      transactions: transactions ?? this.transactions,
      currentPage: currentPage ?? this.currentPage,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}