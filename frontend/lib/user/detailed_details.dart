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

class DetailedDetailScreen extends ConsumerStatefulWidget {
  final String uid;
  final Transaction? transaction;

  const DetailedDetailScreen({super.key, required this.uid, required this.transaction});

  @override
  ConsumerState<DetailedDetailScreen> createState() => _DetailedDetailState();
}

class _DetailedDetailState extends ConsumerState<DetailedDetailScreen> {
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
    // final transaction = widget.transaction;
    // final dispatchType = transaction?.dispatchType;
    // final serviceType = transaction?.serviceType;
    // final bookingNumber = transaction?.freightBookingNumber;

    // /// Helper to check if a value is null or empty
    // bool isNullOrEmpty(dynamic value) {
    //   return value == null || value.toString().trim().isEmpty;
    // }

    // /// Determine if the button should be hidden
    // final showButton = (dispatchType == 'ot' && (isNullOrEmpty(transaction?.deProof) || isNullOrEmpty(transaction?.deSign))&& widget.transaction?.plRequestNumber == widget.transaction?.requestNumber) ||
    //                   (dispatchType == 'dt' && (isNullOrEmpty(transaction?.dlProof) || isNullOrEmpty(transaction?.dlSign))  && widget.transaction?.peRequestNumber == widget.transaction?.requestNumber);
    final transaction = widget.transaction;
    final dispatchType = transaction?.dispatchType;
    final requestNumber = transaction?.requestNumber;
    final plRequestNumber = transaction?.plRequestNumber;
    final peRequestNumber = transaction?.peRequestNumber;
    final bookingNumber = transaction?.bookingRefNo;

    /// Helper
    bool isNullOrEmpty(dynamic value) {
      return value == null || value.toString().trim().isEmpty;
    }

    /// Base conditions (ot and dt)
    bool hideForCurrentDispatch = 
      (dispatchType == 'ot' &&
        (isNullOrEmpty(transaction?.deProof) || isNullOrEmpty(transaction?.deSign)) &&
        plRequestNumber == requestNumber) ||

      (dispatchType == 'dt' &&
        (isNullOrEmpty(transaction?.dlProof) || isNullOrEmpty(transaction?.dlSign)) &&
        peRequestNumber == requestNumber);

    final allTransactions = ref.read(acceptedTransactionProvider);

    print("All: $allTransactions");
    final relatedFF = allTransactions.cast<Transaction?>().firstWhere(
      (tx) => (tx?.bookingRefNo == bookingNumber) && (tx?.dispatchType == 'ff'),
      orElse: () => null,
    );

    print("Related FF: $relatedFF");

    bool ffNotComplete = relatedFF != null && relatedFF.stageId != '7';

    /// Final decision: if any rule to hide the button is true, we hide it
    final showButton = hideForCurrentDispatch || ffNotComplete;

        
    return PopScope(
      canPop: true,
      onPopInvoked: (didPop) {
        if(didPop) {
          ref.invalidate(pendingTransactionProvider);
            ref.invalidate(acceptedTransactionProvider);
            ref.invalidate(bookingProvider);
            ref.invalidate(filteredItemsProvider);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          iconTheme: const IconThemeData(color: mainColor),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              ref.invalidate(pendingTransactionProvider);
              ref.invalidate(acceptedTransactionProvider);
              ref.invalidate(bookingProvider);
              ref.invalidate(filteredItemsProvider);
              Navigator.pop(context);
            },
          ),
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
                progressRow(1),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16.0), // Add padding inside the container
                  
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(20.0), // Rounded edges
                  ),
                  
                  child: Column( // Use a Column to arrange the widgets vertically
                    crossAxisAlignment: CrossAxisAlignment.start, // Align text to the left
                    children: [
                      Row(
                        children: [
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.circle_rounded,
                            color: mainColor,
                            size: 15,
                          ),
                          const SizedBox(width: 20), // Space between icon and text
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Space between label and value
                              Text(
                                widget.transaction?.requestNumber ?? 'N/A',
                                style: AppTextStyles.subtitle.copyWith(
                                  color: mainColor,
                                ),
                              ),
                              Text(
                                "Request Number",
                                style: AppTextStyles.caption.copyWith(
                                  color: mainColor,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.circle_rounded,
                            color: mainColor,
                            size: 15,
                          ),
                          const SizedBox(width: 20), // Space between icon and text
                          Expanded (
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Space between label and value
                                Text(
                                // (widget.transaction?.originAddress.isNotEmpty ?? false)
                                // ? widget.transaction!.originAddress.toUpperCase() : '—',
                                (widget.transaction?.origin.isNotEmpty ?? false)
                                ? widget.transaction!.origin.toUpperCase() : '—',
                                  // Use the originPort variable here
                                  style: AppTextStyles.subtitle.copyWith(
                                    color: mainColor,
                                  ),
                                ),
                                Text(
                                  "Port of Origin",
                                  style: AppTextStyles.caption.copyWith(
                                    color: mainColor,
                                  ),
                                ),
                              ],
                            ),
                          )
                          
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.circle_rounded,
                            color: mainColor,
                            size: 15,
                          ),
                          const SizedBox(width: 20), // Space between icon and text
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Space between label and value
                                Text(
                                (widget.transaction?.freightForwarderName?.isNotEmpty ?? false)
                                ? widget.transaction!.freightForwarderName!.toUpperCase() : '—',
                                  // Use the originPort variable here
                                  style: AppTextStyles.subtitle.copyWith(
                                    color: mainColor,
                                  ),
                                ),
                                Text(
                                  "Service Provider",
                                  style: AppTextStyles.caption.copyWith(
                                    color: mainColor,
                                  ),
                                ),
                              ],
                            ),
                          )
                          
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.circle_rounded,
                            color: mainColor,
                            size: 15,
                          ),
                          const SizedBox(width: 20), // Space between icon and text
                          Expanded(
                            child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                (widget.transaction?.contactPerson?.isNotEmpty ?? false)
                                ? widget.transaction!.contactPerson! : '—',
                                style: AppTextStyles.subtitle.copyWith(
                                    color: mainColor,
                                  ),
                                ),
                                Text(
                                  "Contact Person",
                                  style: AppTextStyles.caption.copyWith(
                                    color: mainColor,
                                  ),
                                ),
                              ],
                            ),
                          )
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.circle_rounded,
                            color: mainColor,
                            size: 15,
                          ),
                          const SizedBox(width: 20), // Space between icon and text
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Space between label and value
                              Text(
                              (widget.transaction?.contactNumber?.isNotEmpty ?? false)
                              ? widget.transaction!.contactNumber! : '—',
                                // Use the originPort variable here
                                style: AppTextStyles.subtitle.copyWith(
                                  color: mainColor,
                                ),
                              ),
                              Text(
                                "Contact Number",
                                style: AppTextStyles.caption.copyWith(
                                  color: mainColor,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ), // ⬅️ Added progress indicator above content
                Container(
                  // color: Colors.green[500], // Set background color for this section
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
              
                  child: Column( // Use a Column to arrange the widgets vertically
                    crossAxisAlignment: CrossAxisAlignment.start, // Align text to the left
                    children: [
                      Row(
                        children: [
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.circle_rounded,
                            color: mainColor,
                            size: 15,
                          ),
                          const SizedBox(width: 20), // Space between icon and text
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Space between label and value
                              Text(
                                (widget.transaction?.freightBookingNumber?.isNotEmpty ?? false)
                                ? widget.transaction!.freightBookingNumber! : '—',
                                style: AppTextStyles.subtitle.copyWith(
                                  color: mainColor,
                                ),
                              ),
                              Text(
                                "Freight Booking Number",
                                style: AppTextStyles.caption.copyWith(
                                  color: mainColor,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.circle_rounded,
                            color: mainColor,
                            size: 15,
                          ),
                          const SizedBox(width: 20), // Space between icon and text
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Space between label and value
                              Text(
                                (widget.transaction?.freightBlNumber?.isNotEmpty ?? false)
                                ? widget.transaction!.freightBlNumber! : '—',
                                style: AppTextStyles.subtitle.copyWith(
                                  color: mainColor,
                                ),
                              ),
                              Text(
                                "Bill of Lading Number",
                                style: AppTextStyles.caption.copyWith(
                                  color: mainColor,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.circle_rounded,
                            color: mainColor,
                            size: 15,
                          ),
                          const SizedBox(width: 20), // Space between icon and text
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Space between label and value
                              Text(
                              (widget.transaction?.containerNumber?.isNotEmpty ?? false)
                              ? widget.transaction!.containerNumber! : '—',
                                // Use the originPort variable here
                                style: AppTextStyles.subtitle.copyWith(
                                  color: mainColor,
                                ),
                              ),
                              Text(
                                "Container Number",
                                style: AppTextStyles.caption.copyWith(
                                  color: mainColor,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.circle_rounded,
                            color: mainColor,
                            size: 15,
                          ),
                          const SizedBox(width: 20), // Space between icon and text
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Space between label and value
                              Text(
                              (widget.transaction?.sealNumber?.isNotEmpty ?? false)
                                ? widget.transaction!.sealNumber!
                                : '—',
                                // Use the originPort variable here
                                style: AppTextStyles.subtitle.copyWith(
                                  color: mainColor,
                                ),
                              ),
                              Text(
                                "Container Seal Number",
                                style: AppTextStyles.caption.copyWith(
                                  color: mainColor,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
        ),
        bottomNavigationBar: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if(!showButton)
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
                            builder: (context) => ScheduleScreen(uid: widget.uid, transaction: widget.transaction),
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
      )
    );
   
  }

   /// Progress Indicator Row
  Widget progressRow(int currentStep ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        buildStep("Delivery Log", currentStep > 1 ? mainColor : Colors.grey, currentStep == 1), // Active step
        buildConnector(currentStep > 1 ? Colors.green : Colors.grey),
        buildStep("Schedule", currentStep > 2 ? mainColor : Colors.grey, currentStep == 2),
        buildConnector(currentStep > 2 ? Colors.green : Colors.grey),
        buildStep("Confirmation", currentStep == 3 ? mainColor : Colors.grey, currentStep == 3),
      ],
    );
  }

  /// Single Progress Step Widget
  Widget buildStep(String label, Color color, bool isCurrent) {
    return Column(
      children: [
        CircleAvatar(
          radius: 10,
          backgroundColor: isCurrent ? mainColor : Colors.grey,
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
            color: isCurrent ? mainColor : Colors.grey
          )
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
