import 'dart:io';
import 'dart:math';
import 'package:frontend/notifiers/transaction_notifier.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/provider/accepted_transaction.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';
import 'package:signature/signature.dart'; // Import signature package
import 'package:path_provider/path_provider.dart';
import 'dart:typed_data';

class TransactionScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> user;
  const TransactionScreen({super.key, required this.user});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _TransactionScreenState();
}

class _TransactionScreenState extends ConsumerState<TransactionScreen> {
  final SignatureController _controller = SignatureController(
    penStrokeWidth: 5,
    penColor: Colors.black,
    exportBackgroundColor: Colors.white,
  );

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

  Future<void> saveSignature(Uint8List signatureBytes) async {
    final directory = await getApplicationDocumentsDirectory();
    final filePath = '${directory.path}/signature.png';
    final file = File(filePath);
    await file.writeAsBytes(signatureBytes);
    print('Signature saved to $filePath');
  }

  void _success(transaction, context) async {
    // Export the signature as a PNG byte array
    final signatureBytes =
        await _controller.toPngBytes(height: 1000, width: 1000);
    if (signatureBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          key: Key('snackbarNoImage'),
          content: Text('Failed to generate signature image'),
        ),
      );
      return;
    }
    await saveSignature(signatureBytes);

    final random = Random();
    final transactionId = random.nextInt(1000000);
    // Pass the signature bytes to the submitTransaction function
    ref.read(transactionNotifierProvider.notifier).submitTransaction(
          userId: 1,
          amount: transaction.amount,
          transactionDate: DateTime.now(),
          description: transaction.booking,
          transactionId:
              transactionId.toString(), // Use your actual transaction ID
          booking: transaction.booking,
          location: transaction.location,
          destination: transaction.destination,
          eta: DateTime.now(),
          etd: DateTime.now(),
          status: transaction.status,
          signature: signatureBytes, // Pass the signature bytes here
          context: context,
        );

    if (mounted) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => Scaffold(
            appBar: AppBar(
              title: const Text('PNG Image'),
            ),
            body: Center(
              child: Container(
                color: Colors.grey[300],
                child: Image.memory(signatureBytes),
              ),
            ),
          ),
        ),
      );
    }
    }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    color: Colors.white,
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

                      // Signature Widget (Signature Canvas)
                      const SizedBox(height: 20),
                      Text(
                        'Please provide your signature below:',
                        style: GoogleFonts.poppins(fontSize: 16),
                      ),
                      Signature(
                        controller: _controller,
                        width: 300,
                        height: 150,
                        backgroundColor: Colors.grey[200]!,
                      ),
                      const SizedBox(height: 10),

                      // Clear Button to clear the signature
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.red,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 10),
                          ),
                          onPressed: () => _controller.clear(),
                          child: const Text('Clear Signature',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(
                          height: 10), // Space between signature and details

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
                                  fontWeight: FontWeight.bold,
                                  fontSize: 22,
                                  letterSpacing: 0.9,
                                ),
                              )),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 36, vertical: 8),
                            decoration: BoxDecoration(
                              color: _getStatusColor(transact.status),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Text(
                              transact.status,
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      // ... Rest of the booking details ...
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
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton(
                          onPressed: () {
                            _success(transact, context);
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
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
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
