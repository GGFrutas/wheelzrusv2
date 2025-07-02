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
  final Map<String, dynamic> user;
  const HistoryScreen({super.key, required this.user});

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
      DateTime dateTime = DateTime.parse("${dateString}Z").toLocal();// Convert string to DateTime
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

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header card covering full top area
            SizedBox(
              height: 200, // You can adjust height as needed
              width: double.infinity,
              child: Card(
                margin: const EdgeInsets.all(16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Image.asset(
                        'assets/New YXE Drive.jpg',
                        fit: BoxFit.cover,
                      ),
                    ),
                    Container(
                      color: Colors.black.withOpacity(0.4),
                    ),
                    Positioned(
                      left: 24,
                      top: 26,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Delivery\nTransactions',
                            style: AppTextStyles.title.copyWith(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text (
                            'Records of completed or\nscheduled deliveries',
                            style: AppTextStyles.caption.copyWith(
                              color: Colors.white,
                            
                            )
                          )
                        ],
                      )
                    ),
                    
                  ],
                ),
              ),
            ),
           
            Expanded (
              child: RefreshIndicator(
                onRefresh: _refreshTransaction,
                child: transactionold.when(
                  data: (transactionList) {
                    // If transactionList is null, we ensure it's an empty list to prevent errors
                    
                    final validTransactionList = transactionList;

                    print("Valid Transaction List: ${validTransactionList.length}");

                    // If there are no transactions, show a message
                    if (validTransactionList.isEmpty) {
                      return CustomScrollView(
                          physics: const AlwaysScrollableScrollPhysics(), // Allow scrolling even if the list is empty
                          slivers: [
                            SliverFillRemaining(
                              hasScrollBody: false,
                              child: Center(
                                child: Text(
                                  'No history yet.',
                                  style: AppTextStyles.subtitle,
                                ),
                              ),
                            )
                          ]
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
                              destination: cleanAddress(item.destination),
                              origin: cleanAddress(item.origin),
                              requestNumber: item.deRequestNumber,
                              requestStatus: item.deRequestStatus,
                              // truckPlateNumber: item.deTruckPlateNumber,
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
                              // truckPlateNumber: item.plTruckPlateNumber,
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
                              // truckPlateNumber: item.dlTruckPlateNumber,
                            ),
                          // Second instance: Pickup from Consignee
                          if (item.peTruckDriverName == driverId) // Filter out if accepted
                            item.copyWith(
                              name: "Pickup from Consignee",
                              origin: cleanAddress(item.origin),
                              destination: cleanAddress(item.destination),
                              requestNumber: item.peRequestNumber,
                              requestStatus: item.peRequestStatus,
                              // truckPlateNumber: item.peTruckPlateNumber,
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
                      .where((tx) => tx.requestStatus == "Rejected" || tx.requestStatus == "Completed")
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
                                  ),
                                ),
                              ),
                            ],
                          );
                        }
                      );
                      
                    }
                    return ListView.builder(
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
                                              item.requestStatus == "Completed" 
                                              ? "Date Completed"
                                              : item.requestStatus == "Rejected" 
                                              ? "Date Rejected"
                                              : "Date Rejected",
                                              style: AppTextStyles.caption.copyWith(
                                                color: darkerBgColor,
                                              ),
                                            ),
                                            Text(
                                              item.requestStatus == 'Rejected'
                                  ? formatDateTime(item.rejectedTime)
                                  : item.requestStatus == 'Completed'
                                    ? formatDateTime(item.completedTime)
                                    : '—',
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
                    );
                  }, 
                  loading: () => const Center(child: CircularProgressIndicator()),  // Show loading spinner while fetching data
                  error: (e, stack) => Center(child: Text('Error: $e')),  
                ),  
              )
            )
              
          ],
        )
      ) 
    );
   

   
    //       return Scaffold(
    //          body: Padding(
    //           padding: const EdgeInsets.all(16),
    //           child: ListView.builder(
    //             itemCount: ongoingTransactions.length,
    //             itemBuilder: (context, index) {
    //               final item = ongoingTransactions[index];
    //               return Container(
    //                 margin: const EdgeInsets.only(bottom: 20),
    //                 decoration: BoxDecoration(
    //                   color: bgColor,
    //                   borderRadius: BorderRadius.circular(12),
    //                   boxShadow: const [
    //                     BoxShadow(
    //                       color: darkerBgColor,
    //                       blurRadius: 6,
    //                       offset: Offset(0, 3)
    //                     )
    //                   ]
    //                 ),
                    
    //                 child: InkWell(
    //                   onTap: () {
    //                     Navigator.of(context).push(
    //                       PageRouteBuilder(
    //                         pageBuilder: (context, animation, secondaryAnimation) => HistoryDetailScreen(
    //                           transaction: item,
    //                           uid: uid ?? '',
    //                         ),
    //                         transitionsBuilder: (context, animation, secondaryAnimation, child) {
    //                           const begin = Offset(1.0, 0.0); // from right
    //                           const end = Offset.zero;
    //                           const curve = Curves.ease;

    //                           final tween =
    //                               Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
    //                           final offsetAnimation = animation.drive(tween);

    //                           return SlideTransition(
    //                             position: offsetAnimation,
    //                             child: child,
    //                           );
    //                         },
    //                       ),
    //                     );

    //                   },
    //                   child: Container(
    //                     padding: const EdgeInsets.all(16),
    //                     child: Column(
    //                       crossAxisAlignment: CrossAxisAlignment.start,
    //                       children: [
                            
    //                         Row(
    //                           children: [
    //                             const SizedBox(width: 20), // Space between icon and text
    //                             Column(
    //                               crossAxisAlignment: CrossAxisAlignment.start,
    //                               children: [
    //                                 // Space between label and value
    //                                 Text(
    //                                   "Request Number",
    //                                   style: AppTextStyles.caption.copyWith(
    //                                     color: darkerBgColor,
    //                                   ),
    //                                 ),
    //                                 Text(
    //                                   (item.requestNumber?.toString() ?? 'No Request Number Available'),
    //                                   style: AppTextStyles.body.copyWith(
    //                                     color: mainColor,
    //                                     fontWeight: FontWeight.bold,
    //                                   ),
    //                                 ),
    //                               ],
    //                             ),
    //                           ],
    //                         ),
    //                         const SizedBox(height: 20),
    //                         Row(
    //                           children: [
    //                             const SizedBox(width: 20), // Space between icon and text
    //                             Expanded(
    //                               child: Column(
    //                                 crossAxisAlignment: CrossAxisAlignment.start,
    //                                 children: [
    //                                   // Space between label and value
    //                                   Text(
    //                                     "Date Delivered",
    //                                     style: AppTextStyles.caption.copyWith(
    //                                       color: darkerBgColor,
    //                                     ),
    //                                   ),
    //                                   Text(
    //                                     formatDateTime(item.deliveryDate),
    //                                     style: AppTextStyles.body.copyWith(
    //                                       color: mainColor,
    //                                       fontWeight: FontWeight.bold,
    //                                     ),
    //                                   ),
    //                                 ],
    //                               ),
    //                             ),
    //                             Container(
    //                               constraints: const BoxConstraints(
    //                                 minWidth: 150,
    //                               ),
    //                               decoration: BoxDecoration(
    //                                 borderRadius: BorderRadius.circular(20),
    //                                 color: getStatusColor(item.requestStatus ?? ''),
    //                               ),
    //                               padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    //                               child: Text(
    //                                 item.requestStatus ?? '',
    //                                 style: AppTextStyles.caption.copyWith(
    //                                   color: Colors.white,
    //                                   fontWeight: FontWeight.bold
    //                                 ),
    //                                 textAlign: TextAlign.center,
    //                               ),
    //                             ),
    //                           ],
    //                         ),
                           
    //                      ],
    //                   ),
    //                 ),
    //               ),
    //             );
                    
    //           },
             
    //         ),
    //       ),
    //     );

    //   },
    //   loading: () => const Center(child: CircularProgressIndicator()),  // Show loading spinner while fetching data
    //   error: (e, stack) => Center(child: Text('Error: $e')),  // Display error message if an error occurs
    //   ),
    // );
    
  }

}