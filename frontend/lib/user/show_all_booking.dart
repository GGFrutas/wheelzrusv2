// ignore_for_file: unused_import, avoid_print, depend_on_referenced_packages, unnecessary_import

import 'dart:convert';
import 'dart:io';

import 'package:animated_toggle_switch/animated_toggle_switch.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/models/transaction_model.dart';
import 'package:frontend/models/week_query.dart';
import 'package:frontend/notifiers/auth_notifier.dart';
import 'package:frontend/notifiers/navigation_notifier.dart';
import 'package:frontend/provider/accepted_transaction.dart' as accepted_transaction;
import 'package:frontend/provider/theme_provider.dart';
import 'package:frontend/provider/transaction_list_notifier.dart';
import 'package:frontend/provider/transaction_provider.dart';
import 'package:frontend/screen/navigation_menu.dart';
import 'package:frontend/theme/colors.dart';
import 'package:frontend/theme/text_styles.dart';
import 'package:frontend/user/confirmation.dart';
import 'package:frontend/user/transaction_details.dart';
import 'package:frontend/util/transaction_utils.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;

/// Wraps a group of legs that belong to the same freight booking
/// (same freightBookingNumber) so they can be rendered as a single tile.
class _GroupedBookingTransaction {
  final Transaction representative;
  final List<Transaction> legs; // all legs in this group (1 normally, 2 when merged)
  final List<String> requestNumbers;
  final bool isMerged;
  // True when this booking has 2 legs total (same freightBookingNumber)
  // even if only one of them currently qualifies for this week's filter —
  // e.g. its sibling already progressed to Ongoing/Completed and dropped
  // out of the status filter here.
  final bool cameFromMergedBooking;

  _GroupedBookingTransaction({
    required this.representative,
    required this.legs,
    required this.requestNumbers,
    required this.isMerged,
    required this.cameFromMergedBooking,
  });

  /// When two legs of the same freight booking are merged, show a fixed
  /// label depending on dispatch type: "ot" bookings pair Deliver
  /// Empty/Pickup Laden legs, "dt" bookings pair Deliver Laden/Pickup Empty
  /// legs. Otherwise fall back to the single leg's own name.
  String get displayName {
    if (!isMerged) return representative.name ?? '';
    return representative.dispatchType == 'dt'
        ? 'Deliver Laden - Pickup Empty'
        : 'Deliver Empty - Pickup Laden';
  }

  /// True only for the "orphaned" case: this booking has 2 legs total, but
  /// only this one is currently showing on its own — not when both legs are
  /// shown together (isMerged), and not for a genuine standalone booking
  /// that was never paired with a sibling at all.
  bool get isLeftoverFromMerge => cameFromMergedBooking && !isMerged;
}

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

  late final List<String> tabTitles;

  final ScrollController _scrollableController = ScrollController();

  @override
  void initState() {
    super.initState();
    weekStartDates = _generateWeekStartDates();
    tabTitles = [
      'Delayed',
      ...weekStartDates.map((d) => DateFormat('MMM d').format(d)),
    ];
    _expandedTabIndex = 1;
    _scrollableController.addListener(() {
      final state = ref.read(paginatedTransactionProvider('all-bookings'));
      if (_scrollableController.position.pixels >=
              _scrollableController.position.maxScrollExtent - 200 &&
          !state.isLoading &&
          state.hasMore) {
        ref.read(paginatedTransactionProvider('all-bookings').notifier).fetchNextPage();
      }
    });
  }
  

  List<DateTime> _generateWeekStartDates() {
    DateTime now = DateTime.now();

    // Normalize to midnight
    DateTime today = DateTime(now.year, now.month, now.day);

    // Find the most recent Sunday
    int daysSinceSunday = today.weekday % 7;
    DateTime thisSunday = today.subtract(Duration(days: daysSinceSunday));

    // Generate current + next 4 Sundays (5 weeks total)
    return List.generate(5, (i) => thisSunday.add(Duration(days: i * 7)));

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
  Future<bool> hasInternetConnection() async {
    try {
      final response = await http.get(Uri.parse("https://www.google.com"));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
 Future<void> _refreshTransaction() async {
    print("Refreshing transactions");
    final hasInternet = await hasInternetConnection();
    if (!hasInternet) {
      print("No internet connection. Cannot refresh.");
      return;
    }
    try {
      ref.invalidate(bookingProvider);
   
      final future = ref.refresh(allTransactionProvider.future);

      await future;
      print("REFRESHED!");
    }catch (e){
      print('DID NOT REFRESHED!');
    }
  }

   bool sameWeekRange(DateTime? target, DateTime weekStart) {
    // Get the start of the week for both dates
    if (target == null) return false; // Handle null target date
    final weekEnd = weekStart.add(const Duration(days: 6));
    return !target.isBefore(weekStart) && !target.isAfter(weekEnd);
   }



  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d');
    final tabTitles = [
      'Delayed',
      ...weekStartDates.map((d) => dateFormat.format(d)),
    ];
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
                        tabTitles[index],
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
              _expandedTabIndex == 0
              ? Expanded(child: _buildWeekContent(isDelayed: true))
              : Expanded(child: _buildWeekContent(
                  date: weekStartDates[_expandedTabIndex! - 1],
                ))
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


  Widget _buildWeekContent({DateTime? date, bool isDelayed = false}){ {
    final allTransaction = ref.watch(allTransactionFilteredProvider);
    final acceptedTransaction = ref.watch(accepted_transaction.acceptedTransactionProvider);
 
    print("Tab index: $_expandedTabIndex, isDelayed: $isDelayed, date: $date");
    return Expanded(
      child: RefreshIndicator(
        onRefresh: _refreshTransaction,
        child: allTransaction.when(
          data: (transactionList) {
            // If transactionList is null, we ensure it's an empty list to prevent errors
            
            final validTransactionList = transactionList;

            print("Valid Transaction List: ${validTransactionList.length}");

            // If there are no transactions, show a message
            if (validTransactionList.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(), // Allow scrolling even if the list is empty
                children: [
                  Container(
                    height: MediaQuery.of(context).size.height * 0.6, // Enough height to allow pull gesture
                    alignment: Alignment.center,
                    child: Text(
                     isDelayed ? 'No delayed transactions available.' :
                      'No transaction for this week.',
                      style: AppTextStyles.subtitle,
                    ),
                  ),
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

            final expandedTransactions = TransactionUtils.expandTransactions(
              transaction,
              driverId ?? '',
            );

          

            final filteredForWeek = expandedTransactions.where((tx) {
              final isOngoing = [
                "Accepted",
                "Pending",
                "Assigned",
              ].contains(tx.requestStatus);

              final notCancelled = tx.stageId != "Cancelled";

              if (!isOngoing || !notCancelled) return false;

              // Safely parse the string to DateTime
              try {
                final rawDate = tx.dispatchType == "ot" ? tx.pickupDate : tx.deliveryDate;
                if(rawDate == null || rawDate.isEmpty) return false;
                final isoDate = rawDate.replaceFirst(' ', 'T');
                DateTime selectedDate = DateTime.parse(isoDate).add(const Duration(hours: 8));

                selectedDate = DateTime(selectedDate.year, selectedDate.month,selectedDate.day);

                final firstWeekStart = DateTime(weekStartDates.first.year,weekStartDates.first.month,weekStartDates.first.day);

                // ✅ If delayed, check if any date is before week start
                if (isDelayed) {
                  return selectedDate.isBefore(firstWeekStart);
                } else {
                  // Check if any date falls in the same week
                  return sameWeekRange(selectedDate, DateTime(date!.year,date.month, date.day));
                }
              } catch (_) {
                return false;
              }
            }).toList();

            // --- Merge legs that belong to the same freight booking ---
            // Same logic as the Homepage: group by the booking's original
            // name (bookingRefNo holds the raw booking "name" from before
            // expandTransaction overwrites it per-leg, so both legs of the
            // same booking always share it) so both legs of a booking
            // assigned to this driver render as one tile instead of two.
            final Map<String, List<Transaction>> grouped = {};
            for (final tx in filteredForWeek) {
              final key = tx.bookingRefNo?.toString() ??
                  'no-booking-${tx.id}-${tx.requestNumber}';
              grouped.putIfAbsent(key, () => []).add(tx);
            }

            // Total leg count per booking across ALL expanded legs (not
            // just the ones passing this week's status filter) — catches
            // the case where one leg already moved on to Ongoing/Completed
            // and dropped out of filteredForWeek, leaving only its sibling
            // visible here as a seemingly "single" tile.
            final Map<String, int> totalLegCountByBooking = {};
            for (final tx in expandedTransactions) {
              final key = tx.bookingRefNo?.toString() ??
                  'no-booking-${tx.id}-${tx.requestNumber}';
              totalLegCountByBooking[key] = (totalLegCountByBooking[key] ?? 0) + 1;
            }

            final ongoingTransactions = grouped.entries.map((entry) {
              final key = entry.key;
              final group = entry.value;
              // Legs only differ by assignedDate/requestNumber; use the
              // most recently assigned leg as the tile's representative.
              group.sort((a, b) {
                final dA = DateTime.tryParse(a.assignedDate ?? '') ?? DateTime(0);
                final dB = DateTime.tryParse(b.assignedDate ?? '') ?? DateTime(0);
                return dB.compareTo(dA);
              });

              final requestNumbers = group
                  .map((t) => t.requestNumber?.toString())
                  .where((s) => s != null && s.isNotEmpty)
                  .cast<String>()
                  .toSet()
                  .toList();

              return _GroupedBookingTransaction(
                representative: group.first,
                legs: group,
                requestNumbers: requestNumbers,
                isMerged: group.length > 1,
                cameFromMergedBooking: (totalLegCountByBooking[key] ?? group.length) > 1,
              );
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
                            isDelayed ? 'No delayed transactions available.' :
                      'No transaction for this week.',
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
              // controller: _scrollableController,
              itemCount: ongoingTransactions.length,
              itemBuilder: (context, index) {
                final group = ongoingTransactions[index];
                final item = group.representative;
                return Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    // Flags a tile whose sibling leg already moved on
                    // elsewhere (Ongoing/Completed) and is no longer visible
                    // together here — status never unifies across a merged
                    // pair, so this is the only visual cue it's "half" of a
                    // booking, not a standalone one.
                    // color: group.isLeftoverFromMerge
                    //     ? const Color(0xFFFBC926)
                    //     : mainColor,
                        color:mainColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: InkWell(
                    onTap: () async {
                      final navigator = Navigator.of(context);
                      final hasInternet = await hasInternetConnection();
                      if(!navigator.mounted) return;
                      if (hasInternet) {
                        navigator.push(
                          MaterialPageRoute(
                            builder: (context) => TransactionDetails(
                              transaction: item,
                              legs: group.legs,
                              id: item.id,
                              uid: widget.uid,
                            ),
                          ),
                        );
                      } else {
                        navigator.push(
                          MaterialPageRoute(
                            builder: (context) => ConfirmationScreen(
                              transaction: item,
                              id: item.id,
                              uid: widget.uid, relatedFF: null, requestNumber: null,
                            ),
                          ),
                        );
                      }

                      
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
                                      group.displayName,
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
                                          "Bkg Ref. No.: ",
                                          style: AppTextStyles.caption.copyWith(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                            color: Colors.white,
                                          ),
                                        ),
                                        Flexible(
                                          child: Text(
                                            (item.freightBookingNumber?.toString() ?? 'N/A'),
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
                                          "Request Number: ",
                                          style: AppTextStyles.caption.copyWith(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                            color: Colors.white,
                                          ),
                                        ),
                                        Flexible(
                                          child: Text(
                                            (group.requestNumbers.isNotEmpty
                                                ? group.requestNumbers.join(', ')
                                                : 'No Request Number Available'),
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
          error: (err, stack) => RefreshIndicator (
            onRefresh: _refreshTransaction,
            child: Center(
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.all(16),
                  child: Text(
                    err is Exception
                    ? err.toString().replaceFirst('Exception: ', '')
                    : err.toString(),
                    style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.bold
                    ),
                    textAlign: TextAlign.center,
                  )
                )
              )
            )
          )
        ),  
      )
    );
  }
  }

}