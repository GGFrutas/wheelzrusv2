
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/models/reject_reason_model.dart';
import 'package:frontend/models/transaction_model.dart';
import 'package:frontend/provider/accepted_transaction.dart';
import 'package:frontend/provider/transaction_provider.dart';
import 'package:frontend/provider/reject_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:frontend/user/transaction_details.dart';

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
  @override
  Widget build(BuildContext context) {
    final transactionold = ref.watch(filteredItemsProvider);
    final acceptedTransaction = ref.watch(acceptedTransactionProvider);

    return transactionold.when(
      data: (transactionList) {
        // If transactionList is null, we ensure it's an empty list to prevent errors
        final validTransactionList = transactionList;

        // If there are no transactions, show a message
        if (validTransactionList.isEmpty) {
          return const Center(child: Text('No transactions available.'));
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
          return const Center(child: Text('No transactions available that haven’t been accepted.'));
        }

        final expandedTransactions = transaction.expand((item) {
          if (item.dispatchType == "ot") {
            return [
              // First instance: Deliver to Shipper
              if (item.deRequestStatus != "accepted") // Filter out if accepted
                item.copyWith(
                name: "Deliver to Shipper",
                destination: item.destination,
                origin: item.origin,
                requestNumber: item.deRequestNumber,
                requestStatus: item.deRequestStatus,
              ),
                // Second instance: Pickup from Shipper
              if (item.plRequestStatus != "accepted") // Filter out if accepted
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
      if (item.dlRequestStatus != "accepted") // Filter out if accepted
        item.copyWith(
          name: "Delivers to Consignee",
          origin: item.destination,
          destination: item.origin,
          requestNumber: item.dlRequestNumber,
          requestStatus: item.dlRequestStatus,
        ),
      // Second instance: Pickup from Consignee
      if (item.peRequestStatus != "accepted") // Filter out if accepted
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
              

        return Scaffold(
          appBar: AppBar(
            title: Text(
              'YXE Driver',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            centerTitle: true,
          ),
          body: Padding(
            padding: const EdgeInsets.all(16),
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
                            builder: (context) => TransactionDetails(transaction: item),
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


                                // Text("Request Number: ${item.requestNumber}"),
                                // Text("Pick-Up Address: ${item.origin}"),
                                // Text("Delivery Address: ${item.destination}"),
                                // Text("Delivery Schedule: ${item.deliveryDate}"),
                              ],
                            ),

                            // Button Section
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                ElevatedButton(
                                  onPressed: () {
                                    final selectedTransaction = expandedTransactions[index];
                                    final acceptedTransactionNotifier = ref.read(acceptedTransactionProvider.notifier);

                                    final isAccepted = acceptedTransactionNotifier.isAccepted(
                                      selectedTransaction.id, 
                                      selectedTransaction.requestNumber.toString(),
                                    );

                                    // If not accepted, update the status and add it to accepted transactions
                                    if (!isAccepted) {
                                      acceptedTransactionNotifier.updateStatus(
                                        selectedTransaction.id.toString(),
                                        selectedTransaction.requestNumber.toString(),
                                        'Accepted', // Pass both ID and RequestNumber
                                      );
                                      acceptedTransactionNotifier.addProduct(selectedTransaction); // Add to accepted list

                                      setState(() {
                                        expandedTransactions.removeAt(selectedTransaction.id);
                                      });
                                      // ref.read(filteredItemsProvider.notifier).removeTransaction(selectedTransaction);
                                    }

                                    // Find and display the updated transaction
                                    final updatedState = ref.read(acceptedTransactionProvider);
                                    final updatedTransaction = updatedState.firstWhere(
                                      (transaction) => transaction.id == selectedTransaction.id,
                                      orElse: () => selectedTransaction, // Return the original if not found
                                    );

                                    // Print the updated status
                                    print('ID: ${updatedTransaction.id}');
                                    print('Request Number: ${updatedTransaction.requestNumber}');
                                    print('Updated Status: ${updatedTransaction.requestStatus}');

                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => TransactionDetails(transaction: item),
                                      ),
                                    );
                                      
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color.fromARGB(255, 244, 176, 74),
                                  
                                  ),
                                  child: Text(
                                    'Accept'.toUpperCase(),
                                    style: GoogleFonts.poppins(
                                      color: Colors.black, // White text color
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                     _showModal(context,ref);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color.fromARGB(255, 255, 0, 0), // Set the button color to orange
                                  ),
                                  child: Text(
                                    'Reject'.toUpperCase(),
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
            ),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),  // Show loading spinner while fetching data
      error: (e, stack) => Center(child: Text('Error: $e')),  // Display error message if an error occurs
    );
  }

  void _showModal(BuildContext context, WidgetRef ref) {
    TextEditingController controller = TextEditingController();
    String? selectedValue;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Reject This Booking'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Text('Tell us why you are refusing this booking request, this will help us improve our services.'),
              Consumer(
                builder: (context, ref, child) {
                  final rejectionReasonsAsync = ref.watch(rejectionReasonsProvider);

                   return rejectionReasonsAsync.when(
                    data: (reasons) {
                      return DropdownButton<String>(
                        value: selectedValue,
                        hint: const Text('Select a reason'),
                        onChanged: (String? newValue) {
                          selectedValue = newValue;
                        },
                        items: reasons.map<DropdownMenuItem<String>>((RejectionReason reason) {
                          return DropdownMenuItem<String>(
                            value: reason.id.toString(), // Using the 'id' from the model
                            child: Text(reason.name), // Using the 'name' from the model
                          );
                        }).toList(),
                      );
                    },
                      loading: () => const CircularProgressIndicator(),
                    error: (e, stackTrace) => Text('Error: $e'),
                  );
                },
              ),

              const SizedBox(height: 10),

              // Text Area for feedback
              TextField(
                controller: controller,
                maxLines: 5,  // Multi-line text area
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Your feedback...',
                ),
              ),
            ],
          ),
          actions: <Widget>[
            ElevatedButton(
              onPressed: () {
                // Handle Reject Action here (using _selectedValue and controller.text)
                Navigator.of(context).pop();
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


