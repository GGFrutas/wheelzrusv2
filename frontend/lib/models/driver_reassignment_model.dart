class DriverReassignment {
  final String id;
  final int dispatchId;
  final String dispatchName;
  final int driverId;
  final String driverName;

  DriverReassignment({
    required this.id,
    required this.dispatchId,
    required this.dispatchName,
    required this.driverId,
    required this.driverName,
  });

  factory DriverReassignment.fromJson(Map<String, dynamic> json) {
    final dispatch = (json['dispatch_id'] is List && json['dispatch_id']!.length >= 2)
        ? json['dispatch_id'] as List
        : [0, ''];

    final driver = (json['driver_id'] is List && json['driver_id']!.length >= 2)
        ? json['driver_id'] as List
        : [0, ''];

    return DriverReassignment(
      id: json['id'].toString(),
      dispatchId: dispatch[0] as int,
      dispatchName: dispatch[1].toString(),
      driverId: driver[0] as int,
      driverName: driver[1].toString(),
    );
  }
}