import 'package:frontend/models/transaction_model.dart';


List<Transaction> expandTransactions(
  List<Transaction> transactionList,
  Set<String> acceptedTransactionIds,
  String? driverId,
) {
  List<Transaction> filtered = transactionList.where((t) {
    final key = "${t.id}-${t.requestNumber}";
    return !acceptedTransactionIds.contains(key);
  }).toList();

  return filtered.expand((item) {
    String cleanAddress(String address) {
      return address
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty && e.toLowerCase() != 'ph')
          .join(', ');
    }

    String descriptionMsg(Transaction item) {
      return item.landTransport == 'transport'
          ? 'Deliver Laden Container to Consignee'
          : 'Pickup Laden Container from Shipper';
    }

    String newName(Transaction item) {
      return item.landTransport == 'transport'
          ? 'Deliver to Consignee'
          : 'Pickup from Shipper';
    }

    if (item.dispatchType == "ot") {
      return [
        if (item.deTruckDriverName == driverId)
          item.copyWith(
            name: "Deliver to Shipper",
            destination: cleanAddress(item.origin),
            origin: cleanAddress(item.destination),
            requestNumber: item.deRequestNumber,
            requestStatus: item.deRequestStatus,
            rejectedTime: item.deRejectedTime,
            completedTime: item.deCompletedTime,
            originAddress: "Deliver Empty Container to Shipper",
          ),
        if (item.plTruckDriverName == driverId)
          item.copyWith(
            name: newName(item),
            destination: cleanAddress(item.origin),
            origin: cleanAddress(item.destination),
            requestNumber: item.plRequestNumber,
            requestStatus: item.plRequestStatus,
            rejectedTime: item.plRejectedTime,
            completedTime: item.plCompletedTime,
            originAddress: descriptionMsg(item),
          ),
      ];
    } else if (item.dispatchType == "dt") {
      return [
        if (item.dlTruckDriverName == driverId)
          item.copyWith(
            name: "Deliver to Consignee",
            origin: cleanAddress(item.destination),
            destination: cleanAddress(item.origin),
            requestNumber: item.dlRequestNumber,
            requestStatus: item.dlRequestStatus,
            rejectedTime: item.dlRejectedTime,
            completedTime: item.dlCompletedTime,
            originAddress: "Deliver Laden Container to Consignee",
          ),
        if (item.peTruckDriverName == driverId)
          item.copyWith(
            name: "Pickup from Consignee",
            origin: cleanAddress(item.origin),
            destination: cleanAddress(item.destination),
            requestNumber: item.peRequestNumber,
            requestStatus: item.peRequestStatus,
            rejectedTime: item.peRejectedTime,
            completedTime: item.peCompletedTime,
            originAddress: "Pickup Empty Container to Consignee",
          ),
      ];
    }
    return [item];
  }).toList();
}