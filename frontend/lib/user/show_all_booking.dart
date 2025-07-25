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
import 'package:frontend/user/transaction_details.dart';
import 'package:intl/intl.dart';

class AllBookingScreen extends ConsumerStatefulWidget{
  final String uid;
  final Transaction? transaction; 
  
  const AllBookingScreen( {super.key, required this.uid, required this.transaction});

  @override

  ConsumerState<AllBookingScreen> createState() => _AllBookingPageState();
}

class _AllBookingPageState extends ConsumerState<AllBookingScreen>{
   int? _expandedTabIndex;

  late final List<DateTime> weekStartDates;

  @override
  void initState() {
    super.initState();
    weekStartDates = _generateWeekStartDates();
    _expandedTabIndex =0;
  }

  List<DateTime> _generateWeekStartDates() {
    DateTime now = DateTime.now();
    // Find the most recent Sunday
    int daysSinceSunday = now.weekday % 7; 
    DateTime thisSunday = now.subtract(Duration(days: daysSinceSunday));

    // Generate current + next 3 Sundays (4 weeks total)
    return List.generate(4, (i) => thisSunday.add(Duration(days: i * 7)));
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
  Future<void> _refreshTransaction() async {
    print("Refreshing transactions");
    try {
      
      ref.invalidate(bookingProvider);
      print("REFRESHED!");
    }catch (e){
      print('DID NOT REFRESHED!');
    }
   }

   bool sameWeekRange(DateTime? target, DateTime weekStart) {
    // Get the start of the week for both dates
    if (target == null) return false; // Handle null target date
    final weekEnd = weekStart.add(const Duration(days: 6));
    return target.isAfter(weekStart.subtract(const Duration(days: 1))) &&
        target.isBefore(weekEnd.add(const Duration(days: 1)));
   }



  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d');
    return Scaffold(
      appBar: AppBar(
        title: const Text("All Bookings"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: List.generate(weekStartDates.length, (index) {
                final isSelected = _expandedTabIndex == index;
                final tabColor = isSelected ? mainColor : Colors.grey;

                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _expandedTabIndex = isSelected ? null : index;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: tabColor, width: 2),
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        dateFormat.format(weekStartDates[index]),
                        style: TextStyle(
                          color: tabColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 20),

            if (_expandedTabIndex != null)
             Expanded(child: _buildWeekContent(weekStartDates[_expandedTabIndex!])),
          ],
        ),
      ),
      bottomNavigationBar: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            
            NavigationMenu(),
          ],
          
        )
    );
  }

  Widget _buildWeekContent(DateTime date) {
    final allTransaction = ref.watch(allTransactionProvider);
    final acceptedTransaction = ref.watch(accepted_transaction.acceptedTransactionProvider);
 
    return RefreshIndicator(
        onRefresh: _refreshTransaction,
        child: allTransaction.when(
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
                        'No transaction for this week.',
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
              
              String removeBrackets(String input) {
                          return input.replaceAll(RegExp(r'\s*\[.*?\]'), '')
                                      .replaceAll(RegExp(r'\s*\(.*?\)'), '')
                                      .trim();
                        }
                        String cleanAddress(List<String?> parts) {
                          return parts
                            .where((e) => e != null && e.trim().isNotEmpty && e.trim().toLowerCase() != 'ph')
                            .map((e) => removeBrackets(e!)) // now safe because nulls are filtered above
                            .join(', ');
                        }

                        String buildConsigneeAddress(Transaction item, {bool cityLevel = false}) {
                          return cleanAddress(cityLevel ? [item.consigneeCity,item.consigneeProvince]
                          : [item.consigneeStreet,item.consigneeBarangay,item.consigneeCity,item.consigneeProvince]
                          );
                        }

                        String buildShipperAddress(Transaction item, {bool cityLevel = false}) {
                          return cleanAddress(cityLevel ? [item.shipperCity,item.shipperProvince]
                          : [item.shipperStreet,item.shipperBarangay,item.shipperCity,item.shipperProvince]
                          );
                        }
                        String descriptionMsg(Transaction item) {
                          if (item.landTransport == 'transport'){
                            return 'Deliver Laden Container to Consignee';
                          } else {
                            return 'Pickup Laden Container from Shipper';
                          }
                        }
                        String newName(Transaction item) {
                          if (item.landTransport == 'transport'){
                            return 'Deliver to Consignee';
                          } else {
                            return 'Pickup from Shipper';
                          }
                        }
    
              if (item.dispatchType == "ot") {
                final shipperOrigin = buildShipperAddress(item);
                final shipperDestination = cleanAddress([item.destination]);
                return [
                  // First instance: Deliver to Shipper
                  if (item.deTruckDriverName == driverId) // Filter out if accepted
                    // Check if the truck driver is the same as the authPartnerId
                    item.copyWith(
                      name: "Deliver to Shipper",
                      origin:shipperDestination,
                      destination: shipperOrigin,
                      requestNumber: item.deRequestNumber,
                      requestStatus: item.deRequestStatus,
                      assignedDate:item.deAssignedDate,
                      originAddress: "Deliver Empty Container to Shipper"
                      // truckPlateNumber: item.deTruckPlateNumber,
                    ),
                    // Second instance: Pickup from Shipper
                  if ( item.plTruckDriverName == driverId) // Filter out if accepted
                    // if (item.plTruckDriverName == authPartnerId)
                    item.copyWith(
                      name: newName(item),
                      origin:shipperOrigin,
                      destination:shipperDestination,
                      requestNumber: item.plRequestNumber,
                      requestStatus: item.plRequestStatus,
                      assignedDate:item.plAssignedDate,
                      originAddress: descriptionMsg(item),
                      // truckPlateNumber: item.plTruckPlateNumber,
                    ),
                ];
              } else if (item.dispatchType == "dt") {
                final consigneeOrigin = buildConsigneeAddress(item);
                final consigneeDestination = cleanAddress([item.origin]);
                return [
                  // First instance: Deliver to Consignee
                  if (item.dlTruckDriverName == driverId) // Filter out if accepted
                    item.copyWith(
                      name: "Deliver to Consignee",
                      origin:  consigneeDestination,
                      destination: consigneeOrigin,
                      requestNumber: item.dlRequestNumber,
                      requestStatus: item.dlRequestStatus,
                      assignedDate:item.dlAssignedDate,
                      originAddress: "Deliver Laden Container to Consignee"
                      // truckPlateNumber: item.dlTruckPlateNumber,
                    ),
                  // Second instance: Pickup from Consignee
                  if (item.peTruckDriverName == driverId) // Filter out if accepted
                    item.copyWith(
                      name: "Pickup from Consignee",
                      origin: consigneeOrigin,
                      destination: consigneeDestination,
                      requestNumber: item.peRequestNumber,
                      requestStatus: item.peRequestStatus,
                      assignedDate:item.peAssignedDate,
                      originAddress: "Pickup Empty Container from Consignee"
                      // truckPlateNumber: item.peTruckPlateNumber,
                    ),
                ];  
              }
              // Return as-is if no match
              return [item];
            }).toList();

          

            final ongoingTransactions = expandedTransactions.where((tx) {
              final isOngoing = [
                "Accepted",
                "Pending",
                "Assigned",
              ].contains(tx.requestStatus);

              if (!isOngoing) return false;

              // Safely parse the string to DateTime
              try{
                final dateToCheck = tx.dispatchType == "ot"
                ? DateTime.parse(tx.departureDate)
                : DateTime.parse(tx.arrivalDate); // Handle null dates

                return sameWeekRange(dateToCheck, date);
              }catch(_) {
                return false; // If parsing fails, exclude this transaction
              }
            }).toList();


                  
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
                            'No transactions for this week.',
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
                    color: mainColor,
                    borderRadius: BorderRadius.circular(12),
                    
                  ),
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TransactionDetails(
                            transaction: item,
                            id: item.id,
                            uid: widget.uid,
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
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text (
                                      item.name,
                                      style: AppTextStyles.body.copyWith(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.9,
                                        color: Colors.white,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 2,
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Text(
                                          "Request Number: ",
                                          style: AppTextStyles.caption.copyWith(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                            color: Colors.white,
                                          ),
                                        ),
                                        Flexible(
                                          child: Text(
                                            (item.requestNumber?.toString() ?? 'No Request Number Available'),
                                            style: AppTextStyles.caption.copyWith(
                                              color: Colors.white
                                            ),
                                            softWrap: true, // Text will wrap if it's too long
                                          ),
                                        ),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        Text(
                                          "Date Assigned: ",
                                          style: AppTextStyles.caption.copyWith(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                            color: Colors.white,
                                          ),
                                          
                                        ),
                                        Flexible(
                                          child: Text(
                                            formatDateTime(item.assignedDate),
                                            style: AppTextStyles.caption.copyWith(
                                              color: Colors.white
                                            ),
                                            softWrap: true, // Text will wrap if it's too long
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            
                              const SizedBox(width: 8),
                              const Icon(
                                Icons.chevron_right,
                                color: Color.fromARGB(255, 255, 255, 255),
                                size: 40,
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
      );
    
    
  }

}