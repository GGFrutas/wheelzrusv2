import 'dart:typed_data';

class TransactionSub {
  final String userId;
  final double amount;
  final DateTime? transactionDate;
  final String description;
  final String transactionId;
  final String booking;
  final String location;
  final String destination;
  final DateTime? eta;
  final DateTime? etd;
  final String status;
  final Uint8List signature;
  final List<Uint8List> transactionImages;

  const TransactionSub({
    required this.userId,
    required this.amount,
    this.transactionDate,
    required this.description,
    required this.transactionId,
    required this.booking,
    required this.location,
    required this.destination,
    this.eta,
    this.etd,
    required this.status,
    required this.signature,
    required this.transactionImages,
  });

  TransactionSub copyWith({
    String? userId,
    double? amount,
    DateTime? transactionDate,
    String? description,
    String? transactionId,
    String? booking,
    String? location,
    String? destination,
    DateTime? eta,
    DateTime? etd,
    String? status,
    Uint8List? signature,
    List<Uint8List>? transactionImages,
  }) {
    return TransactionSub(
      userId: userId ?? this.userId,
      amount: amount ?? this.amount,
      transactionDate: transactionDate ?? this.transactionDate,
      description: description ?? this.description,
      transactionId: transactionId ?? this.transactionId,
      booking: booking ?? this.booking,
      location: location ?? this.location,
      destination: destination ?? this.destination,
      eta: eta ?? this.eta,
      etd: etd ?? this.etd,
      status: status ?? this.status,
      signature: signature ?? this.signature,
      transactionImages: transactionImages ?? this.transactionImages,
    );
  }
}
