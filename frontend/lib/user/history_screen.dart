// ignore_for_file: unused_import, avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_custom_clippers/flutter_custom_clippers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/models/consolidation_model.dart';
import 'package:frontend/models/consolidation_extension.dart';
import 'package:frontend/models/driver_reassignment_model.dart';
import 'package:frontend/models/milestone_history_model.dart';
import 'package:frontend/models/transaction_model.dart';
import 'package:frontend/notifiers/auth_notifier.dart';
import 'package:frontend/provider/accepted_transaction.dart' as accepted_transaction;
import 'package:frontend/provider/reject_provider.dart';
import 'package:frontend/provider/transaction_provider.dart';
import 'package:frontend/theme/colors.dart';
import 'package:frontend/theme/text_styles.dart';
import 'package:frontend/user/history_details.dart';
import 'package:frontend/user/rejection_details.dart';
import 'package:frontend/user/show_all_history.dart';
import 'package:frontend/user/transaction_details.dart';
import 'package:frontend/util/transaction_utils.dart';
import 'package:frontend/views/transaction_view.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class HistoryScreen extends ConsumerStatefulWidget{
  final Map<String, dynamic> user;
   final Transaction? transaction;
  const HistoryScreen({super.key, required this.user,  this.transaction});

  @override
  // ignore: library_private_types_in_public_api
  _HistoryPageState createState() => _HistoryPageState();
}

class _HistoryPageState extends ConsumerState<HistoryScreen> {
  String? uid;
 Future<List<Transaction>>? _futureTransactions;

Map<String, MilestoneHistoryModel?> getPickupAndDeliverySchedule(Transaction? transaction) {
  // If transaction itself is null, return early
  if (transaction == null) {
    return {
      'pickup': null,
      'delivery': null,
      'email': null,
    };
  }

  final dispatchType = transaction.dispatchType;
  final history = transaction.history ?? [];
  final serviceType = transaction.serviceType;
  final dispatchId = transaction.id?.toString();
  final requestNumber = transaction.requestNumber;

  final fclPrefixes = {
    'ot': {
      'Full Container Load': {
        'de': {'delivery': 'TEOT', 'pickup': 'TYOT'},
        'pl': {'delivery': 'CLOT', 'pickup': 'TLOT', 'email': 'ELOT'},
      },
      'Less-Than-Container Load': {
        'pl': {'delivery': 'LCLOT', 'pickup': 'LTEOT'},
      },
    },
    'dt': {
      'Full Container Load': {
        'dl': {'delivery': 'CLDT', 'pickup': 'GYDT'},
        'pe': {'delivery': 'CYDT', 'pickup': 'GLDT', 'email': 'EEDT'},
      },
      'Less-Than-Container Load': {
        'pl': {'delivery': 'LCLOT', 'pickup': 'LTEOT'},
      },
    },
  };

  final fclCodeMap = {
    'de': transaction.deRequestNumber,
    'pl': transaction.plRequestNumber,
    'dl': transaction.dlRequestNumber,
    'pe': transaction.peRequestNumber,
  };

  // Find which leg matches this transaction
  String? matchingLegs;
  for (final entry in fclCodeMap.entries) {
    if (entry.value != null && entry.value == requestNumber) {
      matchingLegs = entry.key;
      break;
    }
  }

  print("Matching Leg for $requestNumber: $matchingLegs");

  if (matchingLegs == null) {
    return {'pickup': null, 'delivery': null, 'email': null};
  }

  final fclMap = fclPrefixes[dispatchType]?[serviceType]?[matchingLegs];
  if (fclMap == null) {
    return {'pickup': null, 'delivery': null, 'email': null};
  }

  final pickupFcl = fclMap['pickup'];
  final deliveryFcl = fclMap['delivery'];
  final emailFcl = fclMap['email'];

  MilestoneHistoryModel? findSchedule(String? fcl) {
    if (fcl == null) return null;
    try {
      final result = history.firstWhere(
        (h) =>
            h.fclCode.trim().toUpperCase() == fcl.toUpperCase() &&
            h.dispatchId == dispatchId &&
            h.serviceType == serviceType,
      );
      return result;
    } catch (_) {
      return null;
    }

    
  }

  final pickupSchedule = findSchedule(pickupFcl);
  final deliverySchedule = findSchedule(deliveryFcl);
  final emailSchedule = findSchedule(emailFcl);

  return {
    'pickup': pickupSchedule,
    'delivery': deliverySchedule,
    'email': emailSchedule,
  };
}


 @override
void initState() {
  super.initState();
  Future.microtask(() {
    setState(() {
      _futureTransactions = ref.read(filteredItemsProviderForHistoryScreen.future);
    });
  });
}

  Future<void> _refreshTransaction() async {
    print("Refreshing transactions");
    try {
      ref.invalidate(filteredItemsProviderForHistoryScreen);
      setState(() {
        _futureTransactions = ref.read(filteredItemsProviderForHistoryScreen.future);
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
     
  final transaction = widget.transaction;

    final scheduleMap = getPickupAndDeliverySchedule(transaction);

     final delivery = scheduleMap['delivery'];
    
    final acceptedTransaction = ref.watch(accepted_transaction.acceptedTransactionProvider);

    

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
             Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25.0, vertical:10.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'History',
                      style:AppTextStyles.title.copyWith(
                        color: mainColor,
                        fontWeight: FontWeight.bold
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AllHistoryScreen(uid: uid ?? '', transaction: null,),
                          ),
                        );
                      },
                      child: Text (
                        "Show All",
                        style:AppTextStyles.body.copyWith(
                          color: mainColor,
                          fontWeight: FontWeight.bold
                        ),
                      )
                    )
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 3.0),
                child: Divider(
                  color: Colors.grey,
                  thickness: 1,
                ),
              ),


           
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
                      final message = snapshot.error.toString().replaceFirst('Exception: ', '');
                      return RefreshIndicator (
                        onRefresh: _refreshTransaction,
                        child: Center(
                          child: SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              margin: const EdgeInsets.all(16),
                              child: Text(
                                message,
                                style: AppTextStyles.body.copyWith(
                                  fontWeight: FontWeight.bold
                                ),
                                textAlign: TextAlign.center,
                              )
                            )
                          )
                        )
                      );
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
                 
                   
                    final expandedTransactions = TransactionUtils.expandTransactions(
                      transaction,
                      driverId ?? '',
                    );

                 
                    final ongoingTransactions = expandedTransactions
                      .where((tx) =>  ['Cancelled', 'Completed'].contains(tx.stageId) || ['Backload', 'Completed'].contains(tx.requestStatus) || tx.reassignment.any((e) => e.driverId.toString() == driverId)) // include removed
                      .take(5)
                      .toList()
                      ..sort((a,b){
                      DateTime getRecentDate(Transaction t) {
                        final completed = DateTime.tryParse(t.completedTime ?? '');
                        final cancelled = DateTime.tryParse(t.writeDate ?? '');
                        final backload = DateTime.tryParse(t.backloadConsolidation?.consolidatedDatetime ?? '');
                        
                        return completed ?? backload ??cancelled ?? DateTime.fromMillisecondsSinceEpoch(0);

                      }
                      return getRecentDate(b).compareTo(getRecentDate(a));
                    });

                    String getStatusLabel(Transaction item) {
                      final status = item.requestStatus?.trim();
                      final stage = item.stageId?.trim();
                    

                      if (status == 'Completed' || status == 'Backload') return status!;
                      if (stage == 'Completed' || stage == 'Cancelled') return stage!;
                      return '—';
                    }

                    

             
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
                      itemCount: ongoingTransactions.length,
                      itemBuilder: (context, index) {
                        final item = ongoingTransactions[index];
                        final statusLabel = getStatusLabel(item);

                        String getDisplayDate(Transaction item, MilestoneHistoryModel? delivery) {
                          try {
                            if (item.stageId == 'Cancelled') {
                              return separateDateTime(item.writeDate)?['date'] ?? '—';
                            } else if (item.requestStatus == 'Completed') {
                              return separateDateTime(delivery?.actualDatetime)['date'] ?? '—';
                            } else if (item.requestStatus == 'Backload') {
                              return item.backloadConsolidation?.formattedConsolidatedDate ?? '—';
                            }
                          } catch (_) {}
                          return '—';
                        }

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
                                          color: getStatusColor((statusLabel).trim()),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                             (item.requestStatus == 'Completed' || item.requestStatus == 'Backload' || item.stageId == 'Completed')
                                              ? item.requestStatus == 'Backload' ? 'Backloading' : 'Completed'
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
                                             getDisplayDate(item, delivery),

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
                                                  ? separateDateTime(delivery?.actualDatetime)['time'] ?? '—'
                                                 : item.requestStatus == 'Backload'
                                                    ? separateDateTime(item.backloadConsolidation?.consolidatedDatetime)['time'] ?? '—'

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
      ) 
    );
    
  }

}




