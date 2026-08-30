import 'package:frontend/models/transaction_model.dart';
import 'package:frontend/services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AssignmentNotificationService {
  static const _seenRequestsKey = 'seen_request_numbers';
  static const _initializedKey = 'assignment_notif_initialized';

  static Future<void> checkAndNotifyNewAssignments(
    List<Transaction> transactions) async {
  final prefs = await SharedPreferences.getInstance();

  // Get logged-in driver's ID
  final driverId = prefs.getString('partner_id') ?? '';

  final isFirstRun = !(prefs.getBool(_initializedKey) ?? false);
  final seen = prefs.getStringList(_seenRequestsKey) ?? [];
  final seenSet = seen.toSet();
  final newSeen = <String>{};

  for (final tx in transactions) {
    // Only add request number if THIS driver is assigned to it
    final candidates = <String, String?>{};

    if (tx.deTruckDriverName == driverId && tx.deRequestNumber != null)
      candidates['DE'] = tx.deRequestNumber;

    if (tx.plTruckDriverName == driverId && tx.plRequestNumber != null)
      candidates['PL'] = tx.plRequestNumber;

    if (tx.dlTruckDriverName == driverId && tx.dlRequestNumber != null)
      candidates['DL'] = tx.dlRequestNumber;

    if (tx.peTruckDriverName == driverId && tx.peRequestNumber != null)
      candidates['PE'] = tx.peRequestNumber;

    print('🔔 TX id=${tx.id} | matched candidates=$candidates');

    for (final entry in candidates.entries) {
      final reqNo = entry.value;
      if (reqNo == null || reqNo == 'null' || reqNo.trim().isEmpty) continue;

      newSeen.add(reqNo);

      if (!isFirstRun && !seenSet.contains(reqNo)) {
        print('🔔 FIRING assignment notification for: $reqNo');
        await NotificationService.showAssignmentNotification(
          requestNumber: reqNo,
          dispatchType: entry.key,
        );
      }
    }
  }

  await prefs.setStringList(_seenRequestsKey, newSeen.toList());

  if (isFirstRun) {
    await prefs.setBool(_initializedKey, true);
    print('🔔 First run done, saved ${newSeen.length} request numbers');
  }
}
}