// ignore_for_file: unused_import, avoid_print

import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:animated_toggle_switch/animated_toggle_switch.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/models/milestone_history_model.dart';
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
    // schedule = getPickupAndDeliverySchedule(widget.transaction!) as MilestoneHistoryModel?;
  }

  String getNullableValue(String? value, {String fallback = ''}) {
    return value ?? fallback;
  }
  MilestoneHistoryModel? schedule;


  Map<String, MilestoneHistoryModel?> getPickupAndDeliverySchedule(Transaction transaction) {
  final dispatchType = transaction.dispatchType;
  final history = transaction.history;
  final serviceType = transaction.serviceType;
  final dispatchId = transaction.id.toString();

  final fclPrefixes = {
    'ot': {
      'Full Container Load': {
        'de': {'delivery': 'TEOT', 'pickup': 'TYOT'} ,
        'pl': {'delivery': 'CLOT', 'pickup': 'TLOT'},
      },
      'Less-Than-Container Load': {
        'pl': {'delivery': 'LCLOT', 'pickup': 'LTEOT'} ,
      },
    },
    'dt': {
      'Full Container Load': {
        'dl': {'delivery': 'CLDT','pickup': 'GYDT'},
        'pe': {'delivery': 'CYDT', 'pickup':'GLDT'},
      },
      'Less-Than-Container Load': {
        'dl': {'delivery': 'LCLDT','pickup': 'LGYDT'},
      },
    },
  };

  final legs = ['de', 'pl', 'dl', 'pe'];
  final fieldCodeMap = {
    'de': transaction.deRequestNumber,
    'pl': transaction.plRequestNumber,
    'dl': transaction.dlRequestNumber,
    'pe': transaction.peRequestNumber,
  };

  MilestoneHistoryModel? pickup;
  MilestoneHistoryModel? delivery;

  for (final leg in legs) {
    final requestNo = fieldCodeMap[leg];
    if (requestNo == null || requestNo.isEmpty) continue;

    final fclMap = fclPrefixes[dispatchType]?[serviceType]?[leg];
    if (fclMap == null) continue;


    final pickupFcl = fclMap['pickup'];
    final deliveryFcl = fclMap['delivery'];

    // Find Pickup
    if (pickupFcl != null) {
      pickup = history.firstWhere(
        (h) =>
            h.fclCode.trim().toUpperCase() == pickupFcl.toUpperCase() &&
            h.dispatchId == dispatchId &&
            h.serviceType == serviceType,
        orElse: () => const MilestoneHistoryModel(
          id: -1,
          dispatchId: '',
          dispatchType: '',
          fclCode: '',
          scheduledDatetime: '',
          serviceType: '',
        ),
      );
      if (pickup.id == -1) pickup = null;
    }

    // Find Delivery
    if (deliveryFcl != null) {
      delivery = history.firstWhere(
        (h) =>
            h.fclCode.trim().toUpperCase() == deliveryFcl.toUpperCase() &&
            h.dispatchId == dispatchId &&
            h.serviceType == serviceType,
        orElse: () => const MilestoneHistoryModel(
          id: -1,
          dispatchId: '',
          dispatchType: '',
          fclCode: '',
          scheduledDatetime: '',
          serviceType: '',
        ),
      );
      if (delivery.id == -1) delivery = null;

      if(pickup != null || delivery != null) {
        pickup = pickup;
        delivery = delivery;
        break;
      }
    }

    // If both found for this leg, stop
    if (pickup != null || delivery != null) break;
  }

  return {
    'pickup': pickup,
    'delivery': delivery,
  };
}


  

  Map< String, String> separateDateTime(String? dateTime) {
    if (dateTime == null || dateTime.isEmpty) {
      return {"date": "N/A", "time": "N/A"}; // Return default values if null or empty
    }

    try {
      DateTime datetime = DateTime.parse("${dateTime}Z").toLocal();

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
   final scheduleMap = getPickupAndDeliverySchedule(widget.transaction!);
final pickup = scheduleMap['pickup'];
final delivery = scheduleMap['delivery'];
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
                  "Pickup and Delivery Schedule", // Section Title
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
                                      separateDateTime(pickup?.scheduledDatetime)["date"] ?? "N/A",
                                      style: AppTextStyles.caption.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: mainColor,
                                      ),
                                    ),
                                    const SizedBox(height: 5), // Space between label and value
                                      Text(
                                        separateDateTime(pickup?.scheduledDatetime)["time"] ?? "N/A",
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
                                      separateDateTime(delivery?.scheduledDatetime)["date"] ?? "N/A",
                                      style: AppTextStyles.caption.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: mainColor,
                                      ),
                                    ),
                                    const SizedBox(height: 5), // Space between label and value
                                    Text(
                                      separateDateTime(delivery?.scheduledDatetime)["time"] ?? "N/A",
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
      bottomNavigationBar: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column (
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: double.infinity,
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
                  )
                ],
              )
              
            ),
            const NavigationMenu(),
          ],
          
        )
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
