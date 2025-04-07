
// ignore_for_file: unused_import, deprecated_member_use, avoid_print

import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/models/reject_reason_model.dart';
import 'package:frontend/models/transaction_model.dart';
import 'package:frontend/notifiers/auth_notifier.dart';
import 'package:frontend/provider/accepted_transaction.dart' as accepted_transaction;
import 'package:frontend/provider/transaction_list_notifier.dart' as transaction_list;
import 'package:frontend/provider/transaction_list_notifier.dart';
import 'package:frontend/provider/transaction_provider.dart';
import 'package:frontend/provider/reject_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:frontend/user/transaction_details.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;


class HomepageScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> user;

  const HomepageScreen({super.key, required this.user});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _HomepageScreenState();
}

// List of pastel colors
final List<Color> pastelColors = [
  const Color(0xFFFFD1DC), // Light Pink
  const Color(0xFFFFF4E6), // Light Peach
  const Color(0xFFE6E6FA), // Lavender
  const Color(0xFFFFEBCD), // Blanched Almond
  const Color(0xFFB4E1FF), // Light Blue
  const Color(0xFFBFFCC6), // Mint Green
  const Color(0xFFFFFACD), // Lemon Chiffon
  const Color(0xFFF5D5A4), // Pastel Orange
];

// Function to get a random pastel color
Color getRandomPastelColor() {
  final random = Random();
  return pastelColors[random.nextInt(pastelColors.length)];
}

class _HomepageScreenState extends ConsumerState<HomepageScreen> {
  String? uid;
   final Map<String, bool> _loadingStates = {};
   Future<void> _refreshTransaction() async {
    print("Refreshing transactions");
    try {
      
      ref.invalidate(bookingProvider);
      print("REFRESHED!");
    }catch (e){
      print('DID NOT REFRESHED!');
    }
   }
  
  
  @override
  Widget build(BuildContext context) {
     
    final transactionold = ref.watch(filteredItemsProvider);
    
    final acceptedTransaction = ref.watch(accepted_transaction.acceptedTransactionProvider);

    return RefreshIndicator(
      onRefresh: _refreshTransaction,
      child: transactionold.when(
        data: (transactionList) {
          // If transactionList is null, we ensure it's an empty list to prevent errors
          if (transactionList.isNotEmpty) {
            for (var transaction in transactionList) {
              print("Booking ID: ${transaction.id}");
            }
          } else {
            print("No transactions found.");
          }
          final validTransactionList = transactionList;

          // If there are no transactions, show a message
          if (validTransactionList.isEmpty) {
            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(), // Allow scrolling even if the list is empty
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.8, // Adjust height as needed
                child: const Center(
                  child: Text(
                    'No transactions available.'
                  ),
                ),
              ),
            );
          }

          // If acceptedTransaction is a list, convert it to a Set of IDs for faster lookup
          final acceptedTransactionIds = acceptedTransaction;

          // Filtered list excluding transactions with IDs in acceptedTransaction
          final transaction = validTransactionList.where((t) {
            final key = "${t.id}-${t.requestNumber}";
              return !acceptedTransactionIds.contains(key);
          }).toList();

            // If no filtered transactions, show a message
          if (transaction.isEmpty) {
            return const Center(child: Text('No transactions available that have not been accepted.'));
          }

          final expandedTransactions = transaction.expand((item) {
            if (item.dispatchType == "ot") {
              return [
                // First instance: Deliver to Shipper
                if (item.deRequestStatus != "accepted" && item.deRequestStatus !="Rejected" && item.deTruckDriverName != null && item.deTruckDriverName!.isNotEmpty) // Filter out if accepted
                  item.copyWith(
                  name: "Deliver to Shipper",
                  destination: item.destination,
                  origin: item.origin,
                  requestNumber: item.deRequestNumber,
                  requestStatus: item.deRequestStatus,
                ),
                  // Second instance: Pickup from Shipper
                if (item.plRequestStatus != "accepted" && item.plRequestStatus != "Rejected" && item.plTruckDriverName != null && item.plTruckDriverName!.isNotEmpty) // Filter out if accepted
                  item.copyWith(
                  name: "Pickup from Shipper",
                  destination: item.origin,
                  origin: item.destination,
                  requestNumber: item.plRequestNumber,
                  requestStatus: item.plRequestStatus,
                  ),
              ];
            } else if (item.dispatchType == "dt") {
              return [
                // First instance: Deliver to Consignee
                if (item.dlRequestStatus != "accepted" && item.dlRequestStatus != "rejected" && item.dlTruckDriverName != null && item.dlTruckDriverName!.isNotEmpty) // Filter out if accepted
                  item.copyWith(
                    name: "Delivers to Consignee",
                    origin: item.destination,
                    destination: item.origin,
                    requestNumber: item.dlRequestNumber,
                    requestStatus: item.dlRequestStatus,
                  ),
                // Second instance: Pickup from Consignee
                if (item.peRequestStatus != "accepted"  && item.peRequestStatus != "rejected" && item.peTruckDriverName != null && item.peTruckDriverName!.isNotEmpty ) // Filter out if accepted
                  item.copyWith(
                    name: "Pickup from Consignee",
                    requestNumber: item.peRequestNumber,
                    requestStatus: item.peRequestStatus,
                  ),
              ];
            }
            // Return as-is if no match
            return [item];
          }).toList();

          expandedTransactions.sort((a,b){
            DateTime dateA = DateTime.tryParse(a.deliveryDate) ?? DateTime(0);
            DateTime dateB = DateTime.tryParse(b.deliveryDate) ?? DateTime(0);
            return dateB.compareTo(dateA);
          });
                

          return Scaffold(
            // appBar: AppBar(
            //   title: Text(
            //     'YXE Driver 1',
            //     style: GoogleFonts.poppins(
            //       fontSize: 24,
            //       fontWeight: FontWeight.bold,
            //     ),
            //   ),
            //   centerTitle: true,
            // ),
            body: Padding(
              padding: const EdgeInsets.all(16),
              // child: RefreshIndicator(
              //   onRefresh: _refreshTransaction,
                child: GridView.builder(
                  itemCount: expandedTransactions.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 1,
                    mainAxisExtent: 250,
                    crossAxisSpacing: 20,
                    mainAxisSpacing: 20,
                  ),
                  itemBuilder: (context, index) {
                    final item = expandedTransactions[index];
                    final isLoading = _loadingStates[item.requestNumber.toString()] ?? false;
                    Color getStatusColor(String requestStatus) {
                      switch (requestStatus) {
                        case 'Completed':
                          return Colors.green;
                        case 'Ongoing':
                          return const Color.fromARGB(255, 62, 243, 68);  // Completed status will have a green background
                        case 'Accepted':
                          return const Color.fromARGB(255, 239, 184, 44);  
                        case 'Pending':
                          return Colors.orange;
                        case 'Rejected':
                          return const Color.fromARGB(255, 233, 110, 34);
                        case 'Cancelled':
                          return Colors.red;
                        default:
                          return Colors.grey;  // Default color for unknown status
                      }
                    }

                    return ConstrainedBox(
                      constraints: const BoxConstraints(
                        minHeight: 80.0,  // Minimum height for the box
                        maxHeight: 150.0, // Maximum height for the box (adjust as needed)
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => TransactionDetails(transaction: item, id: item.id, uid: '',),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            color: getRandomPastelColor().withOpacity(0.75),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min, 
                              children: [
                                // Title Section
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Flexible(
                                      child: Text(
                                      item.name,
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        letterSpacing: 0.9,
                                      ),
                                      overflow: TextOverflow.ellipsis, // Prevent overflow
                                      maxLines: 2, // Allow wrapping to next line
                                    ),
                                  ),
                                  const SizedBox(width: 8), // Space between the text and the container
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: getStatusColor(item.requestStatus.toString()),
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                    child: Text(
                                      item.requestStatus.toString(),
                                      style: GoogleFonts.poppins(
                                        color: Colors.black,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              // Content Section
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        "Request Number: ",
                                        style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Flexible(
                                        child: Text(
                                          (item.requestNumber?.toString() ?? 'No Request Number Available'),
                                          style: GoogleFonts.poppins(
                                            fontWeight: FontWeight.w500,
                                          ),
                                          softWrap: true, // Text will wrap if it's too long
                                        ),
                                      ),
                                    ],
                                  ),
                                  // const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      Text(
                                        "Pick-Up Address: ",
                                        style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Flexible(
                                        child: Text(
                                          " ${item.destination}",
                                          style: GoogleFonts.poppins(
                                            fontWeight: FontWeight.w500,
                                          ),
                                          softWrap: true, // Text will wrap if it's too long
                                        ),
                                      ),
                                    ],
                                  ),
                                  // const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      Text(
                                        "Delivery Address: ",
                                        style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Flexible(
                                        child: Text(
                                          " ${item.origin}",
                                          style: GoogleFonts.poppins(
                                            fontWeight: FontWeight.w500,
                                          ),
                                          softWrap: true, // Text will wrap if it's too long
                                        ),
                                      ),
                                    ],
                                  ),
                                  // const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      Text(
                                        "Delivery Schedule: ",
                                        style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Flexible(
                                        child: Text(
                                          " ${item.deliveryDate}",
                                          style: GoogleFonts.poppins(
                                            fontWeight: FontWeight.w500,
                                          ),
                                          softWrap: true, // Text will wrap if it's too long
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                ],
                              ),

                              // Button Section
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  if (!(isLoading || item.requestStatus == "Accepted" || item.requestStatus == "Rejected" || ref.read(accepted_transaction.acceptedTransactionProvider.notifier).isAccepted(item.id, item.requestNumber.toString()))) 
                                 
                                  ElevatedButton(
                                    onPressed: () async {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => TransactionDetails(transaction: item, id: item.id, uid: '',),
                                        ),
                                      );
                                      // setState(() {
                                      //   _loadingStates[item.requestNumber.toString()] = true;
                                      // });

                                      // await Future.delayed(const Duration(milliseconds: 1000));
                                      // final selectedTransaction = expandedTransactions[index];
                                      // final acceptedTransactionNotifier = ref.read(accepted_transaction.acceptedTransactionProvider.notifier);

                                      // final isAccepted = acceptedTransactionNotifier.isAccepted(
                                      //   selectedTransaction.id, 
                                      //   selectedTransaction.requestNumber.toString(),
                                      // );

                                      // // If not accepted, update the status and add it to accepted transactions
                                      // if (isAccepted) {
                                      //   setState((){
                                      //     _loadingStates[selectedTransaction.requestNumber.toString()] = false;
                                      //   });
                                        return;
                                      // }
                                      // acceptedTransactionNotifier.updateStatus(
                                      //   selectedTransaction.id.toString(),
                                      //   selectedTransaction.requestNumber.toString(),
                                      //   'Accepted', ref// Pass both ID and RequestNumber
                                      // );
                                      //   acceptedTransactionNotifier.addProduct(selectedTransaction); // Add to accepted 
                                        
                                      //   Timer.periodic(const Duration(seconds: 2), (timer) async {
                                      //     final updated = await fetchTransactionStatus(ref, selectedTransaction.id.toString());

                                      //     if(updated.requestStatus == "Accepted") {
                                      //       setState(() {
                                      //         _loadingStates[selectedTransaction.requestNumber.toString()] = false;
                                      //       });
                                      //       timer.cancel();
                                      //     }
                                      //   });

                                      //   setState(() {
                                      //     expandedTransactions.removeWhere((t) => t.id == selectedTransaction.id);
                                      //   });
                                      //   // ref.read(filteredItemsProvider.notifier).removeTransaction(selectedTransaction);
                                      //   // ref.refresh(acceptedTransactionProvider);
                                      

                                      // // Find and display the updated transaction
                                      // final updatedState = ref.read(transaction_list.acceptedTransactionProvider);
                                      // final updatedTransaction = updatedState.firstWhere(
                                      //   (transaction) => transaction.id == selectedTransaction.id,
                                      //   orElse: () => selectedTransaction, // Return the original if not found
                                      // );

                                      // // Print the updated status
                                      // print('ID: ${selectedTransaction.id}');
                                      // print('Request Number: ${updatedTransaction.requestNumber}');
                                      // print('Updated Status: ${updatedTransaction.requestStatus}');

                                      // // setState((){
                                      // //   _loadingStates.remove(item.requestNumber.toString());
                                      // // });
                                        
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color.fromARGB(255, 244, 176, 74),
                                    
                                    ),
                                    child: isLoading ? const CircularProgressIndicator(color: Colors.black)
                                    :Text(
                                      'Accept'.toUpperCase(),
                                      style: GoogleFonts.poppins(
                                        color: Colors.black, // White text color
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  if (!(item.requestStatus != "Rejected" || item.requestStatus != "Accepted" )) 
                                  ElevatedButton(
                                    onPressed: () {
                                      _showModal(context, ref, expandedTransactions, index);
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color.fromARGB(255, 255, 0, 0), // Set the button color to orange
                                    ),
                                    child: Text(
                                      'Directions'.toUpperCase(),
                                      style: GoogleFonts.poppins(
                                        color: Colors.white, // White text color
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              // )
              
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),  // Show loading spinner while fetching data
        error: (e, stack) => Center(child: Text('Error: $e')),  // Display error message if an error occurs
      ),
    );
    
  }

  void _showModal(BuildContext context, WidgetRef ref, List<dynamic> expandedTransactions, int index) {
    TextEditingController controller = TextEditingController();
    // String? selectedValue;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Reject This Booking'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Text('Tell us why you are refusing this booking request, this will help us improve our services.'),
                Consumer(
                  builder: (context, ref, child) {
                    final rejectionReasonsAsync = ref.watch(rejectionReasonsProvider);
                    final selectedValue = ref.watch(selectedReasonsProvider);

                    return rejectionReasonsAsync.when(
                      data: (reasons) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Expanded(
                            child: DropdownButton<String>(
                              isExpanded: true, 
                              value: selectedValue,
                              hint: const Text('Select a reason'),
                              onChanged: (String? newValue) {
                                ref.read(selectedReasonsProvider.notifier).state = newValue;
                              },
                              items: reasons.map<DropdownMenuItem<String>>((RejectionReason reason) {
                                return DropdownMenuItem<String>(
                                  value: reason.id.toString(),
                                child: Text(reason.name, overflow: TextOverflow.ellipsis),
                                );
                              }).toList(),
                            ),
                          ),
                        );
                      },
                        loading: () => const CircularProgressIndicator(),
                      error: (e, stackTrace) => Text('Error: $e'),
                    );
                  },
                ),

                const SizedBox(height: 10),

                // Text Area for feedback
                SingleChildScrollView(
                  child: TextField(
                    controller: controller,
                    maxLines: 3,  // Multi-line text area
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Your feedback...',
                    ),
                  ),
                ),
              ],
            ),
          ),

          actions: <Widget>[
            ElevatedButton(
              onPressed: () async {
                final uid = ref.read(authNotifierProvider).uid;
                final transactionId = expandedTransactions[index];

                // Handle Reject Action here (using _selectedValue and controller.text)
                final selectedReason = ref.read(selectedReasonsProvider);
                final feedback = controller.text;

                if(selectedReason == null || selectedReason.isEmpty){
                  print('Please select a reason');
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

                try{
                  final password = ref.watch(authNotifierProvider).password ?? '';
                  final response = await http.post(
                    Uri.parse('http://192.168.118.102:8000/api/odoo/reject-booking'),
                    headers:{
                      'Content-Type': 'application/json',
                      'Accept': 'application/json',
                      'password': password,
                    },
                    body: jsonEncode({
                      'uid': uid,
                      'transaction_id': transactionId.id,
                      'reason': selectedReason,
                      'feedback': feedback
                    }),
                  );
                  if (response.statusCode == 200) {
                      final rejectedTransactionNotifier = ref.read(accepted_transaction.acceptedTransactionProvider.notifier);
                      rejectedTransactionNotifier.updateStatus(transactionId.id.toString(), transactionId.requestNumber.toString(),'Rejected',ref);

                      final updated = await fetchTransactionStatus(ref, transactionId.id.toString());
                      print('Updated Status: ${updated.requestStatus}');

                      if(updated.requestStatus == "Rejected") {
                        print('Rejection Successful');
                      } else {
                        print('Rejection Failed');
                      }
                      Navigator.of(context).pop();
                    } else {
                      print('Button Rejection Failed');
                    }
                }catch (e){
                  print('Error: $e');
                  Navigator.of(context).pop();
                }

                
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 255, 0, 0), // Set button color to red
              ),
              child: Text(
                'X Reject'.toUpperCase(),
                style: GoogleFonts.poppins(
                  color: Colors.white, // White text color
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                // Handle Cancel Action
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 230, 178, 20), // Set button color to yellow
              ),
              child: Text(
                'Cancel'.toUpperCase(),
                style: GoogleFonts.poppins(
                  color: Colors.black, // Black text color
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}


