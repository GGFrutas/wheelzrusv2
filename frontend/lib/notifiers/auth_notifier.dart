import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/screen/homepage_screen.dart';
import 'package:frontend/services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';

final authNotifierProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) {
    final authService = ref.watch(authServiceProvider);
    return AuthNotifier(
        authService); // Remove isError since we handle it in AuthState
  },
);

class AuthState {
  final bool isLoading;
  final bool isError;

  AuthState({
    required this.isLoading,
    required this.isError,
  });

  // Helper method to copy the state with updated values
  AuthState copyWith({bool? isLoading, bool? isError}) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      isError: isError ?? this.isError,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;

  AuthNotifier(this._authService)
      : super(AuthState(isLoading: false, isError: false));

  //Login
  Future<void> login({
    required String email,
    required String password,
    required BuildContext context,
  }) async {
    try {
      // Set loading state
      state = state.copyWith(isLoading: true, isError: false);

      final response = await _authService.login(email, password);
      final data =
          response is String ? jsonDecode(response as String) : response;
      final user = data['user'];
      final token = data['token'];

      // Save the token
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', token);
      if (context.mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomePage(user: user),
          ),
        );
      }
      await Future.delayed(const Duration(seconds: 1));
      state = state.copyWith(isLoading: false, isError: false);

      // Set state back to not loading
    } catch (e) {
      print(e);
      state = state.copyWith(isLoading: false, isError: true);
      if (context.mounted) {
        const snackBar = SnackBar(
          elevation: 0,
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.transparent,
          content: AwesomeSnackbarContent(
            title: 'Bad Credentials!',
            message: 'Invalid username or password. Please try again.',
            contentType: ContentType.failure,
          ),
        );
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(snackBar);
      }
    }
  }

  //Register
  Future<void> register({
    required String name,
    required String email,
    String? companyCode,
    required String mobile,
    required String password,
    File? picture,
    required BuildContext context,
  }) async {
    try {
      // Set loading state
      state = state.copyWith(isLoading: true);
      final response = await _authService.register(
        name,
        email,
        mobile,
        companyCode!, // Assuming companyCode can be null
        password,
        picture!,
      );
      final data =
          response is String ? jsonDecode(response as String) : response;

      final user = data['user'];
      final token = data['token'];

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', token);

      if (context.mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomePage(user: user),
          ),
        );
      }

      // Set state back to not loading
      state = state.copyWith(isLoading: false);
    } catch (e) {
      print(e);
      state = state.copyWith(isLoading: false, isError: true);
      if (context.mounted) {
        const snackBar = SnackBar(
          elevation: 0,
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.transparent,
          content: AwesomeSnackbarContent(
            title: 'Oh Snap!',
            message: 'An error occurred during sign up. Please try again.',
            contentType: ContentType.failure,
          ),
        );
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(snackBar);
      }
    }
  }

  //Update
  Future<void> update({
    String? name,
    String? email,
    String? mobile,
    String? companyCode,
    String? password,
    File? picture,
    required BuildContext context,
  }) async {
    try {
      // Set loading state
      state = state.copyWith(isLoading: true, isError: false);
      final response = await _authService.update(
        name,
        email,
        mobile,
        companyCode,
        password,
        picture,
      );
      final data =
          response is String ? jsonDecode(response as String) : response;
      print('Data returned');
      print(data);
      final user = data['user'];

      if (context.mounted) {
        const snackBar = SnackBar(
          elevation: 0,
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.transparent,
          content: AwesomeSnackbarContent(
            title: 'Success!',
            message: 'Updated',
            contentType: ContentType.success,
          ),
        );
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(snackBar);
      }

      // Set state back to not loading
      state = state.copyWith(isLoading: false);
    } catch (e) {
      print(e);
      state = state.copyWith(isLoading: false, isError: true);
      if (context.mounted) {
        const snackBar = SnackBar(
          elevation: 0,
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.transparent,
          content: AwesomeSnackbarContent(
            title: 'Oh Snap!',
            message: 'An error occurred during update. Please try again.',
            contentType: ContentType.failure,
          ),
        );
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(snackBar);
      }
    }
  }
}
