import 'package:frontend/models/milestone_history_model.dart';
import 'package:frontend/models/transaction_model.dart';

import 'transaction_utils.dart'; // make sure you import your existing utils


class TransactionHelpers {
  // /// Returns the expanded leg for the current driver, or the original transaction if none found
  // static Transaction getCurrentLeg(Transaction transaction, String driverId) {
  //   final expandedLegs = TransactionUtils.expandTransaction(transaction, driverId);

  //   if (expandedLegs.isNotEmpty) {
  //     return expandedLegs.first; // usually only one leg for this driver
  //   }

  //   // fallback: no matching leg, return original transaction
  //   return transaction;
  // }

 
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
            truckPlateNumber: item.deTruckPlateNumber,
            reassigned: item.reassigned
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
            truckPlateNumber: item.plTruckPlateNumber,
            reassigned: item.reassigned
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
            truckPlateNumber: item.dlTruckPlateNumber,
            reassigned: item.reassigned
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
            truckPlateNumber: item.peTruckPlateNumber,
            reassigned: item.reassigned
          ),
      ];
    }

    // default: return as-is
    return [item];
  }

   /// Returns the pickup and delivery schedule for a single transaction
  // static Map<String, MilestoneHistoryModel?> getScheduleForTransaction(
  //     Transaction transaction, String driverId) {
  //   final currentLeg = getCurrentLeg(transaction, driverId);
  //   return getPickupAndDeliverySchedule(currentLeg);
  // }
}
