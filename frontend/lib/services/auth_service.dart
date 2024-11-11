import 'dart:io';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

class AuthService {
  final _dio = Dio(
    BaseOptions(
      baseUrl: 'http://10.0.2.2:8000/api',
      headers: {
        'Accept': 'application/json',
      },
    ),
  );

  Future<Map<String, dynamic>> login(String email, String password) async {
    // bool isLoggedIn = false;

    final response =
        await _dio.post('/login', data: {'email': email, 'password': password});

    print(response);
    return response.data;
  }

  Future<Map<String, dynamic>> register(
      String name,
      String email,
      String mobile,
      String? companyCode,
      String password,
      File? picture) async {
    FormData formData = FormData.fromMap({
      'name': name,
      'email': email,
      'mobile': mobile,
      'company_code': companyCode,
      'password': password,
      if (picture != null)
        'picture': await MultipartFile.fromFile(
          picture.path,
          filename: picture.path.split('/').last,
        ),
    });

    final response = await _dio.post(
      '/register',
      data: formData, // Send the formData instead of plain data
      options: Options(
        contentType: 'multipart/form-data', // Ensure proper content type
      ),
    );
    return response.data;
  }

  Future<Map<String, dynamic>> logout() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      throw Exception('No authentication token found');
    }

    final response = await _dio.post(
      '/logout',
      options: Options(
        headers: {
          'Authorization': 'Bearer $token',
        },
      ),
    );
    return response.data;
  }

  Future<Map<String, dynamic>> update(
    String? name,
    String? email,
    String? mobile,
    String? companyCode,
    String? password,
    File? picture,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      throw Exception('No authentication token found');
    }

    FormData formData = FormData.fromMap({
      if (name != null) 'name': name,
      if (email != null) 'email': email,
      if (mobile != null) 'mobile': mobile,
      if (companyCode != null) 'companyCode': companyCode,
      if (password != null) 'password': password,
      if (picture != null)
        'picture': await MultipartFile.fromFile(
          picture.path,
          filename: picture.path.split('/').last,
        ),
    });
    try {
      final response = await _dio.put(
        '/update', // Your API endpoint
        data: formData,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception(
            'Failed to update profile. Status code: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error updating profile: $e');
    }
  }

  // final response = await _dio.put(
  //   '/update', // Ensure this is your correct endpoint
  //   data: data,
  //   options: Options(
  //     headers: {
  //       'Authorization': 'Bearer $token',
  //       'Content-Type': 'application/json',
  //     },
  //   ),
  // );

  // return response.data;
}
