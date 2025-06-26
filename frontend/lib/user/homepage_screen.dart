
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
import 'package:frontend/theme/colors.dart';
import 'package:frontend/theme/text_styles.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:frontend/user/transaction_details.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:carousel_slider/carousel_slider.dart';


class HomepageScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> user;
  final int initialIndex;

  const HomepageScreen({this.initialIndex = 0, super.key, required this.user});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _HomepageScreenState();
}

class _HomepageScreenState extends ConsumerState<HomepageScreen> {
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

   final List<Map<String, String>> carouselItems = [
    {
      "title": "Start Driving Smarter Today.",
      "subtitle": "From Booking to Delivery — Seamless",
      "image": "assets/hand-drawn-transportation-truck-with-delivery-man.png",
      "color": "#1C7E7B"
    },
    {
      "title": "More Cargo. More Miles.More Pay.",
      "subtitle": "Book shipments. Accept jobs. Drive your way",
      "image": "assets/illustrated-transport-truck-delivery-side-view-front-view-red-color-delivery-truck.png",
      "color": "#2D906F"
    },
    {
      "title": "Loads at your fingertips.",
      "subtitle": "Browse, accept, and deliver — all in one app",
      "image": "assets/box-truck-with-delivery-man-standing-it-vector-illustration.png",
      "color": "#40CA9C"
    },
    {
      "title": "All your Drivers need. In One App.",
      "subtitle": "Booking, tracking, payments, and support.",
      "image": "assets/delivery-truck-boxes-with-isometric-style.png",
      "color": "#7DE4C2"
    },
  ];
  
  
  
  @override
  Widget build(BuildContext context) {
     
    final transactionold = ref.watch(filteredItemsProvider);
    
    final acceptedTransaction = ref.watch(accepted_transaction.acceptedTransactionProvider);
     final uid = ref.read(authNotifierProvider).uid;

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
                child: Center(
                  child: Text(
                    'No pending transactions available.',
                    style: AppTextStyles.subtitle,
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
            DateTime dateA = DateTime.tryParse(a.deliveryDate) ?? DateTime(0);
            DateTime dateB = DateTime.tryParse(b.deliveryDate) ?? DateTime(0);
            return dateB.compareTo(dateA);
          });

          final ongoingTransactions = expandedTransactions
            .where((tx) => tx.requestStatus == "Pending")
            .toList();

          return Scaffold(
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Column(
                        children: [
                          // 🚚 Carousel
                          CarouselSlider(
                            items: carouselItems.map((item) {
                              return Card(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                margin: const EdgeInsets.symmetric(horizontal: 8),
                                color: Color(int.parse(item['color']!.replaceFirst('#', '0xff'))),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    children: [
                                      // 📝 Text column — don't constrain title
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              item['title']!,
                                              style: AppTextStyles.subtitle.copyWith(
                                                color: Colors.white,
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(height: 10),
                                            Flexible(
                                              child: Text(
                                                item['subtitle']!,
                                                style: AppTextStyles.caption.copyWith(
                                                  color: Colors.white70,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        height: 50,
                                        width: 100,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(12),
                                          image: DecorationImage(
                                            image: AssetImage(item['image']!),
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                            options: CarouselOptions(
                              height: 150,
                              enlargeCenterPage: true,
                              autoPlay: true,
                              viewportFraction: 0.85,
                              autoPlayInterval: const Duration(seconds: 4),
                            ),
                          ),

                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                   
                    // 📦 Grid wrapped in SliverList
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final item = ongoingTransactions[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 20),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => TransactionDetails(
                                        transaction: item,
                                        id: item.id,
                                        uid: uid ?? '',
                                      ),
                                    ),
                                  );
                                },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 14),
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(15),
                                      boxShadow: const [
                                        BoxShadow(
                                          color: mainColor,
                                          spreadRadius: 2,
                                          offset: Offset(0, 3),
                                        ),
                                      ],
                                    ),
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
                                )
                              ),
                            ),
                          );
                        },
                        childCount: ongoingTransactions.length,
                      ),
                    ),
                  ],
                ),
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


