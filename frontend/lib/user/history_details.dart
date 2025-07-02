// ignore_for_file: unused_import, avoid_print

import 'dart:convert';
import 'dart:io';

import 'package:animated_toggle_switch/animated_toggle_switch.dart';
import 'package:flutter/material.dart';
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
import 'package:intl/intl.dart';
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

    String formatDateTime(String? dateString) {
      if (dateString == null || dateString.isEmpty) return "N/A"; // Handle null values
      
      try {
        DateTime dateTime = DateTime.parse(dateString); // Convert string to DateTime
        return DateFormat('dd / MM / yyyy  - h:mm a').format(dateTime); // Format date-time
      } catch (e) {
        return "Invalid Date"; // Handle errors gracefully
      }
    } 

    String? _getDisplayName(String? name) {
      

      if(widget.transaction?.dispatchType == 'ot') {
        return 'Shipper Info';
      } else if (widget.transaction?.dispatchType == 'dt') {
        return 'Consignee Info';
      }else{
        return null;
      }
    }

   
    

  
  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
  
    final driverContactNumber = (authState.driverNumber != null && authState.driverNumber!.trim().isNotEmpty)
      ? authState.driverNumber!
          : '—';

    final driverName = (authState.driverName?.isNotEmpty ?? false)
      ? authState.driverName!
      : '—'; 

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
                              driverName,
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
                              driverContactNumber,
                              // Use the originPort variable here
                              style: AppTextStyles.subtitle.copyWith(
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              "Contact Number",
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
                                widget.transaction?.requestNumber ?? '',
                                style: AppTextStyles.subtitle.copyWith(
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                "Request Number",
                                style: AppTextStyles.caption.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Space between label and value
                              Text(
                                widget.transaction?.requestStatus == 'Rejected'
                                  ? formatDateTime(widget.transaction?.rejectedTime)
                                  : widget.transaction?.requestStatus == 'Completed'
                                    ? formatDateTime(widget.transaction?.completedTime)
                                    : '—',
                                style: AppTextStyles.subtitle.copyWith(
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                widget.transaction?.requestStatus == 'Rejected' ?
                                "Rejected Date" : widget.transaction?.requestStatus == 'Completed' ? 'Completed Date' : 'Date',
                                style: AppTextStyles.caption.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ), 
              const SizedBox(height: 20), // Space between sections
              Container(
                  // color: Colors.green[500], // Set background color for this section
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    _getDisplayName(widget.transaction?.name) ?? '', // Section Title
                    style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.bold,
                      color: darkerBgColor,
                    ),
                  ),
                ),
                const Divider(
                  color: bgColor, // Divider color
                  thickness: 1, // Divider thickness
                ),
                const SizedBox(height: 20), // Space between title and content
                Column( // Use a Column to arrange the widgets vertically
                  crossAxisAlignment: CrossAxisAlignment.start, // Align text to the left
                  children: [
                    Row(
                      children: [
                        const SizedBox(width: 30), // Space between icon and text
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Port of Origin",
                              style: AppTextStyles.subtitle.copyWith(
                                color: Colors.black,
                                fontWeight: FontWeight.bold
                              ),
                            ),
                            Text(
                              (widget.transaction?.origin.isNotEmpty ?? false)
                              ? widget.transaction!.origin : '—',
                              style: AppTextStyles.body.copyWith(
                                color: Colors.black,
                              ),
                            ),
                            
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        const SizedBox(width: 30), // Space between icon and text
                        Expanded
                        (
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Service Provider",
                                style: AppTextStyles.subtitle.copyWith(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold
                                ),
                              ),
                              Text(
                              (widget.transaction?.freightForwarderName?.isNotEmpty ?? false)
                              ? widget.transaction!.freightForwarderName! : '—',
                                // Use the originPort variable here
                                style: AppTextStyles.body.copyWith(
                                  color: Colors.black,
                                ),
                              ),
                              
                            ],
                          ),

                        )
                        
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        const SizedBox(width: 30), // Space between icon and text
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Bill of Lading Number",
                              style: AppTextStyles.subtitle.copyWith(
                                color: Colors.black,
                                fontWeight: FontWeight.bold
                              ),
                            ),
                            Text(
                              (widget.transaction?.freightBlNumber?.isNotEmpty ?? false)
                              ? widget.transaction!.freightBlNumber! : '—',
                              style: AppTextStyles.body.copyWith(
                                color: Colors.black,
                              ),
                            ),
                            
                          ],
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        const SizedBox(width: 30), // Space between icon and text
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Container Seal Number",
                              style: AppTextStyles.subtitle.copyWith(
                                color: Colors.black,
                                fontWeight: FontWeight.bold
                              ),
                            ),
                            Text(
                            (widget.transaction?.sealNumber?.isNotEmpty ?? false)
                              ? widget.transaction!.sealNumber!
                              : '—',
                              // Use the originPort variable here
                              style: AppTextStyles.body.copyWith(
                                color: Colors.black,
                              ),
                            ),
                            
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              
              
              const SizedBox(height: 70),
            ],
          ),
          
        ),
        
      ),
      
      // bottomNavigationBar: const NavigationMenu(),
    );
  } 
}
