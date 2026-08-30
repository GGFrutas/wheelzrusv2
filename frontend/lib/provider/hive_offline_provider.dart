import 'dart:convert';
import 'package:frontend/models/pod_offline_model.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;

class PendingPodUploader {
  bool _isUploadingPendingPods = false;

  /// Upload all pending pods and return a list of uploaded request numbers
  Future<List<String>> uploadPendingPods() async {
    if (_isUploadingPendingPods) return [];

    _isUploadingPendingPods = true;
    final uploadedRequests = <String>[];

    try {
      final box = await Hive.openBox<PodModel>('pendingPods');
      if (box.isEmpty) return [];

      final pods = box.values.toList();

      for (var pod in pods) {
        if (pod.isUploading) continue; // skip pods already in progress

        pod.isUploading = true;
        await pod.save();

        try {
          final response = await http.post(
            Uri.parse(pod.uri),
            headers: pod.headers,
            body: jsonEncode(pod.body),
          );

          if (response.statusCode == 200) {
            // Add the requestNumber for notification
            final requestNumber = pod.body['requestNumber']?.toString() ?? pod.key.toString();
            uploadedRequests.add(requestNumber);

            // Remove from Hive
            await box.delete(pod.key);
          } else {
            pod.isUploading = false;
            await pod.save();
          }
        } catch (e) {
          pod.isUploading = false;
          await pod.save();
        }
      }
    } finally {
      _isUploadingPendingPods = false;
    }

    return uploadedRequests;
  }
}
