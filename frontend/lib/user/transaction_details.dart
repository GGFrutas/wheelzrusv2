// ignore_for_file: avoid_print, unused_import

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/models/reject_reason_model.dart' show RejectionReason;
import 'package:frontend/models/transaction_model.dart'; // Import your model file
import 'package:frontend/notifiers/auth_notifier.dart';
import 'package:frontend/notifiers/navigation_notifier.dart';
import 'package:frontend/provider/accepted_transaction.dart' as accepted_transaction;
import 'package:frontend/provider/accepted_transaction.dart' as transaction_list;
import 'package:frontend/provider/reject_provider.dart';
import 'package:frontend/provider/transaction_provider.dart';
import 'package:frontend/screen/homepage_screen.dart';
import 'package:frontend/screen/navigation_menu.dart';
import 'package:frontend/theme/colors.dart';
import 'package:frontend/theme/text_styles.dart';
import 'package:frontend/user/detailed_details.dart';
import 'package:frontend/user/proof_of_delivery_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:http/http.dart' as ref;
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';
import 'package:intl/intl.dart';




class TransactionDetails extends ConsumerStatefulWidget {
  final Transaction? transaction; // Keep it nullable
  final String uid; // Add a field for uid

  // Constructor to accept the nullable Transaction object
  TransactionDetails({super.key, required this.transaction, required int id, String? requestNumber, required this.uid});

  // Helper function to handle null values and provide fallback
  String getNullableValue(String? value, {String fallback = ''}) {
    return value ?? fallback; // If value is null, return fallback
  }
  



  @override
  ConsumerState<TransactionDetails> createState() => _TransactionDetailsState();
}

  
class _TransactionDetailsState extends ConsumerState<TransactionDetails> {
  final Map<String, bool> _loadingStates = {};

  late MapController mapController;
  Location location = Location();
  bool _isMapReady = false;
  PermissionStatus? _permissionGranted;
  bool _serviceEnabled = false;
  LocationData? _locationData;

  

  @override
  void initState() {
    super.initState();
    mapController = MapController();
    initLocation();
  }

  initLocation() async {
    _serviceEnabled = await location.serviceEnabled();
    if (!_serviceEnabled) {
      _serviceEnabled = await location.requestService();
      if (!_serviceEnabled) return;
    }

    _permissionGranted = await location.hasPermission();
    if (_permissionGranted == PermissionStatus.denied) {
      _permissionGranted = await location.requestPermission();
      if (_permissionGranted != PermissionStatus.granted) return;
    }

    _locationData = await location.getLocation();

    if (_isMapReady) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            mapController.move(
              LatLng(
                _locationData?.latitude ?? 0,
                _locationData?.longitude ?? 0,
              ),
              16,
            );
          });
        }
      });
    }
  }

  String getNullableValue(String? value, {String fallback = ''}) {
    return value ?? fallback;
  }

  String formatDateTime(String? dateString) {
    if (dateString == null || dateString.isEmpty) return "N/A"; // Handle null values
    
    try {
      DateTime dateTime = DateTime.parse(dateString); // Convert string to DateTime
       return DateFormat('MMMM d, yyyy - h:mm a').format(dateTime); // Format date-time
    } catch (e) {
      return "Invalid Date"; // Handle errors gracefully
    }
  } 


  
 
  @override
  Widget build(BuildContext context) {
    // If transaction is null, display a fallback message
    return Consumer(
      builder: (context, ref, child) {
        
        if (widget.transaction == null) {
          return Scaffold(
            appBar: AppBar(
              title: const Text("Booking Details"),
            ),
            body: const Center(
              child: Text("No transaction details available."),
            ),
            
          );
        }
      
       // If transaction is not null, display its details
        return Scaffold(
          appBar: AppBar(
            iconTheme: const IconThemeData(color: mainColor),
          ),
          
          body: Padding(
            padding: const EdgeInsets.all(14.0),
            child: ListView( // Use ListView to allow scrolling
              children: [
                Container(
                  // color: Colors.green[500], // Set background color for this section
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    " ${getNullableValue(widget.transaction?.name).toUpperCase()}", // Section Title
                    style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.bold,
                      color: mainColor,
                    ),
                  ),
                ),
                const SizedBox(height: 12), // Add some space between sections
                Container(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center, // Align top of icon and text
                    children: [
                      const Icon(
                        Icons.check_circle,
                        color: mainColor,
                        size: 30,
                      ),
                      const SizedBox(width: 8), // Space between icon and text
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Space between label and value
                          
                          Text(
                            "Request Number",
                            style: AppTextStyles.caption.copyWith(
                              fontSize: 12,
                              color: mainColor,
                            ),
                          ),
                          Text(
                            widget.transaction?.requestNumber ?? '',
                            style: AppTextStyles.subtitle.copyWith(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: mainColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(12.0), // Add padding inside the container
                  child: Column( // Use a Column to arrange the widgets vertically
                    crossAxisAlignment: CrossAxisAlignment.start, // Align text to the left
                    children: [
                      //  Placeholder for the Map
                      Container(
                        height: 250, // Height of the map container
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey[600], // Placeholder color
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: FlutterMap(
                          mapController: mapController,
                          options: MapOptions(
                            initialZoom: 5,
                            onMapReady: () {
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                if (mounted) {
                                  setState(() {
                                    _isMapReady = true;
                                  });
                                }
                              });
                            },
                          ),
                          children: [
                            TileLayer(
                              urlTemplate:
                                  'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                              userAgentPackageName:
                                  'dev.fleaflet.flutter_map.example',
                            ),
                            MarkerLayer(
                              markers: [
                                Marker(
                                  point: LatLng(
                                    _locationData?.latitude ?? 10.3157,
                                    _locationData?.longitude ?? 123.8854,
                                  ),
                                  width: 60,
                                  height: 60,
                                  alignment: Alignment.centerLeft,
                                  child: const Icon(
                                    Icons.location_pin,
                                    size: 60,
                                    color: Colors.red,
                                  ),
                                ),
                                const Marker(
                                  point: LatLng(10.3157, 123.8854),
                                  width: 60,
                                  height: 60,
                                  alignment: Alignment.centerLeft,
                                  child: Icon(
                                    Icons.location_pin,
                                    size: 60,
                                    color: Colors.green,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center, // Align top of icon and text
                          children: [
                            const Icon(
                              Icons.location_on,
                              color: mainColor,
                              size: 30,
                            ),
                            const SizedBox(width: 8), // Space between icon and text
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Space between label and value
                                Text(
                                  widget.transaction?.destination ?? '',
                                  style: AppTextStyles.subtitle.copyWith(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: mainColor,
                                  ),
                                ),
                               Text(
                                  "Pick-up Address",
                                  style: AppTextStyles.caption.copyWith(
                                    color: mainColor,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          const SizedBox(width: 21), // Match left padding with location icon
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.center, // Center dots with the location pin tip
                            children: List.generate(3, (_) => const Padding(
                              padding: EdgeInsets.symmetric(vertical: 8.0), // Adjust spacing
                              child: Icon(
                                Icons.circle_rounded,
                                color: mainColor,
                                size: 10,
                              ),
                            )),
                          ),
                        ],
                      ),
                      
                      // const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(7.9),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center, // Align top of icon and text
                          children: [
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.circle_rounded,
                              color: mainColor,
                              size: 20,
                            ),
                            const SizedBox(width: 8), // Space between icon and text
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Space between label and value
                                Text(
                                  widget.transaction?.origin ?? '',
                                  style: AppTextStyles.subtitle.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: mainColor,
                                  )
                                ),
                                Text(
                                  "Delivery Address",
                                  style: AppTextStyles.caption.copyWith(
                                    color: mainColor,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      Container(
                        padding: const EdgeInsets.all(7.9),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center, // Align top of icon and text
                          children: [
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.calendar_today_outlined,
                              color: mainColor,
                              size: 24,
                            ),
                            const SizedBox(width: 8), // Space between icon and text
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Space between label and value
                                Text(
                                  formatDateTime(widget.transaction?.arrivalDate),
                                  style: AppTextStyles.subtitle.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: mainColor,
                                  )
                                ),
                                Text(
                                  "Arrival Date",
                                  style: AppTextStyles.caption.copyWith(
                                    color: mainColor,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 50),
                    ],
                  ),
                ),
              ],
            ),
            
          ),
          bottomSheet: Container(
            padding: const EdgeInsets.all(10.0),
            child: SizedBox(
              width: double.infinity, // Make the button full width
              child: ElevatedButton(
              onPressed: () async {
                if (widget.transaction?.requestStatus == 'Ongoing' || widget.transaction?.requestStatus == "Accepted") {
                  
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DetailedDetailScreen(uid: widget.uid, transaction: widget.transaction),
                    ),
                  );
                  // print("SUCCESS");
                } else {
                
                  final acceptedTransactionNotifier = ref.read(accepted_transaction.acceptedTransactionProvider.notifier);

                    final isAccepted = acceptedTransactionNotifier.isAccepted(
                      widget.transaction!.id, 
                      widget.transaction!.requestNumber.toString(),
                    );

                    // If not accepted, update the status and add it to accepted transactions
                  if (isAccepted) {
                      _loadingStates[widget.transaction!.requestNumber.toString()] = false;
                    return;
                  }
                  acceptedTransactionNotifier.updateStatus(
                    widget.transaction!.id.toString(),
                    widget.transaction!.requestNumber.toString(),
                    'Accepted', ref, context// Pass both ID and RequestNumber
                  );
                    acceptedTransactionNotifier.addProduct(widget.transaction!); //Add to accepted 
                      // transaction?.removeWhere((t) => t.id == transaction?.id);
                    // ref.read(filteredItemsProvider.notifier).removeTransaction(transaction?);
                    // ref.refresh(acceptedTransactionProvider);
                  

                  // Find and display the updated transaction
                    final updatedState = ref.read(transaction_list.acceptedTransactionProvider);
                    final updatedTransaction = updatedState.firstWhere(
                      (transaction) => transaction.id == transaction.id,
                      orElse: () => widget.transaction!, // Return the original if not found
                    );

                    //Print the updated status
                  print('ID: ${widget.transaction?.id}');
                  print('Request Number: ${updatedTransaction.requestNumber}');
                  print('Updated Status: ${updatedTransaction.requestStatus}');
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: mainColor,
                padding: const EdgeInsets.symmetric(
                  horizontal: 80,
                  vertical: 20,
                ),
                disabledForegroundColor: mainColor,
                disabledBackgroundColor: mainColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30.0),
                ),
              ),
              child: Text(
                widget.transaction?.requestStatus == 'Accepted' || widget.transaction?.requestStatus == 'Ongoing'
                              ? 'View Booking' // New label for accepted transactions
                              : 'Accept Booking', 
                style: AppTextStyles.body.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center, // Ensure the text is centered
                overflow: TextOverflow.ellipsis, // Handle overflow if needed
                maxLines: 1,
              ),
            ),
            ),
          ),
          
          
        );
      },
    );
  }
}