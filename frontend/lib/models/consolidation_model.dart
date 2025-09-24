import 'package:frontend/models/consolidation_extension.dart';

class ConsolidationModel {
  final int id;
  final String name;
  // final String status;
  final String consolidatedDatetime;
  // final String? isBackload;

  const ConsolidationModel({
    required this.id,
    required this.name,
    // required this.status,
    required this.consolidatedDatetime,
    // required this.isBackload,
  });

  factory ConsolidationModel.fromJson(Map<String, dynamic> json) {
     
    return ConsolidationModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? 'Unknown Name',
      // status: json['status'] ?? 'Unknown Status',
      consolidatedDatetime:  json['consolidated_date'] ?? 'Unknown Date',


      
      // isBackload: json['is_backload']?.toString(),

    );
  }
  


  ConsolidationModel copyWith({String? name}) {
    return ConsolidationModel(
      id: id,
      name: name ?? this.name,
      // status: status,
      consolidatedDatetime: consolidatedDatetime,
      
      // isBackload: isBackload

    );
  }
  String get formattedConsolidatedDate {
    if (consolidatedDatetime.trim().isNotEmpty) {
      final parsed = separateDateTime(consolidatedDatetime);
      return parsed['date'] ?? '—';
    }
    return '—';
  }

}
