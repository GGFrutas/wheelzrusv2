class Transaction {
  final int id;
  final double amount;
  final String booking;
  final String location;
  final String destination;
  final String eta;
  final String etd;
  final String status;
  final bool isAccepted;

  const Transaction(
      {required this.id,
      required this.amount,
      required this.booking,
      required this.location,
      required this.destination,
      required this.eta,
      required this.etd,
      required this.status,
      this.isAccepted = false});

  Transaction copyWith({String? status, bool? isAccepted}) {
    return Transaction(
      id: id,
      amount: amount,
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
