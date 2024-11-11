import 'package:frontend/notifiers/transaction_notifier.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/provider/accepted_transaction.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';

class TransactionScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> user;
  const TransactionScreen({super.key, required this.user});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _TransactionScreenState();
}

class _TransactionScreenState extends ConsumerState<TransactionScreen> {
  @override
  void initState() {
    initLocation();
    super.initState();
  }

  MapController mapController = MapController();
  Location location = Location();
  bool _serviceEnabled = false;
  PermissionStatus? _permissionGranted;
  LocationData? _locationData;
  bool _isMapReady = false; // Flag to check if the map is ready

  initLocation() async {
    _serviceEnabled = await location.serviceEnabled();
    if (!_serviceEnabled) {
      _serviceEnabled = await location.requestService();
      if (!_serviceEnabled) {
        return;
      }
    }

    _permissionGranted = await location.hasPermission();
    if (_permissionGranted == PermissionStatus.denied) {
      _permissionGranted = await location.requestPermission();
      if (_permissionGranted != PermissionStatus.granted) {
        return;
      }
    }

    _locationData = await location.getLocation();

    if (_isMapReady) {
      // Ensure the map is ready before moving the controller
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            print(_locationData.toString());
            mapController.move(
              LatLng(
                  _locationData?.latitude ?? 0, _locationData?.longitude ?? 0),
              16,
            );
          });
        }
      });
    }
  }

  void _success(transaction) {
    ref.read(transactionNotifierProvider.notifier).submitTransaction(
        userId: transaction.id,
        amount: transaction.amount,
        transactionDate:
            DateTime.parse(transaction.eta), //transaction.transactionDate,
        description: transaction.booking, //transaction.description,
        transactionId:
            "89", //transaction.id.toString(), //transaction.transactionId,
        booking: transaction.booking,
        location: transaction.location,
        destination: transaction.destination,
        eta: DateTime.parse(transaction.eta),
        etd: DateTime.parse(transaction.etd),
        status: transaction.status,
        context: context);
  }

  @override
  Widget build(BuildContext context) {
    final transaction = ref.watch(acceptedTransactionProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: transaction.map((transact) {
          return Card(
            elevation: 4, // Elevation to give the card a floating effect
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15), // Rounded corners
            ),
            child: Column(
              children: [
                // Map and Booking Details Combined in One Card
                Container(
                  // Combine Map and Details
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    color: Colors.white, // Background color of the card
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Placeholder for the Map
                      Container(
                        height: 460, // Height of the map container
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
                                    _locationData?.latitude ?? 0,
                                    _locationData?.longitude ?? 0,
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
                                  point: LatLng(10.304638, 123.9117856),
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
                      const SizedBox(
                          height: 10), // Space between the map and details

                      // Booking details below the map
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 5, vertical: 0),
                              child: Text(
                                transact.booking,
                                style: GoogleFonts.poppins(
                                    // color: Colors.black, // Text color for status
                                    fontWeight: FontWeight.bold,
                                    fontSize: 22,
                                    letterSpacing: 0.9),
                              )),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 36, vertical: 8),
                            decoration: BoxDecoration(
                                color: _getStatusColor(transact
                                    .status), // Background color for status
                                borderRadius: BorderRadius.circular(5)),
                            child: Text(
                              transact.status,
                              style: GoogleFonts.poppins(
                                color: Colors.white, // Text color for status
                                // fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),

                      Row(
                        children: [
                          const Icon(Icons.location_on,
                              color: Colors.blueAccent),
                          const SizedBox(width: 5),
                          Text(
                            'Origin: ${transact.location}',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          const Icon(Icons.flag, color: Colors.green),
                          const SizedBox(width: 5),
                          Text(
                            'Destination: ${transact.destination}',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          const Icon(Icons.timer, color: Colors.orange),
                          const SizedBox(width: 5),
                          Text(
                            'ETA: ${transact.eta}',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          const Icon(Icons.public_rounded, color: Colors.green),
                          const SizedBox(width: 5),
                          Text(
                            'Latitude : ${_locationData?.latitude}',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          const Icon(Icons.public_rounded, color: Colors.red),
                          const SizedBox(width: 5),
                          Text(
                            'Longitude : ${_locationData?.longitude}',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton(
                          onPressed: () {
                            _success(transact);
                          },
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.blue,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 10),
                          ),
                          child: const Text(
                            'Done',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      // ... other rows of booking details ...
                    ],
                  ),
                )
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // Helper method to get the color based on the status
  Color _getStatusColor(String status) {
    switch (status) {
      case 'Success':
        return Colors.green;
      case 'Ongoing':
        return Colors.orange;
      case 'Pending':
      default:
        return Colors.deepOrangeAccent;
    }
  }
}
