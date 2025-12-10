import 'package:hive/hive.dart';

part 'pod_offline_model.g.dart'; // Run build_runner to generate this

@HiveType(typeId: 0)
class PodModel extends HiveObject {
  @HiveField(0)
  String uri;

  @HiveField(1)
  Map<String, String> headers;

  @HiveField(2)
  Map<String, dynamic> body;

  PodModel({required this.uri, required this.headers, required this.body});
}
