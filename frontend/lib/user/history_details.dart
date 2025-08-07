// ignore_for_file: unused_import, avoid_print

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

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

  int? _expandedTabIndex;



  List<String> get tabTitles {
    final type = widget.transaction?.dispatchType;
    final title = type == 'dt' ? 'Consignee Info' : 'Shipper Info';
   
      return [title, 'Proof of Delivery'];

      
  }

  @override
  void initState() {
    super.initState();
    uid = widget.uid; // Initialize uid
    _expandedTabIndex = 0; // Default to the first tab
  }

  String getNullableValue(String? value, {String fallback = ''}) {
    return value ?? fallback;
  }
  Map<String, MilestoneHistoryModel?> getPickupAndDeliverySchedule(Transaction? transaction) {
    final dispatchType = transaction!.dispatchType;
    final history = transaction.history;
    final serviceType = transaction.serviceType;
    final dispatchId = transaction.id;
    final requestNumber = transaction.requestNumber;

    final fclPrefixes = {
      'ot': {
        'Full Container Load': {
          'de': {
            'delivery': 'TEOT',
            'pickup': 'TYOT'
          },
          'pl': {
            'delivery': 'CLOT',
            'pickup': 'TLOT'
          },
        },
        'Less-Than-Container Load': {
          'pl': {
            'delivery': 'LCLOT',
            'pickup': 'LTEOT'
          },
        },
      },
      'dt': {
        'Full Container Load': {
          'dl': {
            'delivery': 'CLDT',
            'pickup': 'GYDT'
          },
          'pe': {
            'delivery': 'CYDT',
            'pickup': 'GLDT'
          },
        },
        'Less-Than-Container Load': {
          'pl': {
            'delivery': 'LCLOT',
            'pickup': 'LTEOT'
          },
        }
      }
    };

    final fclCodeMap = {
      'de': transaction.deRequestNumber,
      'pl': transaction.plRequestNumber,
      'dl': transaction.dlRequestNumber,
      'pe': transaction.peRequestNumber,
    };

    String? matchingLegs;
    for (final entry in fclCodeMap.entries) {
      if (entry.value !=null && entry.value == requestNumber) {
        matchingLegs = entry.key;
        break;
      }
    }

    print("Matching Leg for $requestNumber: $matchingLegs");

    if(matchingLegs != null) {
      final fclMap = fclPrefixes[dispatchType]?[serviceType]?[matchingLegs];
      final pickupFcl = fclMap?['pickup'];
      final deliveryFcl = fclMap?['delivery'];

      MilestoneHistoryModel? pickupSchedule;
      MilestoneHistoryModel? deliverySchedule;

      if(pickupFcl != null) {
        pickupSchedule = history.firstWhere(
          (h) => 
            h.fclCode.trim().toUpperCase() == pickupFcl.toUpperCase() &&
            h.dispatchId == dispatchId.toString() &&
            h.serviceType == serviceType,
          orElse: () => const MilestoneHistoryModel(
            id: -1,
            dispatchId: '',
            dispatchType: '',
            fclCode: '',
            scheduledDatetime: '',
            serviceType: '',
            actualDatetime: ''
          ),
        );
        if(pickupSchedule.id == -1) pickupSchedule  = null;
      }

      if(deliveryFcl != null) {
        deliverySchedule = history.firstWhere(
          (h) => 
            h.fclCode.trim().toUpperCase() == deliveryFcl.toUpperCase() &&
            h.dispatchId == dispatchId.toString() &&
            h.serviceType == serviceType,
          orElse: () => const MilestoneHistoryModel(
            id: -1,
            dispatchId: '',
            dispatchType: '',
            fclCode: '',
            scheduledDatetime: '',
            serviceType: '',
            actualDatetime: ''
          ),
        );
        if(deliverySchedule.id == -1) deliverySchedule  = null;
      }
      return {
        'pickup': pickupSchedule,
        'delivery': deliverySchedule,
      };
    }
    return {
      'pickup': null,
      'delivery': null,
    };


   }


    String formatDateTime(String? dateString) {
      if (dateString == null || dateString.isEmpty) return "N/A"; // Handle null values
      
      try {
        DateTime dateTime = DateTime.parse(dateString); // Convert string to DateTime
        DateTime adjustedTime = dateTime.add(const Duration(hours:8));
        return DateFormat('dd MMM, yyyy  - h:mm a').format(adjustedTime); // Format date-time
      } catch (e) {
        return "Invalid Date"; // Handle errors gracefully
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
          padding: const EdgeInsets.all(10.0),
          child: ListView(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 35, width: 20), // Space for icon or alignment
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.transaction?.originAddress ?? '—',
                          style: AppTextStyles.body.copyWith(
                            color: mainColor,
                            fontSize: 15,
                            fontWeight: FontWeight.bold
                          ),
                          softWrap: true,
                          maxLines: 2, // Optional: limit to 2 lines
                          overflow: TextOverflow.ellipsis, // Optional: fade or clip if it overflows
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              

              Container(
                padding: const EdgeInsets.all(14.0), // Add padding inside the container
                
                decoration: BoxDecoration(
                  color: (widget.transaction?.requestStatus == 'Completed') ? const Color.fromARGB(255, 45, 144,111) : (widget.transaction?.stageId == 'Cancelled') ?  Colors.red[500] : Colors.grey, // Background color based on status
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
                             widget.transaction?.bookingRefNo ?? '—',
                              style: AppTextStyles.subtitle.copyWith(
                                color: Colors.white,
                              ),
                            ),
                             Text(
                              "Dispatch Reference Number",
                              style: AppTextStyles.caption.copyWith(
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
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
                                (widget.transaction?.requestStatus == 'Completed' || widget.transaction?.stageId == 'Completed')
                                  ? formatDateTime(widget.transaction?.completedTime)
                                  : widget.transaction?.stageId == 'Cancelled'
                                    ? formatDateTime(widget.transaction?.writeDate)
                                    : '—',
                                
                                style: AppTextStyles.subtitle.copyWith(
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                               (widget.transaction?.requestStatus == 'Completed' || widget.transaction?.stageId == 'Completed')
                                              ? 'Completed Date'
                                              : widget.transaction?.stageId == 'Cancelled'
                                                ? 'Cancelled Date'
                                                : '—',
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
              (widget.transaction?.stageId == "Cancelled") ?
               Center(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                    child: Text(
                      'This booking was cancelled.',
                      style: AppTextStyles.subtitle,
                      textAlign: TextAlign.center,
                    ),
                  )
                )
                : Column(
                  children: [
                    Row(
                        children: List.generate(tabTitles.length, (index) {
                    final bool isSelected = _expandedTabIndex == index;
                    

                    final Color tabColor = isSelected ? mainColor : bgColor;


                    return Expanded(
                      child: GestureDetector(
                        onTap: () {
                          // WidgetsBinding.instance.addPostFrameCallback((_) {
                            setState(() {
                              if(_expandedTabIndex == index) {
                                _expandedTabIndex = null;
                              } else {
                                _expandedTabIndex = index;
                              }
                            });
                          // });
                          
                        },
                        child: Container (
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            border: Border (
                              bottom: BorderSide(
                                color: tabColor,
                                width: 2,
                              ),
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            tabTitles[index],
                            style: AppTextStyles.body.copyWith(
                              color:  tabColor,
                              fontWeight: FontWeight.bold
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 16),
            
                if (_expandedTabIndex == 0) _buildFreightTab(),
                if (_expandedTabIndex == 1) _buildShipConsTab(),

                const SizedBox(height: 20),
              ],
                    )
                  ]
                  
   
      
              
          ),
          
        ),
        
      ),
      
      // bottomNavigationBar: const NavigationMenu(),
    );
  } 

  Widget _buildShipConsTab (){

    final isDT = widget.transaction?.dispatchType == 'dt';
    final scheduleMap = getPickupAndDeliverySchedule(widget.transaction!);
    final pickup = scheduleMap['pickup'];
    final delivery = scheduleMap['delivery'];

 print('pickup actual datetime: ${pickup?.actualDatetime}');

   

    Uint8List? decodeBase64(String? data) {
      if(data == null || data.isEmpty)  return null;
      try{
      
        return base64Decode(data.trim());
      } catch (e) {
        debugPrint('Base64 error: $e');
        return null;
      }
    }

    String? yardSignBase64;
    String? yardProofBase64;
    String? signBase64;
    String? proofBase64;
    String? name;
    String? yardName;
    String? yardactualdate;
    String? actualdate;
  

    if (isDT) {
      if (widget.transaction?.requestNumber == widget.transaction?.dlRequestNumber) {
        yardSignBase64 = widget.transaction?.plSign;
        yardProofBase64 = widget.transaction?.plProof;
        signBase64 = widget.transaction?.dlSign;
        proofBase64 = widget.transaction?.dlProof;
        yardName =  widget.transaction?.peReleasedBy;
        name = widget.transaction?.deReleasedBy;
        yardactualdate = formatDateTime(pickup?.actualDatetime);
        actualdate = formatDateTime(delivery?.actualDatetime);
      } else if (widget.transaction?.requestNumber == widget.transaction?.peRequestNumber) {
        yardSignBase64 = widget.transaction?.deSign;
        yardProofBase64 = widget.transaction?.deProof;
        signBase64 = widget.transaction?.peSign;
        proofBase64 = widget.transaction?.peProof;
        yardName =  widget.transaction?.plReceivedBy;
        name = widget.transaction?.dlReceivedBy;
        yardactualdate = formatDateTime(pickup?.actualDatetime);
        actualdate = formatDateTime(delivery?.actualDatetime);
      }
    } else {
      if (widget.transaction?.requestNumber == widget.transaction?.deRequestNumber) {
        yardSignBase64 = widget.transaction?.peSign;
        yardProofBase64 = widget.transaction?.peProof;
        signBase64 = widget.transaction?.dlSign;
        proofBase64 = widget.transaction?.dlProof;
        yardName =  widget.transaction?.peReleasedBy;
        name = widget.transaction?.deReleasedBy;
        yardactualdate = formatDateTime(pickup?.actualDatetime);
        actualdate = formatDateTime(delivery?.actualDatetime);
      } else if (widget.transaction?.requestNumber == widget.transaction?.plRequestNumber) {
        yardSignBase64 = widget.transaction?.dlSign;
        yardProofBase64 = widget.transaction?.dlProof;
        signBase64 = widget.transaction?.peSign;
        proofBase64 = widget.transaction?.peProof;
        yardName =  widget.transaction?.plReceivedBy;
        name = widget.transaction?.dlReceivedBy;
        yardactualdate = formatDateTime(pickup?.actualDatetime);
        actualdate = formatDateTime(delivery?.actualDatetime);
      }
    }

    final yardSignBytes = decodeBase64(yardSignBase64);
    final yardProofBytes = decodeBase64(yardProofBase64);

    final signBytes = decodeBase64(signBase64);
    final proofBytes = decodeBase64(proofBase64);


    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
        'Yard/Port',
          style: AppTextStyles.body.copyWith(
            color: mainColor,
            fontWeight: FontWeight.bold, 
          )
        ),
        const SizedBox(height: 20),
        Text(
        'Proof of Delivery',
          style: AppTextStyles.body.copyWith(
            color: mainColor,
          )
        ),
        const SizedBox(height: 20),
        if(yardProofBytes != null)
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => FullScreenImage(imageBytes: yardProofBytes),
                ),
              );
            },
            child: Column (
              children: [
                Image.memory(yardProofBytes, height:200),
                const SizedBox(height: 20),
                Text(
                  'Released by:  ${yardName ?? '—'}',
                  style: AppTextStyles.body.copyWith(
                    color: mainColor,
                  )
                ),
              ],
            ),
            
          ),

        const SizedBox(height: 20),
        Text(
        'Signature',
          style: AppTextStyles.body.copyWith(
            color: mainColor,
          )
        ),
        const SizedBox(height: 20),

        if(yardSignBytes != null)
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => FullScreenImage(imageBytes: yardSignBytes),
                ),
              );
            },
            child: Image.memory(yardSignBytes, height: 100),
          ),
          const SizedBox(height: 20),
         Text(
          'Actual Date and Time:  ${yardactualdate ?? '—'}',
            style: AppTextStyles.body.copyWith(
              color: mainColor,
            )
          ),
        const SizedBox(height: 20),
        const Divider(
          color: Colors.grey,
          thickness: 1,
        ),

        // SHIPPER CONSIGNEE
          Text(
         isDT ? 'Consignee' : 'Shipper',
          style: AppTextStyles.body.copyWith(
            color: mainColor,
            fontWeight: FontWeight.bold, 
          )
        ),
        const SizedBox(height: 20),
        Text(
          
        'Proof of Delivery',
          style: AppTextStyles.body.copyWith(
            color: mainColor,
          )
        ),
        const SizedBox(height: 20),
        if(proofBytes != null)
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => FullScreenImage(imageBytes: proofBytes),
                ),
              );
            },
            child: Column (
              children: [
                Image.memory(proofBytes, height:200),
                const SizedBox(height: 20),
                Text(
                  'Released by: ${name ?? '—'} ',
                  style: AppTextStyles.body.copyWith(
                    color: mainColor,
                  )
                ),
              ],
            ),
            
          ),

        const SizedBox(height: 20),
        Text(
        'Signature',
          style: AppTextStyles.body.copyWith(
            color: mainColor,
          )
        ),
        const SizedBox(height: 20),

        if(signBytes != null)
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => FullScreenImage(imageBytes: signBytes),
                ),
              );
            },
            child: Image.memory(signBytes, height: 100),
          ),
          const SizedBox(height: 20),
         Text(
          'Actual Date and Time: ${actualdate ?? '—'}',
            style: AppTextStyles.body.copyWith(
              color: mainColor,
            )
          ),
       
      ],

      
    );
  }

  Widget  _buildFreightTab(){
    return  Column( // Use a Column to arrange the widgets vertically
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
    );
  }
}

class FullScreenImage extends StatelessWidget{
  final Uint8List imageBytes;

  const FullScreenImage({super.key, required this.imageBytes});

  @override
  Widget build(BuildContext context) {
    return Scaffold (
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
      ),
      body: Center (
        child: InteractiveViewer(child: Image.memory(imageBytes)),
      )
    );
  }
}
