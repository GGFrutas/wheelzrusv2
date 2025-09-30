import 'package:frontend/models/consolidation_model.dart';
import 'package:frontend/models/milestone_history_model.dart';

class Transaction {
  final int id;
  final String name;
  final String origin;
  final String destination;
  final String originAddress;
  final String destinationAddress;
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
  final String? serviceType;
  final String? stageId;
  final String? completedTime;
  final String? deCompletedTime;
  final String? plCompletedTime;
  final String? dlCompletedTime;
  final String? peCompletedTime;
  final String? rejectedTime;
  final String? deRejectedTime;
  final String? plRejectedTime;
  final String? dlRejectedTime;
  final String? peRejectedTime;

  final String? shipperProvince;
  final String? shipperCity;  
  final String? shipperBarangay;
  final String? shipperStreet;
  final String? consigneeProvince;
  final String? consigneeCity;  
  final String? consigneeBarangay;
  final String? consigneeStreet;

  final String? assignedDate;
  final String? deAssignedDate;
  final String? plAssignedDate;
  final String? dlAssignedDate;
  final String? peAssignedDate;

  final String? peReleasedBy;
  final String? deReleasedBy;
  final String? dlReceivedBy;
  final String? plReceivedBy;

  final String? landTransport;

 final String? writeDate;

 final String? bookingRefNumber;

  final List<MilestoneHistoryModel> history;
  final ConsolidationModel? backloadConsolidation;

  // final String? completeAddress ;


  const Transaction({
    required this.id,
    required this.name,
    required this.origin,
    required this.destination,
    required this.originAddress,
    required this.destinationAddress,
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
    required this.serviceType, 
    required this.stageId,
    required this.completedTime,
    required this.deCompletedTime,
    required this.plCompletedTime,
    required this.dlCompletedTime,
    required this.peCompletedTime,
    required this.rejectedTime,
    required this.deRejectedTime,
    required this.plRejectedTime,
    required this.dlRejectedTime,
    required this.peRejectedTime,
    required this.shipperProvince,
    required this.shipperCity,
    required this.shipperBarangay,
    required this.shipperStreet,
    required this.consigneeProvince,
    required this.consigneeCity,
    required this.consigneeBarangay,
    required this.consigneeStreet,
    required this.isAccepted,
    required this.assignedDate,
    required this.deAssignedDate,
    required this.plAssignedDate,
    required this.dlAssignedDate,
    required this.peAssignedDate,
    required this.login,
    required this.history,
    required this.landTransport,
    required this.writeDate,
    required this.deReleasedBy,
    required this.peReleasedBy,
    required this.dlReceivedBy,
    required this.plReceivedBy,
    required this.backloadConsolidation,
    required this.bookingRefNumber,
    // required this.completeAddress,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    // print('knii Raw transaction JSON: $json');
    final rawConsolidation = json['backload_consolidation'];

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
      bookingRefNo: json ['name'] ?? 'N/A',
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

      originAddress: json['origin_port_terminal_address'] ?? 'Unknown Origin Address',  // Provide a default value
      destinationAddress: json['destination_port_terminal_address'] ?? 'Unknown Destination Address',  // Provide a

                 
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

      serviceType:json['service_type']?.toString(),

      login: json['login'].toString(),
      stageId: json['stage_id']?.toString() ?? '0',  // Provide a default value

      completedTime: json['de_completion_time'] ?? 'Unknown Completed Time',
      deCompletedTime: json['de_completion_time'] ?? 'Unknown DE',
      plCompletedTime: json['pl_completion_time'] ?? 'Unknown PL',
      dlCompletedTime: json['dl_completion_time'] ?? 'Unknown DL',
      peCompletedTime: json['pe_completion_time'] ?? 'Unknown PE',

      rejectedTime: json['de_rejection_time'] ?? 'Unknown Rejected Time', // Provide a default value
      deRejectedTime: json['de_rejection_time'] ?? 'Unknown DE',
      plRejectedTime: json['pl_rejection_time'] ?? 'Unknown PL',
      dlRejectedTime: json['dl_rejection_time'] ?? 'Unknown DL',
      peRejectedTime: json['pe_rejection_time'] ?? 'Unknown PE',
      shipperProvince: json['shipper_province']?.toString() ?? 'Unknown Shipper Province',
      shipperCity: json['shipper_city']?.toString() ?? 'Unknown Shipper City',
      shipperBarangay: json['shipper_barangay']?.toString() ?? 'Unknown Shipper Barangay',
      shipperStreet: json['shipper_street']?.toString() ?? 'Unknown Shipper Street',
      consigneeProvince: json['consignee_province']?.toString() ?? 'Unknown Consignee Province',
      consigneeCity: json['consignee_city']?.toString() ?? 'Unknown Consignee City',
      consigneeBarangay: json['consignee_barangay']?.toString() ?? 'Unknown Consignee Barangay',
      consigneeStreet: json['consignee_street']?.toString() ?? 'Unknown Consignee Street',

      assignedDate: json['de_assignation_time'] ?? 'Unknown Assignation Time', // Provide a default value
      deAssignedDate: json['de_assignation_time'] ?? 'Unknown DE',
      plAssignedDate: json['pl_assignation_time'] ?? 'Unknown PL',
      dlAssignedDate: json['dl_assignation_time'] ?? 'Unknown DL',
      peAssignedDate: json['pe_assignation_time'] ?? 'Unknown PE',
      landTransport: json['booking_service'] ?? 'Unknown Transport', 

      plReceivedBy: json['pl_receive_by'].toString(),
      peReleasedBy: json['pe_release_by'].toString(),
      deReleasedBy: json['de_release_by'].toString(),
      dlReceivedBy: json['dl_receive_by'].toString(),

      bookingRefNumber: json['booking_reference_no']?.toString() ?? 'N/A',

      history: (json['history'] is List) 
        ? (json['history'] as List).map((e) => MilestoneHistoryModel.fromJson(e)).toList() : [],

      writeDate: json['write_date']?.toString() ?? 'Unknown Date', // Provide a default value

      isAccepted: false,  // set default or map from API

    backloadConsolidation: rawConsolidation != null && rawConsolidation is Map
        ? ConsolidationModel.fromJson(Map<String, dynamic>.from(rawConsolidation))
        : null,

      // completeAddress: json['origin']?.toString() ?? 'N/A',


      
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

 





  Transaction copyWith({String? name, String? destination,String? requestNumber,String? origin,String? requestStatus,status, bool? isAccepted, String? truckPlateNumber, String? destinationAddress, String? originAddress, String? rejectedTime, String? completedTime, String? assignedDate, String? freightBookingNumber}) {
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
      originAddress: originAddress ?? this.originAddress,
      destinationAddress: destinationAddress ?? this.destinationAddress,
      serviceType: serviceType,
      stageId: stageId,
      completedTime: completedTime ?? completedTime,
      deCompletedTime: deCompletedTime,
      plCompletedTime: plCompletedTime,
      dlCompletedTime: dlCompletedTime,
      peCompletedTime: peCompletedTime,

      rejectedTime: rejectedTime ?? rejectedTime,
      deRejectedTime: deRejectedTime,
      plRejectedTime: plRejectedTime,
      dlRejectedTime: dlRejectedTime,
      peRejectedTime: peRejectedTime,
      shipperProvince: shipperProvince,
      shipperCity: shipperCity,
      shipperBarangay: shipperBarangay,
      shipperStreet: shipperStreet,
      consigneeProvince: consigneeProvince,
      consigneeCity: consigneeCity,
      consigneeBarangay: consigneeBarangay,
      consigneeStreet: consigneeStreet,
      assignedDate: assignedDate ?? assignedDate,
      deAssignedDate: deAssignedDate,
      plAssignedDate: plAssignedDate,
      dlAssignedDate: dlAssignedDate,
      peAssignedDate: peAssignedDate,
      landTransport: landTransport,
      writeDate: writeDate,

      peReleasedBy: peReleasedBy,
      deReleasedBy: deReleasedBy,
      dlReceivedBy: dlReceivedBy,
      plReceivedBy: plReceivedBy,

      bookingRefNumber:bookingRefNumber,
      

      login: login,
       history: history,
       backloadConsolidation: backloadConsolidation,

        // completeAddress: completeAddress, 

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