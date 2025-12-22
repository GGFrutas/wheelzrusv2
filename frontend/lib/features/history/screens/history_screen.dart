// ignore_for_file: unused_import, avoid_print

import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_custom_clippers/flutter_custom_clippers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/features/history/helpers/history_helpers.dart';
import 'package:frontend/features/history/helpers/history_transaction_builder.dart';
import 'package:frontend/features/history/widgets/history_list.dart';
import 'package:frontend/models/consolidation_model.dart';
import 'package:frontend/models/consolidation_extension.dart';
import 'package:frontend/models/driver_reassignment_model.dart';
import 'package:frontend/models/milestone_history_model.dart';
import 'package:frontend/models/transaction_model.dart';
import 'package:frontend/notifiers/auth_notifier.dart';
import 'package:frontend/provider/accepted_transaction.dart' as accepted_transaction;
import 'package:frontend/provider/reject_provider.dart';
import 'package:frontend/provider/transaction_list_notifier.dart';
import 'package:frontend/provider/transaction_provider.dart';
import 'package:frontend/theme/colors.dart';
import 'package:frontend/theme/text_styles.dart';
import 'package:frontend/user/history_details.dart';
import 'package:frontend/user/rejection_details.dart';
import 'package:frontend/features/history/screens/show_all_history.dart';
import 'package:frontend/user/transaction_details.dart';
import 'package:frontend/util/network_utils.dart';
import 'package:frontend/util/transaction_utils.dart';
import 'package:frontend/views/transaction_view.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
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
 
 final bool _hasInternet = true;

  


@override
  void initState() {
    super.initState();
    Future.microtask(() {
    
      setState(() {
        _futureTransactions = ref.read(filteredItemsProviderForHistoryScreen.future);
      });
    });
  }

  Future<void> _refreshTransactions() async {
    if (!_hasInternet) return;
    try {
      ref.invalidate(filteredItemsProviderForHistoryScreen);
      final freshFuture = ref.read(filteredItemsProviderForHistoryScreen.future);
      setState(() => _futureTransactions = freshFuture);
    } catch (e) {
      print("Failed to refresh transactions: $e");
    }
  }

  

  
  
  @override
  Widget build(BuildContext context) {

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
                onRefresh: _refreshTransactions,
                child: FutureBuilder<List<Transaction>>(
                  future: _futureTransactions,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      final message = snapshot.error.toString().replaceFirst('Exception: ', '');
                      return RefreshIndicator (
                        onRefresh: _refreshTransactions,
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
                   
                    final authPartnerId = ref.watch(authNotifierProvider).partnerId;
                    final driverName = ref.watch(authNotifierProvider).driverName?.toString() ?? '';

                    final allTransactions = HistoryTransactionBuilder.build(
                      transactionList: transactionList,
                      driverId: authPartnerId!.toString(),
                      currentDriverName: driverName,
                    );


                   

                    final recent5Transactions = allTransactions
                      .where((tx) {
                        if (tx.isReassigned == true) return true; // always include reassigned
                        return ['Cancelled', 'Completed'].contains(tx.stageId) ||
                            ['Backload', 'Completed'].contains(tx.requestStatus);
                      })
                      .toList()
                    ..sort((a, b) {
                      DateTime getRecentDate(Transaction t) {
                        final completed = DateTime.tryParse(t.completedTime ?? '');
                        final cancelled = DateTime.tryParse(t.writeDate ?? '');
                        final backload = DateTime.tryParse(t.backloadConsolidation?.consolidatedDatetime ?? '');
                        final reassigned = (t.isReassigned == true && (t.reassigned?.isNotEmpty ?? false))
                            ? DateTime.tryParse(t.reassigned!.first.createDate)
                            : null;

                        // prioritize reassignment first, then completed/backload/cancelled
                        return reassigned ?? completed ?? backload ?? cancelled ?? DateTime.fromMillisecondsSinceEpoch(0);
                      }

                      return getRecentDate(b).compareTo(getRecentDate(a)); // descending (most recent first)
                    });

                    final ongoingTransactions = recent5Transactions.take(5).toList();

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
                 

                    return HistoryList(
                      transactions: ongoingTransactions,
                      currentDriverId: authPartnerId.toString(),
                      currentDriverName: driverName,
                      helpers: HistoryHelpers(),
                      onTap: (tx) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>HistoryDetailScreen( transaction: tx, uid: uid ?? '',)
                          )
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




