class TransactionSub {
  final String userId;
  final double amount;
  final DateTime transactionDate;
  final String description;
  final String transactionId;
  final String booking;
  final String location;
  final String destination;
  final DateTime eta;
  final DateTime etd;
  final String status;
  final bool isAccepted;

  const TransactionSub({
    required this.userId,
    required this.amount,
    required this.transactionDate,
    required this.description,
    required this.transactionId,
    required this.booking,
    required this.location,
    required this.destination,
    required this.eta,
    required this.etd,
    required this.status,
    this.isAccepted = false,
  });

  TransactionSub copyWith({String? status, bool? isAccepted}) {
    return TransactionSub(
      userId: userId,
      amount: amount,
      transactionDate: transactionDate,
      description: description,
      transactionId: transactionId,
      booking: booking,
      location: location,
      destination: destination,
      eta: eta,
      etd: etd,
      status: status ?? this.status,
      isAccepted: isAccepted ?? this.isAccepted,
    );
  }
}
