// ignore_for_file: unused_import, avoid_print, depend_on_referenced_packages, unnecessary_import

import 'dart:convert';
import 'dart:io';

import 'package:animated_toggle_switch/animated_toggle_switch.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/features/history/helpers/history_helpers.dart';
import 'package:frontend/features/history/helpers/history_transaction_builder.dart';
import 'package:frontend/features/history/widgets/history_list.dart';
import 'package:frontend/models/milestone_history_model.dart';
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
import 'package:frontend/util/network_utils.dart';
import 'package:frontend/util/transaction_utils.dart';
import 'package:http/http.dart' as http;
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
      _futureTransactions = ref.read(filteredItemsProviderForHistoryScreen.future);
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
    final hasInternet = await hasInternetConnection();
    if(!hasInternet){
      print("disabled refresh");
      return;
    }
    try {
      ref.invalidate(allHistoryProvider);
      setState(() {
        _futureTransactions = ref.read(filteredItemsProviderForHistoryScreen.future);
      });
      print("REFRESHED!");
    } catch (e) {
      print('DID NOT REFRESH!');
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

                    final authPartnerId = ref.watch(authNotifierProvider).partnerId;
                    final driverName = ref.watch(authNotifierProvider).driverName?.toString() ?? '';

                    final allTransactions = HistoryTransactionBuilder.build(
                      transactionList: transactionList,
                      driverId: authPartnerId!.toString(),
                      currentDriverName: driverName,
                    );

                    final ongoingTransactions = allTransactions
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