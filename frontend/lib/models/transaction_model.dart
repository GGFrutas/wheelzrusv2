class Transaction {
  final int id;
  final String name;
  final String origin;
  final String destination;
  final String arrivalDate;
  final String deliveryDate;
  final String status;
  final bool isAccepted;
  final String dispatchType;
  final String? containerNumber;
  final String? freightBlNumber;
  final String? sealNumber;
  final String? bookingRefNo;
  final String? freightForwarderName;
  final String? freightBookingNumber;
  final String? originContainerYard;
  final int? requestNumber;
  final int? deRequestNumber;
  final int? plRequestNumber;
  final int? dlRequestNumber;
  final int? peRequestNumber;

  final String? requestStatus;
  final String? deRequestStatus;
  final String? plRequestStatus;
  final String? dlRequestStatus;
  final String? peRequestStatus;

  const Transaction({
    required this.id,
    required this.name,
    required this.origin,
    required this.destination,
    required this.arrivalDate,
    required this.deliveryDate,
    required this.status,
    required this.dispatchType,
    required this.containerNumber,
    required this.freightBlNumber,
    required this.sealNumber,
    required this.freightForwarderName,
    required this.bookingRefNo,
    required this.freightBookingNumber,
    required this.originContainerYard,
    required this.requestNumber,
    required this.deRequestNumber,
    required this.plRequestNumber,
    required this.dlRequestNumber,
    required this.peRequestNumber,
    required this.requestStatus,
    required this.deRequestStatus,
    required this.plRequestStatus,
    required this.dlRequestStatus,
    required this.peRequestStatus,
    this.isAccepted = false,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'],
      name: json['name'] ?? 'No Name Provided',  // Provide a default value
      origin: json['origin'] ?? 'Unknown Origin',  // Provide a default value
      destination: json['destination'] ?? 'Unknown Destination',  // Provide a default value
      arrivalDate: json['arrival_date'] ?? 'Unknown Arrival Date',  // Provide a default value
      deliveryDate: json['delivery_date'] ?? 'Unknown Delivery Date',  // Provide a default value
      status: json['status'] ?? 'Unknown Status',  // Provide a default value
      dispatchType: json['dispatch_type'] ?? 'Unknown Dispatch Type',
      containerNumber: json['container_number'],
      freightBlNumber: json['freight_bl_nummber'],
      sealNumber: json['seal_number'],
      bookingRefNo: json ['booking_reference_no'] ?? 'Unknown Booking Reference Number',
      freightForwarderName: json ['freight_forwarder_name'],
      freightBookingNumber: json ['freight_booking_number'],
      originContainerYard: json['origin_container_location'],
      requestNumber: json['de_request_no'],
      deRequestNumber: json['de_request_no'],
      plRequestNumber: json['pl_request_no'],
      dlRequestNumber: json['dl_request_no'],
      peRequestNumber: json['pe_request_no'],

      requestStatus: json['de_request_status'],
      deRequestStatus: json['de_request_status'],
      plRequestStatus: json['pl_request_status'],
      dlRequestStatus: json['dl_request_status'],
      peRequestStatus: json['pe_request_status'],
      isAccepted: false,  // set default or map from API
      
    );
  }

  Transaction copyWith({String? name, String? destination,int? requestNumber,String? origin,String? requestStatus,status, bool? isAccepted}) {
    return Transaction(
      id: id,
      name: name ?? this.name,
      origin:origin ?? this.origin,
      destination:destination ?? this.destination,
      arrivalDate: arrivalDate,
      deliveryDate: deliveryDate,
      status: status ?? this.status,
      dispatchType: dispatchType,
     containerNumber: containerNumber,
      isAccepted: isAccepted ?? this.isAccepted,
  
      freightBlNumber: freightBlNumber,
      sealNumber: sealNumber,
      bookingRefNo: bookingRefNo,
      freightForwarderName: freightForwarderName,
      freightBookingNumber:freightBookingNumber,
      originContainerYard:originContainerYard,
      requestNumber:requestNumber ?? this.requestNumber,
      deRequestNumber:deRequestNumber,
      plRequestNumber:plRequestNumber,
      dlRequestNumber:dlRequestNumber,
      peRequestNumber:peRequestNumber,
      requestStatus:requestStatus ?? this.requestStatus,
      deRequestStatus:deRequestStatus,
      plRequestStatus:plRequestStatus,
      dlRequestStatus:dlRequestStatus,
      peRequestStatus:peRequestStatus,
    );
  }
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Transaction &&
        other.id == id &&
        other.requestNumber == requestNumber;
  }

  @override
  int get hashCode => Object.hash(id, requestNumber);
}