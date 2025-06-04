// ignore_for_file: unused_import, avoid_print

import 'dart:convert';
import 'dart:io';

import 'package:animated_toggle_switch/animated_toggle_switch.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/models/transaction_model.dart';
import 'package:frontend/notifiers/auth_notifier.dart';
import 'package:frontend/provider/accepted_transaction.dart' as accepted_transaction;
import 'package:frontend/provider/theme_provider.dart';
import 'package:frontend/provider/transaction_list_notifier.dart';
import 'package:frontend/provider/transaction_provider.dart';
import 'package:frontend/screen/navigation_menu.dart';
import 'package:frontend/theme/colors.dart';
import 'package:frontend/theme/text_styles.dart';
import 'package:frontend/user/schedule.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:signature/signature.dart';

class HistoryDetailScreen extends ConsumerStatefulWidget {
  final String uid;
  final Transaction? transaction;

  const HistoryDetailScreen({super.key, required this.uid, required this.transaction});

  @override
  ConsumerState<HistoryDetailScreen> createState() => _HistoryDetailState();
}

class _HistoryDetailState extends ConsumerState<HistoryDetailScreen> {
  late String uid;

  @override
  void initState() {
    super.initState();
    uid = widget.uid; // Initialize uid
  }

  String getNullableValue(String? value, {String fallback = ''}) {
    return value ?? fallback;
  }

  
  @override
  Widget build(BuildContext context) {
     
    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: mainColor),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: ListView(
            children: [
              
              Container(
                padding: const EdgeInsets.all(16.0), // Add padding inside the container
                
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 45, 144,111),
                  borderRadius: BorderRadius.circular(20.0), // Rounded edges
                ),
                
                child: Column( // Use a Column to arrange the widgets vertically
                  crossAxisAlignment: CrossAxisAlignment.start, // Align text to the left
                  children: [
                    Row(
                      children: [
                        const SizedBox(height: 50, width: 20,), // Space between icon and text
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Space between label and value
                            Text(
                              widget.transaction?.requestNumber ?? 'N/A',
                              style: AppTextStyles.subtitle.copyWith(
                                color: Colors.white,
                              ),
                            ),
                             Text(
                              "Driver Name",
                              style: AppTextStyles.caption.copyWith(
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),
                    Row(
                      children: [ 
                        const SizedBox(width: 20), // Space between icon and text
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Space between label and value
                            Text(
                            (widget.transaction?.origin.isNotEmpty ?? false)
                            ? widget.transaction!.origin : '—',
                              // Use the originPort variable here
                              style: AppTextStyles.subtitle.copyWith(
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              "Port of Origin",
                              style: AppTextStyles.caption.copyWith(
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),
                    Row(
                      children: [
                        
                        const SizedBox(width: 20), // Space between icon and text
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Space between label and value
                              Text(
                              widget.transaction?.requestNumber ?? 'N/A',
                                // Use the originPort variable here
                                style: AppTextStyles.subtitle.copyWith(
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                "Request Number",
                                style: AppTextStyles.caption.copyWith(
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        )
                        
                      ],
                    ),
                  ],
                ),
              ), // ⬅️ Added progress indicator above content
              
              const SizedBox(height: 70),
            ],
          ),
          
        ),
        
      ),
      
      // bottomNavigationBar: const NavigationMenu(),
    );
  } 
}
