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
  final List<Uint8List> transactionImages;
  final List<String> transactionImagesType;
  final bool isAccepted;

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
    required this.transactionImages,
    required this.transactionImagesType,
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
      transactionImages: transactionImages,
      transactionImagesType: transactionImagesType,
      isAccepted: isAccepted ?? this.isAccepted,
    );
  }
}
