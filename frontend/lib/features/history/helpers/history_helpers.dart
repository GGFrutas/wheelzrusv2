import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:frontend/models/milestone_history_model.dart';
import 'package:frontend/models/transaction_model.dart';



class HistoryHelpers {
  String? _getLegForTransaction(Transaction tx) {
    final legRequestMap = {
      'de': tx.deRequestNumber,
      'pl': tx.plRequestNumber,
      'dl': tx.dlRequestNumber,
      'pe': tx.peRequestNumber,
    };
    final entry = legRequestMap.entries.firstWhere(
      (e) => e.value == tx.requestNumber,
      orElse: () => const MapEntry('', null),
    );
    return entry.key.isEmpty ? null : entry.key;
  }

  MilestoneHistoryModel? _getLatestMilestoneForLeg(Transaction tx, String leg) {
    if (tx.history == null || tx.history!.isEmpty) return null;

    // Filter history by dispatchId and leg
    final matchingHistory = tx.history!
        .where((h) =>
            h.dispatchId.toString() == tx.id.toString() &&
            h.fclCode.toUpperCase().startsWith(leg.toUpperCase()) && // optional if your FCL codes use leg prefixes
            h.actualDatetime.isNotEmpty == true)
        .toList();

    if (matchingHistory.isEmpty) {
      // If none match by FCL prefix, fallback to any milestone for this dispatchId
      final fallbackHistory = tx.history!
          .where((h) =>
              h.dispatchId.toString() == tx.id.toString() &&
              h.actualDatetime.isNotEmpty == true)
          .toList();

      if (fallbackHistory.isEmpty) return null;

      fallbackHistory.sort((a, b) {
        final aTime = DateTime.tryParse(a.actualDatetime) ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bTime = DateTime.tryParse(b.actualDatetime) ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bTime.compareTo(aTime);
      });

      return fallbackHistory.first;
    }

    // Sort by latest datetime
    matchingHistory.sort((a, b) {
      final aTime = DateTime.tryParse(a.actualDatetime) ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bTime = DateTime.tryParse(b.actualDatetime) ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bTime.compareTo(aTime);
    });

    return matchingHistory.first;
  }

   Map< String, String> separateDateTime(String? dateTime) {
    if (dateTime == null || dateTime.isEmpty) {
      return {"date": "N/A", "time": "N/A"}; // Return default values if null or empty
    }

    try {
      DateTime datetime = DateTime.parse("${dateTime}Z").toLocal();

      return {
        "date": DateFormat('dd MMM , yyyy').format(datetime),
        "time": DateFormat('hh:mm a').format(datetime),
      };
    } catch (e) {
      print("Error parsing date: $e");
      return {"date": "N/A", "time": "N/A"}; // Return default values on error
    }
  }

  Color getStatusColor(String status) {
    switch (status) {
      case 'Completed':
        return const Color.fromARGB(255, 28, 157, 114);
      case 'Cancelled':
        return  Colors.red;
      case 'Rejected':
        return  Colors.grey;
      default:
      return Colors.grey;
    }
  }
  String getStatusLabel(Transaction item, String currentDriverId, String currentDriverName) {
    final status = item.requestStatus?.trim();
    final stage = item.stageId?.trim();
    final isReassigned = item.reassigned?.any(
      (r) => r.driverId.toString() == currentDriverId ||
            r.driverName.toLowerCase().contains(currentDriverName.toLowerCase()) &&
            r.requestNumber == item.requestNumber,
    ) ?? false;



    if (item.isReassigned == true || isReassigned) return 'Reassigned';

    if (status == 'Completed' || status == 'Backload') return status!;
    if (stage == 'Completed' || stage == 'Cancelled') return stage!;
    return '—';
  }

  Map<String, String> getCompletedTransactionDatetime(Transaction tx) {
  final leg = _getLegForTransaction(tx);
  MilestoneHistoryModel? milestone;

  if (leg != null) {
    milestone = _getLatestMilestoneForLeg(tx, leg);
  }

  String? rawDateTime;
if (tx.isReassigned == true) {
  rawDateTime = tx.completedTime ; // always use reassignment's create_date
} else if (tx.requestStatus == 'Completed') {
  rawDateTime = tx.completedTime?.isNotEmpty == true
      ? tx.completedTime
      : milestone?.actualDatetime ?? tx.backloadConsolidation?.consolidatedDatetime ?? tx.writeDate;
} else if (tx.requestStatus == 'Backload') {
  rawDateTime = tx.backloadConsolidation?.consolidatedDatetime.isNotEmpty == true
      ? tx.backloadConsolidation?.consolidatedDatetime
      : milestone?.actualDatetime ?? tx.completedTime ?? tx.writeDate;
} else if (tx.stageId == 'Cancelled') {
  rawDateTime = tx.writeDate?.isNotEmpty == true
      ? tx.writeDate
      : milestone?.actualDatetime ?? tx.completedTime ?? tx.backloadConsolidation?.consolidatedDatetime;
} else {
  rawDateTime = milestone?.actualDatetime ?? tx.completedTime ?? tx.backloadConsolidation?.consolidatedDatetime ?? tx.writeDate;
}


  return separateDateTime(rawDateTime);
}
}