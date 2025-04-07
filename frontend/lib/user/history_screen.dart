// ignore_for_file: unused_import, avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/provider/reject_provider.dart';
import 'package:frontend/provider/transaction_provider.dart';
import 'package:frontend/user/rejection_details.dart';
import 'package:frontend/user/transaction_details.dart';
import 'package:google_fonts/google_fonts.dart';

class HistoryScreen extends ConsumerStatefulWidget{
  const HistoryScreen({super.key, required Map<String, dynamic> user});

  @override
  // ignore: library_private_types_in_public_api
  _HistoryPageState createState() => _HistoryPageState();
}

class _HistoryPageState extends ConsumerState<HistoryScreen> {
// Tracks loading states for each request
// final Map<String, bool> _loadingStates = {};
   Future<void> _refreshTransaction() async {
    print("Refreshing transactions");
    try {
      // final uid = ref.watch(authNotifierProvider).uid;
      ref.invalidate(rejectionReasonsProvider);
      print("REFRESHED!");
    }catch (e){
      print('DID NOT REFRESHED!');
    }
   }

  @override
  Widget build(BuildContext context) {
    final transactionold = ref.watch(filteredRejected);
    final rejectedTransactions = ref.watch(rejectedTransactionProvider);

    return transactionold.when(
      data: (transactionList) {
        
        final validTransactionList = transactionList;

        // If there are no transactions, show a message
        if (validTransactionList.isEmpty) {
          return const Center(child: Text('No history available.'));
        }

        // If rejectedTransactions is a list, convert it to a Set of IDs for faster lookup
        final rejectedTransactionsIds = rejectedTransactions;

        // Filtered list excluding transactions with IDs in rejectedTransactions
        final transaction = validTransactionList.where((t) {
          final key = "${t.id}-${t.requestNumber}";
          return !rejectedTransactionsIds.contains(key);
        }).toList();

        // If no filtered transactions, show a message
        if (transaction.isEmpty) {
          return const Center(child: Text('No transactions available that have not been accepted.'));
        }

        final expandedTransactions = transaction.expand((item) {
          if (item.dispatchType == "ot") {
            return [
              if (item.deRequestStatus == "accepted" && item.deRequestStatus != "rejected" && item.deTruckDriverName!.isNotEmpty)
                item.copyWith(
                  name: "Deliver to Shipper",
                  destination: item.destination,
                  origin: item.origin,
                  requestNumber: item.deRequestNumber,
                  requestStatus: item.deRequestStatus,
                ),
              if (item.plRequestStatus != "rejected" && item.plTruckDriverName!.isNotEmpty)
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
              if (item.dlRequestStatus != "rejected" && item.dlTruckDriverName!.isNotEmpty)
                item.copyWith(
                  name: "Delivers to Consignee",
                  origin: item.destination,
                  destination: item.origin,
                  requestNumber: item.dlRequestNumber,
                  requestStatus: item.dlRequestStatus,
                ),
              if (item.peRequestStatus != "rejected" && item.peTruckDriverName!.isNotEmpty)
                item.copyWith(
                  name: "Pickup from Consignee",
                  requestNumber: item.peRequestNumber,
                  requestStatus: item.peRequestStatus,
                ),
            ];
          }
          return [item];
        }).toList();

        expandedTransactions.sort((a, b) {
          DateTime dateA = DateTime.tryParse(a.deliveryDate) ?? DateTime(0);
          DateTime dateB = DateTime.tryParse(b.deliveryDate) ?? DateTime(0);
          return dateB.compareTo(dateA);
        });

        return Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: RefreshIndicator(
              onRefresh: _refreshTransaction,
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
                  // final isLoading = _loadingStates[item.requestNumber.toString()] ?? false;
                  Color getStatusColor(String requestStatus) {
                    switch (requestStatus) {
                      case 'Completed':
                        return Colors.green;
                      case 'Ongoing':
                        return const Color.fromARGB(255, 62, 243, 68);
                      case 'Accepted':
                        return const Color.fromARGB(255, 239, 184, 44);
                      case 'Pending':
                        return Colors.orange;
                      case 'Rejected':
                        return const Color.fromARGB(255, 233, 110, 34);
                      case 'Cancelled':
                        return Colors.red;
                      default:
                        return Colors.grey;
                    }
                  }

                  return ConstrainedBox(
                    constraints: const BoxConstraints(
                      minHeight: 80.0,
                      maxHeight: 150.0,
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => RejectionDetails(
                                transaction: item,
                                id: item.id,
                                uid: '',
                              ),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
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
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 2,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
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
                                          softWrap: true,
                                        ),
                                      ),
                                    ],
                                  ),
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
                                          softWrap: true,
                                        ),
                                      ),
                                    ],
                                  ),
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
                                          softWrap: true,
                                        ),
                                      ),
                                    ],
                                  ),
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
                                          softWrap: true,
                                        ),
                                      ),
                                    ],
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
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, stack) => Center(child: Text('Error: $e')),
    );
  }
}
