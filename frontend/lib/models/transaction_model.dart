class Transaction {
  final int id;
  final String name;
  final String origin;
  final String destination;
  final String arrivalDate;
  final String deliveryDate;
  final String pickupDate;
  final String departureDate;
  final String status;
  final bool isAccepted;
  final String dispatchType;
  final String? containerNumber;
  final String? freightBlNumber;
  final String? sealNumber;
  final String? bookingRefNo;
  final String? transportForwarderName;
  final String? freightBookingNumber;
  final String? originContainerYard;
  final String? requestNumber;
  final String? deRequestNumber;
  final String? plRequestNumber;
  final String? dlRequestNumber;
  final String? peRequestNumber;

  final String? requestStatus;
  final String? deRequestStatus;
  final String? plRequestStatus;
  final String? dlRequestStatus;
  final String? peRequestStatus;
  final String? deTruckDriverName;
  final String? dlTruckDriverName;
  final String? peTruckDriverName;
  final String? plTruckDriverName;
  final String? freightForwarderName;
  final String? truckPlateNumber;
  final String? deTruckPlateNumber;
  final String? plTruckPlateNumber;
  final String? dlTruckPlateNumber;
  final String? peTruckPlateNumber;
  final String? truckType;
  final String? deTruckType;
  final String? plTruckType;
  final String? dlTruckType;
  final String? peTruckType;
  final String? contactPerson;
  final String? vehicleName;

  final String? contactNumber;

  final String? deProof;
  final String? plProof;
  final String? dlProof;
  final String? peProof;

  final String? deSign;
  final String? plSign;
  final String? dlSign;
  final String? peSign;
  final String? login;


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
    required this.transportForwarderName,
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
    required this.deTruckDriverName,
    required this.dlTruckDriverName,
    required this.peTruckDriverName,
    required this.plTruckDriverName,
    required this.freightForwarderName,
    required this.contactNumber,
    required this.truckPlateNumber,
    required this.deTruckPlateNumber,
    required this.plTruckPlateNumber,
    required this.dlTruckPlateNumber,
    required this.peTruckPlateNumber,
    required this.deTruckType,
    required this.plTruckType,
    required this.dlTruckType,
    required this.peTruckType,
    required this.truckType,
    required this.contactPerson,
    required this.vehicleName,
    required this.deProof,
    required this.plProof,
    required this.dlProof,
    required this.peProof,
    required this.deSign,  
    required this.plSign,   
    required this.dlSign,   
    required this.peSign,  
    required this.pickupDate,   
    required this.departureDate,    
    this.isAccepted = false,
    required this.login,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'] ?? 0,
      name: json['name'] ?? 'No Name Provided',  // Provide a default value
      origin: json['origin'] ?? 'Unknown Origin',  // Provide a default value
      destination: json['destination'] ?? 'Unknown Destination',  // Provide a default value
      arrivalDate: json['arrival_date'] ?? 'Unknown Arrival Date',  // Provide a default value
      deliveryDate: json['delivery_date'] ?? 'Unknown Delivery Date',  // Provide a default value
      status: json['status'] ?? 'Unknown Status',  // Provide a default value
      dispatchType: json['dispatch_type'] ?? 'Unknown Dispatch Type',
      containerNumber: json['container_number'].toString(),
      freightBlNumber: json['freight_bl_number'].toString(),
      sealNumber: json['seal_number'].toString(),
      bookingRefNo: json ['booking_reference_no'] ?? 'Unknown Booking Reference Number',
      transportForwarderName: json['origin_forwarder_name'] != null && json['origin_forwarder_name'].isNotEmpty
                            ? _extractName(json ['origin_forwarder_name']) : _extractName(json ['destination_forwarder_name']),
      freightBookingNumber: json ['freight_booking_number'],
      freightForwarderName: json['freight_forwarder_name'] != null && json['freight_forwarder_name'].isNotEmpty
                            ? _extractName(json['freight_forwarder_name'])
                            : '',
      contactNumber: json['dispatch_type'] == 'ot'
                    ? (json['shipper_phone'] != null && json['shipper_phone'].toString().isNotEmpty
                        ? json['shipper_phone']
                        : '')
                    : (json['consignee_phone'] != null && json['consignee_phone'].toString().isNotEmpty
                        ? json['consignee_phone']
                        : ''),

      contactPerson: json['dispatch_type'] == 'ot'
                    ? (json['shipper_contact_id'] != null && json['shipper_contact_id'].toString().isNotEmpty
                        ? _extractName(json['shipper_contact_id'])
                        : _extractName(json['shipper_id']))
                    : (json['consignee_contact_id'] != null && json['consignee_contact_id'].toString().isNotEmpty
                        ? _extractName(json['consignee_contact_id'])
                        : _extractName(json['consignee_id'])),

                 
      originContainerYard: json['origin_container_location'].toString(),
      requestNumber: json['de_request_no'].toString(),
      deRequestNumber: json['de_request_no'].toString(),
      plRequestNumber: json['pl_request_no'].toString(),
      dlRequestNumber: json['dl_request_no'].toString(),
      peRequestNumber: json['pe_request_no'].toString(),

      requestStatus: json['de_request_status'].toString(),
      deRequestStatus: json['de_request_status'].toString(),
      plRequestStatus: json['pl_request_status'].toString(),
      dlRequestStatus: json['dl_request_status'].toString(),
      peRequestStatus: json['pe_request_status'].toString(),
      deTruckDriverName: _extractDriverId(json['de_truck_driver_name'])?.toString(),
      dlTruckDriverName: _extractDriverId(json['dl_truck_driver_name'])?.toString(),
      peTruckDriverName: _extractDriverId(json['pe_truck_driver_name'])?.toString(),
      plTruckDriverName: _extractDriverId(json['pl_truck_driver_name'])?.toString(),
      truckPlateNumber: _extractName(json['de_truck_plate_no'])?.toString(),
      deTruckPlateNumber: _extractName(json['de_truck_plate_no'])?.toString(),
      plTruckPlateNumber: _extractName(json['pl_truck_plate_no'])?.toString(),
      dlTruckPlateNumber: _extractName(json['dl_truck_plate_no'])?.toString(),
      peTruckPlateNumber: _extractName(json['pe_truck_plate_no'])?.toString(),
      truckType: _extractName(json['de_truck_type'])?.toString(),
      deTruckType: _extractName(json['de_truck_type'])?.toString(),
      plTruckType: _extractName(json['pl_truck_type'])?.toString(),
      dlTruckType: _extractName(json['dl_truck_type'])?.toString(),
      peTruckType: _extractName(json['pe_truck_type'])?.toString(),
      vehicleName: _extractName(json['vehicle_name'])?.toString(), // Provide a default value
      deProof: json['de_proof'].toString(),
      plProof: json['pl_proof'].toString(),
      dlProof: json['dl_proof'].toString(),
      peProof: json['pe_proof'].toString(),

      deSign: json['de_signature'].toString(),
      plSign: json['pl_signature'].toString(),
      dlSign: json['dl_signature'].toString(),
      peSign: json['pe_signature'].toString(),

      pickupDate: json['pickup_date'] ?? 'Unknown Pick Up Date',  // Provide a default value
      departureDate: json['departure_date'] ?? 'Unknown DEparture Date',  // Provide a default value

      login: json['login'].toString(),
     

      isAccepted: false,  // set default or map from API
      
    );
  }

  static String? _extractName(dynamic field) {
    if (field is List && field.isNotEmpty) {
      return field[1]?.toString(); // Extract name (second item in list)
    } else if (field is String) {
      return field;
    }
    return null; // Return null if not available
  }

  static int? _extractDriverId(dynamic field) {
  if (field is List && field.isNotEmpty) {
    return field[0]; // ID is usually the first element
  }
  return null;
}


  Transaction copyWith({String? name, String? destination,String? requestNumber,String? origin,String? requestStatus,status, bool? isAccepted, String? truckPlateNumber}) {
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
      transportForwarderName: transportForwarderName,
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
      deTruckDriverName: deTruckDriverName,
      dlTruckDriverName: dlTruckDriverName,
      peTruckDriverName: peTruckDriverName,
      plTruckDriverName: plTruckDriverName,
      freightForwarderName: freightForwarderName,
      truckPlateNumber: truckPlateNumber ?? truckPlateNumber,
      deTruckPlateNumber: deTruckPlateNumber,
      plTruckPlateNumber: plTruckPlateNumber,
      dlTruckPlateNumber: dlTruckPlateNumber,
      peTruckPlateNumber: peTruckPlateNumber,
      truckType: truckType ?? truckType,
      deTruckType: deTruckType,
      plTruckType: plTruckType,
      dlTruckType: dlTruckType,
      peTruckType: peTruckType,
      contactNumber: contactNumber,
      contactPerson: contactPerson,
      vehicleName: vehicleName,
      deProof: deProof,
      plProof: plProof,
      dlProof: dlProof,
      peProof: peProof,

      deSign: deSign,
      plSign: plSign,
      dlSign: dlSign, 
      peSign: peSign,

      pickupDate: pickupDate,
      departureDate: departureDate,

      login: login,

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