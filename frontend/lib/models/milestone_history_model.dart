class MilestoneHistoryModel {
  final int id;
  final String dispatchId;
  final String dispatchType;
  final String fclCode;
  final String scheduledDatetime;
  final String serviceType;
  final String actualDatetime;
  final String? isBackload;

  const MilestoneHistoryModel({
    required this.id,
    required this.dispatchId,
    required this.dispatchType,
    required this.fclCode,
    required this.scheduledDatetime,
    required this.serviceType,
    required this.actualDatetime,
    required this.isBackload,
  });

  factory MilestoneHistoryModel.fromJson(Map<String, dynamic> json) {
    final serviceTypeRaw = json['service_type'];
    return MilestoneHistoryModel(
      id: json['id'] ?? 0,
      dispatchId: (json['dispatch_id'] is List && (json['dispatch_id'] as List).isNotEmpty)
        ? (_extractId(json['dispatch_id'])?.toString() ?? '')
        : '',
      dispatchType: json['dispatch_type'] ?? 'Unknown Dispatch Type',
      fclCode: json['fcl_code'] ?? 'Unknown FCL Code',
      scheduledDatetime: json['scheduled_datetime'] ?? 'Unknown Time',
      serviceType: serviceTypeRaw is List && serviceTypeRaw.length > 1
        ? serviceTypeRaw[1].toString()
        : '',

        actualDatetime: (json['actual_datetime'] is String && json['actual_datetime'].isNotEmpty)
        ? json['actual_datetime']
        : '',
      isBackload: json['is_backload']?.toString(),

    );
  }
  


  static int? _extractId(dynamic field) {
    if (field is List && field.isNotEmpty) {
      return field[0]; // ID is usually the first element
    }
    return null;
  }




  MilestoneHistoryModel copyWith({String? name, String? destination,String? requestNumber,String? origin,String? requestStatus,status, bool? isAccepted, String? truckPlateNumber, String? destinationAddress, String? originAddress, String? rejectedTime, String? completedTime, String? assignedDate}) {
    return MilestoneHistoryModel(
      id: id,
    dispatchId: dispatchId,
      dispatchType: dispatchType,
     fclCode: fclCode,
     scheduledDatetime: scheduledDatetime,
     serviceType: serviceType,
     actualDatetime: actualDatetime, 
     isBackload: isBackload

    );
  }
 
}