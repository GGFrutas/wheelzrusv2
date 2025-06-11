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
  final String? uid;
  final String? password;
  final String? partnerId;
  final String? driverName;

  AuthState({
    required this.isLoading,
    required this.isError,
    required this.uid,
    required this.password,
    required this.partnerId,
    required this.driverName,
  });

  

  // Helper method to copy the state with updated values
  AuthState copyWith({bool? isLoading, bool? isError, String? uid, String? password, String? partnerId, String? driverName}) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      isError: isError ?? this.isError,
      uid: uid ?? this.uid,
      password: password ?? this.password,
      partnerId: partnerId ?? this.partnerId,
      driverName: driverName ?? this.driverName,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;

  AuthNotifier(this._authService)
      : super(AuthState(isLoading: false, isError: false, uid: null, password: null, partnerId: null, driverName: '')) {
    // loadUid();  
    _initialize(); // Load UID from SharedPreferences when the notifier is created
  }

    Future<void> _initialize() async {
      await loadUid();
    }



    //Login
    Future<void> login({
      required String email,
      required String password,
      required BuildContext context,
    }) async {
      try {
        state = state.copyWith(isLoading: true, isError: false);

        final response = await _authService.login(email, password);
        // print('Raw Response: $response'); // Debugging

        final data = response is String ? jsonDecode(response as String) : response;
        // print('Parsed Data: $data'); // Debugging

        final user = data['user'];
        final String uid = data['uid'].toString();
        final String apiPassword = (data['password'] ?? '').toString();
        final List<dynamic> partnerData = data['user']['partner_id'];
        final String partnerId = partnerData[0].toString(); // 👈 this gets just the ID (e.g., "238")
        final String partnerFullName = partnerData[1].toString();

        // 👇 Extract "Driver 1" from "Z Transport, Driver 1"
        final String driverName = partnerFullName.split(',').length > 1
            ? partnerFullName.split(',')[1].trim()
            : partnerFullName;

        print('🧾 Partner Name: $partnerFullName');
        print('👤 Driver Name: $driverName');

        final String driverName = partnerFullName.split(',').length > 1
            ? partnerFullName.split(',')[1].trim()
            : partnerFullName;

        if (user == null) {
          throw Exception('User or uid is null');
        }

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('uid', uid);
        await prefs.setString('password', apiPassword);
        await prefs.setString('partner_id', partnerId);
        await prefs.setString('name', partnerFullName);
        await prefs.setString('driver_name', driverName);

        if (context.mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => HomePage(user: user),
            ),
          );
        }

        state = state.copyWith(isLoading: false, isError: false, uid: uid, password: password, partnerId: partnerId, driverName: driverName); // ✅ Store both uid and password
      } catch (e) {
        // print('Login Error: $e');
        state = state.copyWith(isLoading: false, isError: true);
      }

    }
    
  Future<void> loadUid() async {
    final prefs = await SharedPreferences.getInstance();
    final storedUid = prefs.getString('uid');
    final storedPassword = prefs.getString('password');
    final storedPartnerId = prefs.getString('partnerId');
    final storedDriverName = prefs.getString('driver_name') ?? ''; 

    if (storedUid != null && storedUid.isNotEmpty && storedPassword != null) {
      print('✅ Loaded UID: $storedUid');
      print('✅ Loaded Partner ID: $storedPartnerId'); 

      state = state.copyWith(uid: storedUid, password: storedPassword, partnerId:storedPartnerId, driverName: storedDriverName); // ✅ Store both
    } else {
      // print('❌ Missing UID or Password in storage.');
    } 

    // if (storedUid != null && storedUid.isNotEmpty) {
    //   state = state.copyWith(uid: storedUid);
    //   print('✅ Loaded UID from storage: $storedUid');
    // } else {
    //   print('❌ No stored UID found.');
    // }
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
      final String uid = data['uid'].toString();
      final String apiPassword = (data['password'] ?? '').toString();

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('uid', uid);
      await prefs.setString('password', apiPassword);

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
      // print(e);
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
      // final response = await _authService.update(
      //   name,
      //   email,
      //   mobile,
      //   companyCode,
      //   password,
      //   picture,
      // );
      // final data =
      //     response is String ? jsonDecode(response as String) : response;
      // print('Data returned');
      // print(data);
      // final user = data['user'];

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
      // print(e);
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
