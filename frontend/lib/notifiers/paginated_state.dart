import 'package:frontend/models/transaction_model.dart';

class PaginatedTransactionState {
  final List<Transaction> transactions;
  final int currentPage;
  final bool isLoading;
  final bool hasMore;
  final String? errorMessage;

  PaginatedTransactionState({
    required this.transactions,
    required this.currentPage,
    required this.isLoading,
    required this.hasMore,
    this.errorMessage,
  });

  factory PaginatedTransactionState.initial() {
    return PaginatedTransactionState(
      transactions: [],
      currentPage: 0,
      isLoading: false,
      hasMore: true,
      errorMessage: null,
    );
  }

  PaginatedTransactionState copyWith({
    List<Transaction>? transactions,
    bool? hasMore,
    int? currentPage,
    bool? isLoading,
    String? errorMessage,
  }) {
    return PaginatedTransactionState(
      transactions: transactions ?? this.transactions,
      currentPage: currentPage ?? this.currentPage,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      errorMessage: errorMessage,
    );
  }
}