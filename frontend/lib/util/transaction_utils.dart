import 'package:frontend/models/driver_reassignment_model.dart';
import 'package:frontend/models/transaction_model.dart';

class TransactionUtils {
  static String removeBrackets(String input) {
    return input
        .replaceAll(RegExp(r'\s*\[.*?\]'), '')
        .replaceAll(RegExp(r'\s*\(.*?\)'), '')
        .trim();
  }

  static String cleanAddress(List<String?> parts) {
    return parts
        .where((e) =>
            e != null &&
            e.trim().isNotEmpty &&
            e.trim().toLowerCase() != 'ph')
        .map((e) => removeBrackets(e!))
        .join(', ');
  }

  static String buildConsigneeAddress(Transaction item,
      {bool cityLevel = false}) {
    return cleanAddress(cityLevel
        ? [item.consigneeCity, item.consigneeProvince]
        : [
            item.consigneeStreet,
            item.consigneeBarangay,
            item.consigneeCity,
            item.consigneeProvince
          ]);
  }

  static String buildShipperAddress(Transaction item,
      {bool cityLevel = false}) {
    return cleanAddress(cityLevel
        ? [item.shipperCity, item.shipperProvince]
        : [
            item.shipperStreet,
            item.shipperBarangay,
            item.shipperCity,
            item.shipperProvince
          ]);
  }

  static String descriptionMsg(Transaction item) {
    return item.landTransport == 'transport'
        ? 'Deliver Laden Container to Consignee'
        : 'Pickup Laden Container from Shipper';
  }

  static String newName(Transaction item) {
    return item.landTransport == 'transport'
        ? 'Deliver to Consignee'
        : 'Pickup from Shipper';
  }

  /// Expands a transaction into multiple "legs" depending on dispatchType
  static List<Transaction> expandTransaction(
      Transaction item, String driverId) {
    if (item.dispatchType == "ot") {
      final shipperOrigin = buildShipperAddress(item);
      final shipperDestination = cleanAddress([item.destination]);

      return [
        if (item.deTruckDriverName == driverId)
          item.copyWith(
            name: "Deliver to Shipper",
            origin: shipperDestination,
            destination: shipperOrigin,
            requestNumber: item.deRequestNumber,
            requestStatus: item.deRequestStatus,
            assignedDate: item.deAssignedDate,
            originAddress: "Deliver Empty Container to Shipper",
            freightBookingNumber: item.freightBookingNumber,
            completedTime: item.deCompletedTime,
          ),
        if (item.plTruckDriverName == driverId)
          item.copyWith(
            name: newName(item),
            origin: shipperOrigin,
            destination: shipperDestination,
            requestNumber: item.plRequestNumber,
            requestStatus: item.plRequestStatus,
            assignedDate: item.plAssignedDate,
            originAddress: descriptionMsg(item),
            freightBookingNumber: item.freightBookingNumber,
             completedTime: item.plCompletedTime,
          ),
      ];
    } else if (item.dispatchType == "dt") {
      final consigneeOrigin = buildConsigneeAddress(item);
      final consigneeDestination = cleanAddress([item.origin]);

      return [
        if (item.dlTruckDriverName == driverId)
          item.copyWith(
            name: "Deliver to Consignee",
            origin: consigneeDestination,
            destination: consigneeOrigin,
            requestNumber: item.dlRequestNumber,
            requestStatus: item.dlRequestStatus,
            assignedDate: item.dlAssignedDate,
            originAddress: "Deliver Laden Container to Consignee",
            freightBookingNumber: item.freightBookingNumber,
             completedTime: item.dlCompletedTime,
          ),
        if (item.peTruckDriverName == driverId)
          item.copyWith(
            name: "Pickup from Consignee",
            origin: consigneeOrigin,
            destination: consigneeDestination,
            requestNumber: item.peRequestNumber,
            requestStatus: item.peRequestStatus,
            assignedDate: item.peAssignedDate,
            originAddress: "Pickup Empty Container from Consignee",
            freightBookingNumber: item.freightBookingNumber,
              completedTime: item.peCompletedTime,
          ),
      ];
    }

    // default: return as-is
    return [item];
  }

  /// Expand a full transaction list
  static List<Transaction> expandTransactions(
      List<Transaction> transactions, String driverId) {
    return transactions
        .expand((item) => expandTransaction(item, driverId))
        .toList();
  }

static List<Transaction> expandReassignments(List<DriverReassignment> reassignments, String driverId) {
  return reassignments
      .where((e) => e.driverId.toString() == driverId)
      .map((e) => Transaction(

            id: int.tryParse(e.id.toString()) ?? 0,
            name: 'Reassigned',
            requestStatus: 'Reassigned',
            isReassigned: true,

            origin: '',
            destination: '',
            originAddress: '',
            destinationAddress: '',
            arrivalDate: '',
            deliveryDate: '',
            pickupDate: '',
            departureDate: '',
            status: '',
            isAccepted: false,
            dispatchType: '',
            containerNumber: null,
            freightBlNumber: null,
            sealNumber: null,
            bookingRefNo: null,
            transportForwarderName: null,
            freightBookingNumber: null,
            originContainerYard: null,
            requestNumber: null,
            deRequestNumber: null,
            plRequestNumber: null,
            dlRequestNumber: null,
            peRequestNumber: null,
            deRequestStatus: null,
            plRequestStatus: null,
            dlRequestStatus: null,
            peRequestStatus: null,
            deTruckDriverName: null,
            dlTruckDriverName: null,
            peTruckDriverName: null,
            plTruckDriverName: null,
            freightForwarderName: null,
            truckPlateNumber: null,
            deTruckPlateNumber: null,
            plTruckPlateNumber: null,
            dlTruckPlateNumber: null,
            peTruckPlateNumber: null,
            truckType: null,
            deTruckType: null,
            plTruckType: null,
            dlTruckType: null,
            peTruckType: null,
            contactPerson: null,
            vehicleName: null,
            contactNumber: null,
            deProof: null,
            plProof: null,
            dlProof: null,
            peProof: null,
            deProofFilename: null,
            plProofFilename: null,
            dlProofFilename: null,
            peProofFilename: null,
            deSign: null,
            plSign: null,
            dlSign: null,
            peSign: null,
            login: null,
            serviceType: null,
            stageId: null,
            completedTime: null,
            deCompletedTime: null,
            plCompletedTime: null,
            dlCompletedTime: null,
            peCompletedTime: null,
            rejectedTime: null,
            deRejectedTime: null,
            plRejectedTime: null,
            dlRejectedTime: null,
            peRejectedTime: null,
            shipperProvince: null,
            shipperCity: null,
            shipperBarangay: null,
            shipperStreet: null,
            consigneeProvince: null,
            consigneeCity: null,
            consigneeBarangay: null,
            consigneeStreet: null,
            assignedDate: null,
            deAssignedDate: null,
            plAssignedDate: null,
            dlAssignedDate: null,
            peAssignedDate: null,
            peReleasedBy: null,
            deReleasedBy: null,
            dlReceivedBy: null,
            plReceivedBy: null,
            landTransport: null,
            writeDate: null,
            bookingRefNumber: null,
            history: [],
            backloadConsolidation: null,
            reassignment: [],
            proofStock: null,
            proofStockFilename: null,
            hwbSigned: null,
            hwbSignedFilename: null,
            deliveryReceipt: null,
            deliveryReceiptFilename: null,
            packingList: null,
            packingListFilename: null,
            deliveryNote: null,
            deliveryNoteFilename: null,
            stockDelivery: null,
            stockDeliveryFilename: null,
            salesInvoice: null,
            salesInvoiceFilename: null,
          ))
      .toList();
}

}
