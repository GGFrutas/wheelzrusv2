import 'package:frontend/models/transaction_model.dart';
import 'package:frontend/provider/accepted_transaction.dart' as accepted_transaction;

List<Transaction> expandedTransaction(
  List<Transaction> transaction,
  String driverId,
) {
    String cleanAddress(String address) {
      return address
        .split(',') // splits the string by commas
        .map((e) => e.trim()) //removes extra spaces
        .where((e) => e.isNotEmpty && e.toLowerCase() != 'ph') //filters out empty strings and 'ph'
        .join(', '); // joins the remaining parts back together
    }

    String descriptionMsg(Transaction item) {
      if (item.landTransport == 'transport'){
        return 'Deliver Laden Container to Consignee';
      } else {
        return 'Pickup Laden Container from Shipper';
      }
    }
    String newName(Transaction item) {
      if (item.landTransport == 'transport'){
        return 'Deliver to Consignee';
      } else {
        return 'Pickup from Shipper';
      }
    }

   
    return transaction.expand((item) {
      if (item.dispatchType == "ot") {
        return [
          // First instance: Deliver to Shipper
          if (item.deTruckDriverName == driverId) // Filter out if accepted
            // Check if the truck driver is the same as the authPartnerId
            item.copyWith(
              name: "Deliver to Shipper",
              destination: cleanAddress(item.origin),
              origin: cleanAddress(item.destination),
              requestNumber: item.deRequestNumber,
              requestStatus: item.deRequestStatus,
              rejectedTime: item.deRejectedTime,
              completedTime: item.deCompletedTime,
              originAddress: "Deliver Empty Container to Shipper",
              freightBookingNumber:item.freightBookingNumber,

              // truckPlateNumber: item.deTruckPlateNumber,
            ),
            // Second instance: Pickup from Shipper
          if ( item.plTruckDriverName == driverId) // Filter out if accepted
            // if (item.plTruckDriverName == authPartnerId)
              item.copyWith(
              name: newName(item),
              destination: cleanAddress(item.origin),
              origin: cleanAddress(item.destination),
              requestNumber: item.plRequestNumber,
              requestStatus: item.plRequestStatus,
              rejectedTime: item.plRejectedTime,
              completedTime: item.plCompletedTime,
              originAddress: descriptionMsg(item),
              freightBookingNumber:item.freightBookingNumber,
              // truckPlateNumber: item.plTruckPlateNumber,
              ),
        ];
      } else if (item.dispatchType == "dt") {
        return [
          // First instance: Deliver to Consignee
          if (item.dlTruckDriverName == driverId) // Filter out if accepted
            item.copyWith(
              name: "Deliver to Consignee",
              origin: cleanAddress(item.destination),
              destination: cleanAddress(item.origin),
              requestNumber: item.dlRequestNumber,
              requestStatus: item.dlRequestStatus,
              rejectedTime: item.dlRejectedTime,
              completedTime: item.dlCompletedTime,
              originAddress: "Deliver Laden Container to Consignee",
              freightBookingNumber:item.freightBookingNumber,
              // truckPlateNumber: item.dlTruckPlateNumber,
            ),
          // Second instance: Pickup from Consignee
          if (item.peTruckDriverName == driverId) // Filter out if accepted
            item.copyWith(
              name: "Pickup from Consignee",
              origin: cleanAddress(item.origin),
              destination: cleanAddress(item.destination),
              requestNumber: item.peRequestNumber,
              requestStatus: item.peRequestStatus,
              rejectedTime: item.peRejectedTime,
              completedTime: item.peCompletedTime,
              originAddress: "Pickup Empty Container to Consignee",
              freightBookingNumber:item.freightBookingNumber,
              // truckPlateNumber: item.peTruckPlateNumber,
            ),
        ]; 
      }
      // Return as-is if no match
      return [item];
    }).toList();

}
