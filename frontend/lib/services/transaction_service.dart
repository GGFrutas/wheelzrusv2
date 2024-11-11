import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final transactionServiceProvider =
    Provider<TransactionService>((ref) => TransactionService());

class TransactionService {
  final _dio = Dio(
    BaseOptions(
      baseUrl: 'http://10.0.2.2:8000/api',
      headers: {
        'Accept': 'application/json',
      },
    ),
  );

  Future<Map<String, dynamic>> submit(
      int userId,
      double amount,
      DateTime transactionDate,
      String description,
      String transactionId,
      String booking,
      String location,
      String destination,
      DateTime eta,
      DateTime etd,
      String status) async {
    FormData formData = FormData.fromMap({
      'user_id': userId,
      'amount': amount,
      'transaction_date': transactionDate.toIso8601String(),
      'description': description,
      'transaction_id': transactionId,
      'booking': booking,
      'location': location,
      'destination': destination,
      'eta': eta.toIso8601String(),
      'etd': etd.toIso8601String(),
      'status': status,
    });

    final response = await _dio.post(
      '/createTransaction',
      data: formData,
      options: Options(
        contentType: 'multipart/form-data',
      ),
    );
    return response.data;
  }
}
