// ignore_for_file: unused_import, avoid_print

import 'dart:convert';
import 'dart:io';
import 'dart:math';

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
import 'package:frontend/user/confirmation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:signature/signature.dart';

class ScheduleScreen extends ConsumerStatefulWidget {
  final String uid;
  final Transaction? transaction;

  const ScheduleScreen({super.key, required this.uid, required this.transaction});

  @override
  ConsumerState<ScheduleScreen> createState() => _ScheduleState();
}

class _ScheduleState extends ConsumerState<ScheduleScreen> {
  late String uid;

  @override
  void initState() {
    super.initState();
    uid = widget.uid; // Initialize uid
  }

  String getNullableValue(String? value, {String fallback = ''}) {
    return value ?? fallback;
  }
  
  Map< String, String> separateDateTime(String? dateTime) {
    if (dateTime == null || dateTime.isEmpty) {
      return {"date": "N/A", "time": "N/A"}; // Return default values if null or empty
    }

    try {
      DateTime datetime = DateTime.parse(dateTime);

      return {
        "date": DateFormat(' MMMM dd, yyyy').format(datetime),
        "time": DateFormat('hh:mm a').format(datetime),
      };
    } catch (e) {
      print("Error parsing date: $e");
      return {"date": "N/A", "time": "N/A"}; // Return default values on error
    }
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
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  getNullableValue(widget.transaction?.name).toUpperCase(),
                  style:AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.bold,
                    color: mainColor,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              progressRow(2), // Pass an integer value for currentStep
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(8.0), // Add padding inside the container
                
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10.0),
                  child: Image.asset(
                    'assets/Freight Forwarding.jpg',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  "Freight and Container Info", // Section Title
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w600,
                    color: const Color.fromARGB(255, 128, 137, 145),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16.0), // Add padding inside the container
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(20.0), // Rounded edges
                ),
                child: Column(
                  children:[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: List.generate(6, (index) { // Example: 7 squares
                          return Container(
                            width: 50, // Adjust for square size
                            height: 50,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(2.0),
                            ),
                            alignment: Alignment.center,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '${16 + index}', // Example dates (17, 18, 19...)
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  'March', // You can make this dynamic too
                                  style: AppTextStyles.caption.copyWith(
                                    fontWeight: FontWeight.bold
                                  ),
                                ),
                                const SizedBox(height: 5), // Small space before the line
                                Container(
                                  width: 50, // Match the square width
                                  height: 2, // Thin line height
                                  color: Colors.black26, // Line color
                                  constraints: const BoxConstraints(
                                    maxWidth: 50, // Ensure it doesn't exceed the square width
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.check_circle,
                            color: mainColor,
                            size: 20,
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children:[
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                    "Pick Up Schedule: ",
                                      // Use the originPort variable here
                                      style: AppTextStyles.caption.copyWith(
                                        color: mainColor,
                                      ),
                                    ),
                                    const SizedBox(height: 5), // Space between label and value
                                    Text(
                                      "Pick up Time: ",
                                      style: AppTextStyles.caption.copyWith(
                                        color: mainColor,
                                      ),
                                    ),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      separateDateTime(widget.transaction?.arrivalDate)["date"] ?? "N/A",
                                      style: AppTextStyles.caption.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: mainColor,
                                      ),
                                    ),
                                    const SizedBox(height: 5), // Space between label and value
                                      Text(
                                        separateDateTime(widget.transaction?.arrivalDate)["time"] ?? "N/A",
                                        style: AppTextStyles.caption.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: mainColor,
                                        ),
                                      )
                                  ],
                                )
                              ]
                            ),
                          )
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.check_circle,
                            color: mainColor,
                            size: 20,
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children:[
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                    "Delivery Schedule: ",
                                      // Use the originPort variable here
                                      style: AppTextStyles.caption.copyWith(
                                        color: mainColor,
                                      ),
                                    ),
                                    const SizedBox(height: 5), // Space between label and value
                                    Text(
                                      "Delivery Time: ",
                                      style: AppTextStyles.caption.copyWith(
                                        color: mainColor,
                                      ),
                                    ),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      separateDateTime(widget.transaction?.deliveryDate)["date"] ?? "N/A",
                                      style: AppTextStyles.caption.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: mainColor,
                                      ),
                                    ),
                                    const SizedBox(height: 5), // Space between label and value
                                    Text(
                                      separateDateTime(widget.transaction?.deliveryDate)["time"] ?? "N/A",
                                      style: AppTextStyles.caption.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: mainColor,
                                      ),
                                    )
                                  ],
                                )
                              ]
                            ),
                          )
                        ],
                      ),
                  ]
                ),
                
              ),
            ],
          ),
          
        ),
        
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          top: 8,
          left: 16,
          right: 16,
        ),
        child: ElevatedButton(
        onPressed: () {
          print("uid: ${widget.uid}");
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ConfirmationScreen(uid: widget.uid, transaction: widget.transaction),
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: mainColor,
          padding: const EdgeInsets.symmetric(horizontal: 100, vertical: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30.0),
          ),
        ),
        child: Text(
          "Next",
          style: AppTextStyles.body.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
      ),
      ),
      // bottomNavigationBar: const NavigationMenu(),
    );
  }

  // Progress Indicator Row
  Widget progressRow(int currentStep) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: List.generate(3 * 2 - 1, (index) {
      // Step indices: 0, 2, 4; Connector indices: 1, 3
      if (index.isEven) {
        int stepIndex = index ~/ 2 + 1;
        Color stepColor = stepIndex < currentStep
            ? mainColor     // Completed
            : stepIndex == currentStep
                ? mainColor  // Active
                : Colors.grey;     // Upcoming

        bool isCurrent = stepIndex == currentStep;

        String label;
        switch (stepIndex) {
          case 1:
            label = "Delivery Log";
            break;
          case 2:
            label = "Schedule";
            break;
          case 3:
          default:
            label = "Confirmation";
        }

        return buildStep(label, stepColor, isCurrent);
      } else {
        int connectorIndex = (index - 1) ~/ 2 + 1;
        Color connectorColor = connectorIndex < currentStep
            ? mainColor
            : Colors.grey;

        return buildConnector(connectorColor);
      }
    }),
  );
}


  /// Single Progress Step Widget
 Widget buildStep(String label, Color color, bool isCurrent) {
  return Column(
    children: [
      CircleAvatar(
        radius: 10,
        backgroundColor: color,
        child: isCurrent
            ? const CircleAvatar(
                radius: 7,
                backgroundColor: Colors.white,
              )
            : null,
      ),
      const SizedBox(height: 5),
      Text(
        label,
        style: AppTextStyles.caption.copyWith(
          color: color,
        ),
      ),
    ],
  );
}


  /// Connector Line Between Steps
  Widget buildConnector(Color color) {
    return Transform.translate(
      offset: const Offset(0, -10),
      child: 
        Container(
          width: 40,
          height: 4,
          color: color,
        ),
    );
  }
}
