// ignore_for_file: unused_import, avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/notifiers/auth_notifier.dart';
import 'package:frontend/provider/accepted_transaction.dart' as accepted_transaction;
import 'package:frontend/provider/reject_provider.dart';
import 'package:frontend/provider/transaction_provider.dart';
import 'package:frontend/theme/colors.dart';
import 'package:frontend/theme/text_styles.dart';
import 'package:frontend/user/history_details.dart';
import 'package:frontend/user/rejection_details.dart';
import 'package:frontend/user/transaction_details.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class HistoryScreen extends ConsumerStatefulWidget{
  const HistoryScreen({super.key, required Map<String, dynamic> user});

  @override
  // ignore: library_private_types_in_public_api
  _HistoryPageState createState() => _HistoryPageState();
}

class _HistoryPageState extends ConsumerState<HistoryScreen> {
  String? uid;
  //  final Map<String, bool> _loadingStates = {};
   Future<void> _refreshTransaction() async {
    print("Refreshing transactions");
    try {
      
      ref.invalidate(bookingProvider);
      print("REFRESHED!");
    }catch (e){
      print('DID NOT REFRESHED!');
    }
   }

   String formatDateTime(String? dateString) {
    if (dateString == null || dateString.isEmpty) return "N/A"; // Handle null values
    
    try {
      DateTime dateTime = DateTime.parse(dateString); // Convert string to DateTime
       return DateFormat('d MMMM, yyyy').format(dateTime); // Format date-time
    } catch (e) {
      return "Invalid Date"; // Handle errors gracefully
    }
  } 

  Color getStatusColor(String status) {
    switch (status) {
      case 'Completed':
        return const Color.fromARGB(255, 28, 157, 114);
      case 'Rejected':
        return  Colors.red;
      default:
      return Colors.grey;
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

          // If acceptedTransaction is a list, convert it to a Set of IDs for faster lookup
          final acceptedTransactionIds = acceptedTransaction;

          // Filtered list excluding transactions with IDs in acceptedTransaction
          final transaction = validTransactionList.where((t) {
            final key = "${t.id}-${t.requestNumber}";
              return !acceptedTransactionIds.contains(key);
          }).toList();

         
          final authPartnerId = ref.watch(authNotifierProvider).partnerId;
          final driverId = authPartnerId?.toString();

          print("Driver: $authPartnerId");

          final expandedTransactions = transaction.expand((item) {
            print("🆔 Current driverId: $driverId");
            print("🟨 DE: ${item.deTruckDriverName}, PL: ${item.plTruckDriverName}, DL: ${item.dlTruckDriverName}, PE: ${item.peTruckDriverName}");
           
            if (item.dispatchType == "ot") {
              return [
                // First instance: Deliver to Shipper
                if (item.deTruckDriverName == driverId) // Filter out if accepted
                  // Check if the truck driver is the same as the authPartnerId
                   item.copyWith(
                    name: "Deliver to Shipper",
                    destination: item.destination,
                    origin: item.origin,
                    requestNumber: item.deRequestNumber,
                    requestStatus: item.deRequestStatus,
                    truckPlateNumber: item.deTruckPlateNumber,
                  ),
                  // Second instance: Pickup from Shipper
                if ( item.plTruckDriverName == driverId) // Filter out if accepted
                  // if (item.plTruckDriverName == authPartnerId)
                    item.copyWith(
                    name: "Pickup from Shipper",
                    destination: item.origin,
                    origin: item.destination,
                    requestNumber: item.plRequestNumber,
                    requestStatus: item.plRequestStatus,
                    truckPlateNumber: item.plTruckPlateNumber,
                    ),
              ];
            } else if (item.dispatchType == "dt") {
              return [
                // First instance: Deliver to Consignee
                if (item.dlTruckDriverName == driverId) // Filter out if accepted
                  item.copyWith(
                    name: "Delivers to Consignee",
                    origin: item.destination,
                    destination: item.origin,
                    requestNumber: item.dlRequestNumber,
                    requestStatus: item.dlRequestStatus,
                    truckPlateNumber: item.dlTruckPlateNumber,
                  ),
                // Second instance: Pickup from Consignee
                if (item.peTruckDriverName == driverId) // Filter out if accepted
                  item.copyWith(
                    name: "Pickup from Consignee",
                    requestNumber: item.peRequestNumber,
                    requestStatus: item.peRequestStatus,
                    truckPlateNumber: item.peTruckPlateNumber,
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

          final ongoingTransactions = expandedTransactions
            .where((tx) => tx.requestStatus == 'Rejected' || tx.requestStatus == "Completed")
            .toList();

          if (ongoingTransactions.isEmpty){
            return Center(
              child: Text(
                'No history yet.',
                style: AppTextStyles.subtitle,
              ),
            );
          }

          return Scaffold(
             body: Padding(
              padding: const EdgeInsets.all(16),
              child: ListView.builder(
                itemCount: ongoingTransactions.length,
                itemBuilder: (context, index) {
                  final item = ongoingTransactions[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [
                        BoxShadow(
                          color: darkerBgColor,
                          blurRadius: 6,
                          offset: Offset(0, 3)
                        )
                      ]
                    ),
                      
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => HistoryDetailScreen(
                              transaction: item,
                              uid: uid ?? '',
                            ),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            
                            Row(
                              children: [
                                const SizedBox(width: 20), // Space between icon and text
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Space between label and value
                                    Text(
                                      "Request Number",
                                      style: AppTextStyles.caption.copyWith(
                                        color: darkerBgColor,
                                      ),
                                    ),
                                    Text(
                                      (item.requestNumber?.toString() ?? 'No Request Number Available'),
                                      style: AppTextStyles.body.copyWith(
                                        color: mainColor,
                                        fontWeight: FontWeight.bold,
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
                                        "Delivered Date",
                                        style: AppTextStyles.caption.copyWith(
                                          color: darkerBgColor,
                                        ),
                                      ),
                                      Text(
                                        formatDateTime(item.deliveryDate),
                                        style: AppTextStyles.body.copyWith(
                                          color: mainColor,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  constraints: const BoxConstraints(
                                    minWidth: 150,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(20),
                                    color: getStatusColor(item.requestStatus ?? ''),
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  child: Text(
                                    item.requestStatus ?? '',
                                    style: AppTextStyles.caption.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ],
                            ),
                           
                         ],
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
      ),
    );
    
  }

}