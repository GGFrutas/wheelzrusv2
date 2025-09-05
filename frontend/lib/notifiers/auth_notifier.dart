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
  final String? driverNumber;
  final String? login;
  final String? partnerImageBase64;
  final String? driverphone;
  final String? companyName;
  final String? licenseNumber;
  final String? licenseExpiry;
  final String? licenseStatus;

  AuthState({
    required this.isLoading,
    required this.isError,
    required this.uid,
    required this.password,
    required this.partnerId,
    required this.driverName,
    required this.driverNumber,
    required this.login,
    required this.partnerImageBase64,
    required this.driverphone,
    required this.companyName,
    required this.licenseNumber,
    required this.licenseExpiry,
    required this.licenseStatus,
  });

  

  // Helper method to copy the state with updated values
  AuthState copyWith({bool? isLoading, bool? isError, String? uid, String? password, String? partnerId, String? driverName, String? driverNumber, String? login, String? partnerImageBase64, String? driverphone,
  String? companyName, String? licenseNumber, String? licenseExpiry, String? licenseStatus}) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      isError: isError ?? this.isError,
      uid: uid ?? this.uid,
      password: password ?? this.password,
      partnerId: partnerId ?? this.partnerId,
      driverName: driverName ?? this.driverName,
      driverNumber: driverNumber ?? this.driverNumber,
      login: login ?? this.login,
      partnerImageBase64: partnerImageBase64 ?? this.partnerImageBase64,
      driverphone: driverphone ?? this.driverphone,
      companyName: companyName ?? this.companyName,
      licenseNumber: licenseNumber ?? this.licenseNumber,
      licenseExpiry: licenseExpiry ?? this.licenseExpiry,
      licenseStatus: licenseStatus ?? this.licenseStatus,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;

  AuthNotifier(this._authService)
      : super(AuthState(isLoading: false, isError: false, uid: null, password: null, partnerId: null, driverName: '', driverNumber: null, login: null, partnerImageBase64: '', driverphone: null, companyName: '',
      licenseNumber: null, licenseExpiry: null, licenseStatus: null)) {
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

        // 👇 Extract "Driver 1" from "XXX Company, Driver Name"
        final String driverName = partnerFullName.split(',').length > 1
            ? partnerFullName.split(',')[1].trim()
            : partnerFullName;

         // 👇 Extract company from "XXX Company, Driver Name"
        final String companyName = partnerFullName.split(',')[0].trim();

        
        final String rawDriverNumber = data['mobile']?.toString().trim().toLowerCase() ?? '';
        final String driverNumber =  (rawDriverNumber.isNotEmpty && rawDriverNumber != 'false')
            ? rawDriverNumber
            : '—';

        final String rawDriverphone = data['phone']?.toString().trim().toLowerCase() ?? '';
        final String driverphone =  (rawDriverphone.isNotEmpty && rawDriverphone != 'false')
            ? rawDriverphone
            : '—';

        final String? rawImage = data['user']['image_1920']?.toString();
        final String partnerImageBase64 = (rawImage != null && rawImage.isNotEmpty && rawImage != 'false') ? rawImage : '';


        final String login = user['login'].toString();

        final String licenseNumber = data['license_number']?.toString() ?? '';
        final String licenseExpiry = data['license_expiry']?.toString().trim().toLowerCase() ?? '';
        final String licenseStatus = data['license_status']?.toString().trim().toUpperCase() ?? '';


        if (user == null) {
          throw Exception('User or uid is null');
        }

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('uid', uid);
        await prefs.setString('password', apiPassword);
        await prefs.setString('partner_id', partnerId);
        await prefs.setString('name', partnerFullName);
        await prefs.setString('driver_name', driverName);
        await prefs.setString('mobile', driverNumber);
        await prefs.setString('login', login);
        await prefs.setString('partner_image', partnerImageBase64);
        await prefs.setString('phone', driverphone);
        await prefs.setString('company_name', companyName);
        await prefs.setString('license_number', licenseNumber);
        await prefs.setString('license_expiry', licenseExpiry);
        await prefs.setString('license_status', licenseStatus);


        if (context.mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => HomePage(user: user),
            ),
          );
        }

        state = state.copyWith(isLoading: false, isError: false, uid: uid, password: password, partnerId: partnerId, driverName: driverName, driverNumber: driverNumber, login: login, partnerImageBase64: partnerImageBase64,
        driverphone: driverphone, companyName: companyName, licenseNumber: licenseNumber,licenseExpiry: licenseExpiry, licenseStatus: licenseStatus); // ✅ Store both uid and password
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
    final storedDriverNumber = prefs.getString('mobile') ?? ''; 
    final storedLogin = prefs.getString('login') ?? ''; 
    final storedPartnerImageBase64 = prefs.getString('partner_image') ?? '';
    final storedDriverphone = prefs.getString('phone') ?? '';
    final storedCompanyName = prefs.getString('company_name') ?? '';
    final storedLicenseNumber = prefs.getString('license_number') ?? '';
    final storedLicenseExpiry = prefs.getString('license_expiry') ?? '';
    final storedLicenseStatus = prefs.getString('license_status') ?? '';


    if (storedUid != null && storedUid.isNotEmpty && storedPassword != null) {
      // print('✅ Loaded UID: $storedUid');
      // print('✅ Loaded Partner ID: $storedPartnerId'); 

      state = state.copyWith(uid: storedUid, password: storedPassword, partnerId:storedPartnerId, driverName: storedDriverName, driverNumber: storedDriverNumber, login: storedLogin, partnerImageBase64: storedPartnerImageBase64,
      driverphone: storedDriverphone, companyName: storedCompanyName, licenseNumber: storedLicenseNumber,licenseExpiry: storedLicenseExpiry, licenseStatus: storedLicenseStatus); // ✅ Store both
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
