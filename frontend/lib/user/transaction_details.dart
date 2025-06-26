// ignore_for_file: avoid_print, unused_import

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/models/reject_reason_model.dart' show RejectionReason;
import 'package:frontend/models/transaction_model.dart'; // Import your model file
import 'package:frontend/notifiers/auth_notifier.dart';
import 'package:frontend/notifiers/navigation_notifier.dart';
import 'package:frontend/provider/accepted_transaction.dart' as accepted_transaction;
import 'package:frontend/provider/accepted_transaction.dart' as transaction_list;
import 'package:frontend/provider/base_url_provider.dart';
import 'package:frontend/provider/reject_provider.dart';
import 'package:frontend/provider/transaction_list_notifier.dart';
import 'package:frontend/provider/transaction_provider.dart';
import 'package:frontend/screen/homepage_screen.dart';
import 'package:frontend/screen/navigation_menu.dart';
import 'package:frontend/theme/colors.dart';
import 'package:frontend/theme/text_styles.dart';
import 'package:frontend/user/detailed_details.dart';
import 'package:frontend/user/history_screen.dart';
import 'package:frontend/user/homepage_screen.dart';
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

  int? _expandedTabIndex;

  List<String> get tabTitles {
    final type = widget.transaction?.dispatchType;
    return [
      'Freight',
      type == 'dt' ? 'Consignee' : 'Shipper',
    ];
  }

  

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
      DateTime dateTime = DateTime.parse("${dateString}Z").toLocal();
       // Convert string to DateTime
       return DateFormat('MMMM d, yyyy - h:mm a').format(dateTime); // Format date-time
    } catch (e) {
      return "Invalid Date"; // Handle errors gracefully
    }
  } 


  @override
  Widget build(BuildContext context) {
    // If transaction is null, display a fallback message
    final showTabs = !(widget.transaction?.requestStatus == "Pending" || widget.transaction?.requestStatus == "Accepted");
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
                Padding(
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
                if (showTabs) ...[
                  Row(
                    children: List.generate(tabTitles.length, (index) {
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
                                  color: _expandedTabIndex == index ? mainColor : bgColor,
                                  width: 2,
                                ),
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              tabTitles[index],
                              style: AppTextStyles.body.copyWith(
                                color:  _expandedTabIndex == index ? mainColor : bgColor,
                                fontWeight: FontWeight.bold
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 16),
                  if(_expandedTabIndex == 0) _buildFreightTab(),
                  if(_expandedTabIndex == 1) _buildShipConsTab(),

                ],
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
                            Expanded (
                              child: Column(
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
                            )
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
                            Expanded (
                              child: Column(
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
                            )
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
                                  widget.transaction?.dispatchType == 'ot' ? formatDateTime(widget.transaction?.departureDate)
                                  : formatDateTime(widget.transaction?.arrivalDate),
                                  style: AppTextStyles.subtitle.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: mainColor,
                                  )
                                ),
                                Text(
                                  widget.transaction?.dispatchType == 'ot' ? "Departure Date" 
                                  :  "Arrival Date",
                                  style: AppTextStyles.caption.copyWith(
                                    color: mainColor,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
          ),
          bottomNavigationBar: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column (
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: double.infinity, // Make the button full width
                  child: ElevatedButton(
                  onPressed: () async {
                    if (widget.transaction?.requestStatus != 'Pending') {
                      
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

                      final success = await acceptedTransactionNotifier.updateStatus(
                        widget.transaction!.id.toString(),
                        widget.transaction!.requestNumber.toString(),
                        'Accepted', // Update status to 'Accepted'
                        ref,
                        context,
                      );

                      final updatedState = ref.read(transaction_list.acceptedTransactionProvider);

                      // final updatedTransaction = updatedState.firstWhere(
                      //   (transaction) => transaction.id == transaction.id,
                      //   orElse: () => widget.transaction!, // Return the original if not found
                      // );
                      final updatedTransaction = updatedState.firstWhere(
                        (t) =>
                            t.id == widget.transaction!.id &&
                            t.requestNumber == widget.transaction!.requestNumber,
                        orElse: () => widget.transaction!, // fallback if not founds
                      );
                     
                    
                      print('✅ Update Status: ${updatedTransaction.requestStatus}'); // Should now be 'Accepted'

                      if (success) {
                        acceptedTransactionNotifier.addProduct(updatedTransaction); //Add to accepted 
                        showDialog(
                          context:context,
                          barrierDismissible: false,
                          builder: (context) {
                            return const Center (
                              child: CircularProgressIndicator(),
                            );
                          },
                        );

                        await Future.delayed(const Duration(seconds: 2));
                        Navigator.of(context).pop(); // Close the loading dialog

                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (_) => PopScope(
                          canPop: false, // Prevent default pop behavior
                          onPopInvoked: (didPop) {
                            if (!didPop) {
                              ref.invalidate(pendingTransactionProvider);
                              ref.invalidate(acceptedTransactionProvider);
                              ref.invalidate(bookingProvider);
                              ref.invalidate(filteredItemsProvider);
                              ref.read(navigationNotifierProvider.notifier).setSelectedIndex(0);
                              // Navigate to home if system back button is pressed
                              Navigator.of(context).popUntil((route) => route.isFirst);
                            }
                          },
                          child: Dialog(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            backgroundColor: Colors.white,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Booking has been accepted',
                                    style: AppTextStyles.body.copyWith(
                                      color: Colors.black87
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 16),
                                  const Icon (
                                    Icons.check_circle,
                                    color: mainColor,
                                    size: 100
                                  ),
                                  const SizedBox(height: 24),
                                  SizedBox(
                                    width: 200,
                                    child:ElevatedButton(
                                      onPressed: () {
                                        Navigator.pop(context);
                                        // Navigator.of(context).popUntil((route) => route.isFirst);
                                        ref.invalidate(pendingTransactionProvider);
                                        ref.invalidate(acceptedTransactionProvider);
                                        ref.invalidate(bookingProvider);
                                        ref.invalidate(filteredItemsProvider);
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => DetailedDetailScreen(uid: widget.uid, transaction: updatedTransaction),
                                          ),
                                        );
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: mainColor,
                                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(25),
                                        ),
                                      ),
                                      child: Text("Continue", style: AppTextStyles.body.copyWith(color: Colors.white)),
                                    ),
                                  )
                                  
                                ],
                              ),
                            ),
                          ),
                          ),
                        );
                      }
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
                    widget.transaction?.requestStatus != 'Pending'
                    // widget.transaction?.requestStatus == 'Accepted' || widget.transaction?.requestStatus == 'Ongoing'
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
                const SizedBox(height: 10), // Add some space between buttons
                if (widget.transaction?.requestStatus == "Pending") // Show only if not accepted
                SizedBox(
                  width: double.infinity, // Make the button full width
                  child: OutlinedButton(
                    onPressed: () {
                      _showModal(context,ref);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30.0),
                      ),
                    ),
                    child: Text(
                      'Decline Booking',
                      style: AppTextStyles.body.copyWith(
                       
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center, // Ensure the text is centered
                      overflow: TextOverflow.ellipsis, // Handle overflow if needed
                      maxLines: 1,
                    ),
                  ),
                ),
              ],
            ),
            
          ),
          
          // bottomNavigationBar: const NavigationMenu(), // Show navigation menu only if it's the home screen

        );
      },
    );
  }

  Widget _buildFreightTab (){

    final isDT = widget.transaction?.dispatchType == 'dt';
   

    Uint8List? _decodeBase64(String? data) {
      if(data == null || data.isEmpty)  return null;
      try{
      
        return base64Decode(data.trim());
      } catch (e) {
        debugPrint('Base64 error: $e');
        return null;
      }
    }

    final signBytes = isDT ? _decodeBase64(widget.transaction?.plSign) : _decodeBase64(widget.transaction?.peSign);
    final proofBytes = isDT ? _decodeBase64(widget.transaction?.plProof) : _decodeBase64(widget.transaction?.peProof);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
        'Freight Documents',
          style: AppTextStyles.body.copyWith(
            color: mainColor,
          )
        ),
        const SizedBox(height: 10),
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
            child: Image.memory(proofBytes, height: 100),
          ),

        const SizedBox(height: 10),

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

          
       
      ],
    );
  }

  Widget _buildShipConsTab (){
    final isDT = widget.transaction?.dispatchType == 'dt';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isDT ? 'Consignee Documents' : 'Shipper Documents',
          style: AppTextStyles.body.copyWith(
            color: mainColor,
          )
        ),
       
      ],
    );
  }


  void _showModal(BuildContext context, WidgetRef ref) {
    TextEditingController controller = TextEditingController();
    final rootContext = context;
    showDialog(
      context: rootContext,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          insetPadding: const EdgeInsets.all(20.0),
          child: LayoutBuilder(
            builder:(context, constraints) {
              return Stack (
                children: [
                  SingleChildScrollView(
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.of(context).viewInsets.bottom, // Add padding for keyboard
                      top: 20.0, // Add top padding for better appearance
                      left: 20.0,
                      right: 20.0,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min, // Use min size to fit content
                      children: [
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('REJECT BOOKING', style: AppTextStyles.subtitle.copyWith(color: mainColor), textAlign: TextAlign.center),
                            const SizedBox(height: 8),
                            const Icon(Icons.sentiment_dissatisfied, color: mainColor, size: 75), // Cancel icon
                          ],
                        ),
                        Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Text('Please let us know your reason for cancelling or rejecting this booking to help us improve our services.',
                          style: AppTextStyles.caption.copyWith(color: Colors.black, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          Consumer(
                            builder: (context, ref, child) {
                              final rejectionReasonsAsync = ref.watch(rejectionReasonsProvider);
                              final selectedValue = ref.watch(selectedReasonsProvider);
                              return rejectionReasonsAsync.when(
                                data: (reasons) {
                                  return Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.grey, width: 1),
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                    child: DropdownButton<String>(
                                      isExpanded: true,
                                      value: selectedValue,
                                      hint: Text('Select Reason', style: AppTextStyles.body),
                                      underline: const SizedBox(), // Remove the underline
                                      onChanged: (String? newValue) {
                                        ref.read(selectedReasonsProvider.notifier).state = newValue;
                                      },
                                      items: reasons.map<DropdownMenuItem<String>>((RejectionReason reason) {
                                        return DropdownMenuItem<String>(
                                          value: reason.id.toString(), // Using the 'id' from the model
                                          child: Text(reason.name, style: AppTextStyles.body), // Using the 'name' from the model
                                        );
                                      }).toList(),
                                    ),
                                  );
                                  
                                },
                                  loading: () => const CircularProgressIndicator(),
                                error: (e, stackTrace) => Text('Error: $e'),
                              );
                            },
                          ),

                          const SizedBox(height: 10),
                          

                          // Text Area for feedback s
                          TextField(
                            controller: controller,
                            maxLines: 3,  // Multi-line text area
                            decoration: InputDecoration(
                              border: const OutlineInputBorder(),
                              hintText: 'Your feedback...',
                              hintStyle: AppTextStyles.body, // Use caption style for hint text
                            ),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () async {
                                final uid = ref.read(authNotifierProvider).uid;
                                final transactionId = widget.transaction!;
                                final baseUrl = ref.watch(baseUrlProvider);
                                // Handle Reject Action here (using _selectedValue and controller.text)
                                final selectedReason = ref.read(selectedReasonsProvider);
                                final feedback = controller.text;

                                if(selectedReason == null || selectedReason.isEmpty){
                                  showDialog(
                                    context: context,
                                    builder: (context) {
                                      return AlertDialog(
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                        title: Text (
                                          "No Reason Selected!",
                                          style: AppTextStyles.body.copyWith(color: Colors.red, fontWeight: FontWeight.bold),
                                          textAlign: TextAlign.center,
                                        ),
                                        content: Text (
                                          'Please select a reason before rejecting.',
                                          style: AppTextStyles.body,
                                          textAlign: TextAlign.center,
                                        ),
                                        actions: [
                                          Padding(
                                            padding: const EdgeInsets.only(bottom: 12.0),
                                            child: Center(
                                              child: SizedBox(
                                                width: 200,
                                                child: ElevatedButton(
                                                onPressed: () {
                                                  Navigator.of(context).pop();
                                                }, 
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.red,
                                                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(25),
                                                  ),
                                                ),
                                                child: Text(
                                                  "OK",
                                                  style: AppTextStyles.body.copyWith(
                                                    color: Colors.white,
                                                  )
                                                )
                                              ),
                                              )
                                            )
                                          )
                                        ],
                                      );
                                    }
                                  );
                                  return;
                                }

                                //Clear selection//
                                ref.read(selectedReasonsProvider.notifier).state = null;
                                controller.clear();

                                print('🟥 Rejecting Transaction');
                                print('🔹 UID: $uid');
                                print('🔹 Transaction ID: ${transactionId.id}');
                                print('🔹 Reason: $selectedReason');
                                print('🔹 Feedback: $feedback');

                                showDialog(
                                  context: context,
                                  barrierDismissible: false,
                                  builder:(context) {
                                    return const Center (
                                      child: CircularProgressIndicator(),
                                    );
                                  },
                                );

                                try{
                                  final password = ref.watch(authNotifierProvider).password ?? '';
                                  final login = ref.watch(authNotifierProvider).login ?? '';
                                  final response = await http.post(
                                    Uri.parse('$baseUrl/api/odoo/reject-booking'),
                                    headers:{
                                      'Content-Type': 'application/json',
                                      'Accept': 'application/json',
                                      'password': password,
                                      'login': login
                                    },
                                    body: jsonEncode({
                                      'uid': uid,
                                      'transaction_id': transactionId.id,
                                      'reason': selectedReason,
                                      'feedback': feedback
                                    }),
                                  );
                                  // Navigator.of(context, rootNavigator: true).pop(); // close loading
                                  print('Response Status Code: ${response.statusCode}');
                                
                                  if (response.statusCode == 200) {
                                    print("Rejection Successful");
                                    final rejectedTransactionNotifier = ref.read(accepted_transaction.acceptedTransactionProvider.notifier);
                                    rejectedTransactionNotifier.updateStatus(transactionId.id.toString(), transactionId.requestNumber.toString(),'Rejected',ref, context);

                                    await Future.delayed(const Duration(seconds: 1));
                                    final updated = await fetchTransactionStatus(ref,baseUrl, transactionId.id.toString());
                                    print('Updated Status: ${updated.requestStatus}');

                                    if(updated.requestStatus == "Rejected") {
                                      print('Rejection Successful');
                                      ref.read(selectedReasonsProvider.notifier).state = null; // Clear the selected reason
                                      controller.clear(); // Clear the text field

                                      print('🔁 Redirecting to HistoryScreen with UID: $uid');

                                      await Future.delayed(const Duration(seconds: 2));
                                      ref.invalidate(bookingProvider);
                                      ref.invalidate(filteredItemsProvider);
                                      Navigator.of(context, rootNavigator: true).popUntil((route) => route.isFirst);
                                      ref.read(navigationNotifierProvider.notifier).setSelectedIndex(2);
                                     

                                    } else {
                                      print('Rejection Failed');
                                      showDialog(
                                        context: context,
                                        builder: (context) {
                                          return AlertDialog(
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                            title: Text (
                                              "Rejection Failed!",
                                              style: AppTextStyles.body.copyWith(color: Colors.red, fontWeight: FontWeight.bold),
                                              textAlign: TextAlign.center,
                                            ),
                                            content: Text (
                                              'An error occurred while rejecting the booking. Please try again later.',
                                              style: AppTextStyles.body,
                                              textAlign: TextAlign.center,
                                            ),
                                            actions: [
                                              Padding(
                                                padding: const EdgeInsets.only(bottom: 12.0),
                                                child: Center(
                                                  child: SizedBox(
                                                    width: 200,
                                                    child: ElevatedButton(
                                                    onPressed: () {
                                                      Navigator.of(context).pop();
                                                    }, 
                                                    style: ElevatedButton.styleFrom(
                                                      backgroundColor: Colors.red,
                                                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                                                      shape: RoundedRectangleBorder(
                                                        borderRadius: BorderRadius.circular(25),
                                                      ),
                                                    ),
                                                    child: Text(
                                                      "OK",
                                                      style: AppTextStyles.body.copyWith(
                                                        color: Colors.white,
                                                      )
                                                    )
                                                  ),
                                                  )
                                                )
                                              )
                                            ],
                                          );
                                        }
                                      );
                                      return;
                                    }
                                   
                                  } else {
                                    print('Button Rejection Failed');
                                    
                                  }
                                }catch (e){
                                  print('Error: $e');
                                }

                                
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color.fromARGB(255, 236, 162, 55),
                                padding: const EdgeInsets.symmetric(horizontal: 100, vertical: 20),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30.0),
                                ),  
                              ),
                              child: Text(
                                'Confirm',
                                style: AppTextStyles.subtitle.copyWith(
                                  color: Colors.black, // White text color
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () async {
                                Navigator.of(context).pop(); // Close the dialog
                                
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                padding: const EdgeInsets.symmetric(horizontal: 100, vertical: 20),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30.0),
                                ),  
                              ),
                              child: Text(
                                'Cancel',
                                style: AppTextStyles.subtitle.copyWith(
                                  color: Colors.white, // White text color
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          
                        ],
                      ),
                      ],
                    ),
                    
                  ),
                  Positioned(
                      top: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.red,
                          ),
                          padding: const EdgeInsets.all(4),
                          child: const Icon(Icons.close, size: 25, color: Colors.white),
                        ),
                      ),
                    ),
                ]
              );
              
            },
          )
          
        );
      },
    );
  }
}

// Move FullScreenImage to the top-level (outside of any class)
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