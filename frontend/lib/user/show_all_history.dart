// ignore_for_file: unused_import, avoid_print, depend_on_referenced_packages, unnecessary_import

import 'dart:convert';
import 'dart:io';

import 'package:animated_toggle_switch/animated_toggle_switch.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/models/transaction_model.dart';
import 'package:frontend/notifiers/auth_notifier.dart';
import 'package:frontend/notifiers/navigation_notifier.dart';
import 'package:frontend/provider/accepted_transaction.dart' as accepted_transaction;
import 'package:frontend/provider/theme_provider.dart';
import 'package:frontend/provider/transaction_list_notifier.dart';
import 'package:frontend/provider/transaction_provider.dart';
import 'package:frontend/screen/navigation_menu.dart';
import 'package:frontend/theme/colors.dart';
import 'package:frontend/theme/text_styles.dart';
import 'package:frontend/user/history_details.dart';
import 'package:frontend/user/transaction_details.dart';
import 'package:intl/intl.dart';

class AllHistoryScreen extends ConsumerStatefulWidget{
  final String uid;
  final Transaction? transaction; 
  
  const AllHistoryScreen( {super.key, required this.uid, required this.transaction});

  @override

  ConsumerState<AllHistoryScreen> createState() => _AllHistoryPageState();
}

class _AllHistoryPageState extends ConsumerState<AllHistoryScreen>{
  String? uid;
 Future<List<Transaction>>? _futureTransactions;

  final ScrollController _scrollableController = ScrollController();

 @override
void initState() {
  super.initState();
  Future.microtask(() {
    setState(() {
      _futureTransactions = ref.read(allHistoryProvider.future);
    });
  });

  _scrollableController.addListener(() {
      if (_scrollableController.position.pixels == _scrollableController.position.maxScrollExtent) {
        ref.read(paginatedTransactionProvider('all-history').notifier).fetchNextPage();
      }
    });
}

  Future<void> _refreshTransaction() async {
    print("Refreshing transactions");
    try {
      ref.invalidate(allHistoryProvider);
      setState(() {
        _futureTransactions = ref.read(allHistoryProvider.future);
      });
      print("REFRESHED!");
    } catch (e) {
      print('DID NOT REFRESH!');
    }
  }

  Map< String, String> separateDateTime(String? dateTime) {
    if (dateTime == null || dateTime.isEmpty) {
      return {"date": "N/A", "time": "N/A"}; // Return default values if null or empty
    }

    try {
      DateTime datetime = DateTime.parse("${dateTime}Z").toLocal();

      return {
        "date": DateFormat('dd MMM , yyyy').format(datetime),
        "time": DateFormat('hh:mm a').format(datetime),
      };
    } catch (e) {
      print("Error parsing date: $e");
      return {"date": "N/A", "time": "N/A"}; // Return default values on error
    }
  }


   
  Color getStatusColor(String status) {
    switch (status) {
      case 'Completed':
        return const Color.fromARGB(255, 28, 157, 114);
      case 'Cancelled':
        return  Colors.red;
      case 'Rejected':
        return  Colors.grey;
      default:
      return Colors.grey;
    }
  }

  
  
  @override
  Widget build(BuildContext context) {
     
  
    
    final acceptedTransaction = ref.watch(accepted_transaction.acceptedTransactionProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text("History", style: AppTextStyles.title.copyWith(
          color: mainColor,
        )),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded (
              child: RefreshIndicator(
                onRefresh: _refreshTransaction,
                child: FutureBuilder<List<Transaction>>(
                  future: _futureTransactions,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }

                    final transactionList = snapshot.data ?? [];


                    // If acceptedTransaction is a list, convert it to a Set of IDs for faster lookup
                    final acceptedTransactionIds = acceptedTransaction;

                    // Filtered list excluding transactions with IDs in acceptedTransaction
                    final transaction = transactionList.where((t) {
                      final key = "${t.id}-${t.requestNumber}";
                        return !acceptedTransactionIds.contains(key);
                    }).toList();

                   
                    final authPartnerId = ref.watch(authNotifierProvider).partnerId;
                    final driverId = authPartnerId?.toString();

                   



                    final expandedTransactions = transaction.expand((item) {
                      
                      String cleanAddress(String address) {
                        return address
                          .split(',') // splits the string by commas
                          .map((e) => e.trim()) //removes extra spaces
                          .where((e) => e.isNotEmpty && e.toLowerCase() != 'ph') //filters out empty strings and 'ph'
                          .join(', '); // joins the remaining parts back together
                      }
    
                      if (item.dispatchType == "ot") {
                        return [
                          // First instance: Deliver to Shipper
                          if (item.deTruckDriverName == driverId) // Filter out if accepted
                            // Check if the truck driver is the same as the authPartnerId
                            item.copyWith(
                              name: "Deliver to Shipper",
                              destination: cleanAddress(item.origin),
                              origin: cleanAddress(item.destination),
                              requestNumber: item.deRequestNumber,
                              requestStatus: item.deRequestStatus,
                              rejectedTime: item.deRejectedTime,
                              completedTime: item.deCompletedTime,

                              truckPlateNumber: item.deTruckPlateNumber,
                            ),
                            // Second instance: Pickup from Shipper
                          if ( item.plTruckDriverName == driverId) // Filter out if accepted
                            // if (item.plTruckDriverName == authPartnerId)
                              item.copyWith(
                              name: "Pickup from Shipper",
                              destination: cleanAddress(item.origin),
                              origin: cleanAddress(item.destination),
                              requestNumber: item.plRequestNumber,
                              requestStatus: item.plRequestStatus,
                              rejectedTime: item.plRejectedTime,
                              completedTime: item.plCompletedTime,
                              truckPlateNumber: item.plTruckPlateNumber,
                              ),
                        ];
                      } else if (item.dispatchType == "dt") {
                        return [
                          // First instance: Deliver to Consignee
                          if (item.dlTruckDriverName == driverId) // Filter out if accepted
                            item.copyWith(
                              name: "Deliver to Consignee",
                              origin: cleanAddress(item.destination),
                              destination: cleanAddress(item.origin),
                              requestNumber: item.dlRequestNumber,
                              requestStatus: item.dlRequestStatus,
                              rejectedTime: item.dlRejectedTime,
                              completedTime: item.dlCompletedTime,
                              truckPlateNumber: item.dlTruckPlateNumber,
                            ),
                          // Second instance: Pickup from Consignee
                          if (item.peTruckDriverName == driverId) // Filter out if accepted
                            item.copyWith(
                              name: "Pickup from Consignee",
                              origin: cleanAddress(item.origin),
                              destination: cleanAddress(item.destination),
                              requestNumber: item.peRequestNumber,
                              requestStatus: item.peRequestStatus,
                              rejectedTime: item.peRejectedTime,
                              completedTime: item.peCompletedTime,
                              truckPlateNumber: item.peTruckPlateNumber,
                            ),
                        ]; 
                      }
                      // Return as-is if no match
                      return [item];
                    }).toList();

                    expandedTransactions.sort((a,b){
                      DateTime dateACompleted = DateTime.tryParse(a.completedTime ?? '') ?? DateTime(0);
                      DateTime dateARejected = DateTime.tryParse(a.rejectedTime ?? '') ?? DateTime(0);
                      DateTime dateBCompleted = DateTime.tryParse(b.completedTime ?? '') ?? DateTime(0);
                      DateTime dateBRejected = DateTime.tryParse(b.rejectedTime ?? '') ?? DateTime(0);

                      DateTime latestA = dateACompleted.isAfter(dateARejected) ? dateACompleted : dateARejected;
                      DateTime latestB = dateBCompleted.isAfter(dateBRejected) ? dateBCompleted : dateBRejected;
                      
                      return latestB.compareTo(latestA);
                      
                    });
                    

                    final ongoingTransactions = expandedTransactions
                      .where((tx) =>  ['Cancelled', 'Completed'].contains(tx.stageId) || tx.requestStatus == 'Completed')
                      .toList();

                  
                    if (ongoingTransactions.isEmpty) {
                      return LayoutBuilder(
                        builder: (context,constraints){
                          return ListView(
                            physics: const AlwaysScrollableScrollPhysics(), // Allow scrolling even if the list is empty
                            children: [
                              SizedBox(
                                height: constraints.maxHeight, // Adjust height as needed
                                child: Center(
                                  child: Text(
                                    'No history transactions yet.',
                                    style: AppTextStyles.subtitle,
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                            ],
                          );
                        }
                      );
                      
                    }
                    return ListView.builder(
                      controller: _scrollableController,
                      itemCount: ongoingTransactions.length + 1,
                      itemBuilder: (context, index) {
                        if (index == ongoingTransactions.length) {
                          // Show a loading indicator at the end of the list
                          return const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                        final item = ongoingTransactions[index];
                        final statusLabel =
                        item.requestStatus == 'Completed'
                            ? item.requestStatus
                            : item.stageId == 'Completed' || item.stageId == 'Cancelled'
                                ? item.stageId
                                : '—';
                        return Container(
                          margin: const EdgeInsets.only(bottom: 20),
                         
                          child: InkWell(
                            onTap: () {
                              Navigator.of(context).push(
                                PageRouteBuilder(
                                  pageBuilder: (context, animation, secondaryAnimation) => HistoryDetailScreen(
                                    transaction: item,
                                    uid: uid ?? '',
                                  ),
                                  transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                    const begin = Offset(1.0, 0.0); // from right
                                    const end = Offset.zero;
                                    const curve = Curves.ease;

                                    final tween =
                                        Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                                    final offsetAnimation = animation.drive(tween);

                                    return SlideTransition(
                                      position: offsetAnimation,
                                      child: child,
                                    );
                                  },
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.all(3),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                    
                                      // Space between label and value
                                      Text(
                                        "Dispatch No.: ",
                                        style: AppTextStyles.caption.copyWith(
                                          color: darkerBgColor,
                                        ),
                                      ),
                                      Text(
                                        item.bookingRefNo ?? '—',
                                        style: AppTextStyles.caption.copyWith(
                                          color: mainColor,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const Spacer(),
                                    
                                      Container(
                                        decoration: BoxDecoration(
                                          color: getStatusColor((statusLabel ?? 'Unknown').trim()),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                            (item.requestStatus == 'Completed' || item.stageId == 'Completed')
                                              ? 'Completed'
                                              : item.stageId == 'Cancelled'
                                                ? 'Cancelled'
                                                : '—',
                                              style: AppTextStyles.caption.copyWith(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                     

                                      Text(
                                        "Request ID: ",
                                        style: AppTextStyles.caption.copyWith(
                                          color: darkerBgColor,
                                        ),
                                      ),
                                      Text(
                                        (item.requestNumber?.toString() ?? 'No Request Number Available'),
                                        style: AppTextStyles.caption.copyWith(
                                          color: mainColor,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const Spacer(),
                                      Container(
                                        constraints: const BoxConstraints(
                                          minWidth: 150,
                                        ),
                                       
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                              item.stageId == 'Cancelled'
                                                ? separateDateTime(item.writeDate)['date'] ?? '—'
                                                : item.requestStatus == 'Completed'
                                                  ? separateDateTime(item.completedTime)['date'] ?? '—'
                                                  : '—',
                                              style: AppTextStyles.caption.copyWith(
                                                color: mainColor,
                                                fontWeight: FontWeight.bold,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ],
                                        ),
                                      ),
                                      
                                    ],
                                  ),
                                 
                                  Row(
                                    children: [
                                    

                                      Text(
                                        "View Details →",
                                        style: AppTextStyles.caption.copyWith(
                                          color: mainColor,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                     
                                     const Spacer(),
                                      Container(
                                        constraints: const BoxConstraints(
                                          minWidth: 150,
                                        ),
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                              item.stageId == 'Cancelled'
                                                ? separateDateTime(item.writeDate)['time'] ?? '—'
                                                : item.requestStatus == 'Completed'
                                                  ? separateDateTime(item.completedTime)['time'] ?? '—'
                                                  : '—',
                                              style: AppTextStyles.caption.copyWith(
                                                color: mainColor,
                                                fontWeight: FontWeight.bold,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ],
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
                    );
                  }, 
                  // Remove loading and error named parameters, handle in builder
                ),  
              )
            )
              
          ],
        )
      ), 
      bottomNavigationBar: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            
            NavigationMenu(),
          ],
          
        )
    );
   

  }

}