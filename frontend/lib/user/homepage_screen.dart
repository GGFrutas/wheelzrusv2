import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/provider/accepted_transaction.dart';
import 'package:frontend/provider/transaction_provider.dart';
import 'package:google_fonts/google_fonts.dart';

class HomepageScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> user;

  const HomepageScreen({super.key, required this.user});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _HomepageScreenState();
}

// List of pastel colors
final List<Color> pastelColors = [
  const Color(0xFFFFD1DC), // Light Pink
  const Color(0xFFFFF4E6), // Light Peach
  const Color(0xFFE6E6FA), // Lavender
  const Color(0xFFFFEBCD), // Blanched Almond
  const Color(0xFFB4E1FF), // Light Blue
  const Color(0xFFBFFCC6), // Mint Green
  const Color(0xFFFFFACD), // Lemon Chiffon
  const Color(0xFFF5D5A4), // Pastel Orange
];

// Function to get a random pastel color
Color getRandomPastelColor() {
  final random = Random();
  return pastelColors[random.nextInt(pastelColors.length)];
}

class _HomepageScreenState extends ConsumerState<HomepageScreen> {
  @override
  Widget build(BuildContext context) {
    final transactionold = ref.watch(bookingProvider);
    final acceptedTransaction = ref.watch(acceptedTransactionProvider);

// Debugging: Print initial lists
    print('Original transaction list: ${transactionold.map((t) => t.id)}');
    print(
        'Accepted transactions list: ${acceptedTransaction.map((a) => a.id)}');

// Filtered list excluding transactions with IDs in acceptedTransaction
    final transaction = transactionold.where((t) {
      final isAccepted =
          acceptedTransaction.any((accepted) => accepted.id == t.id);
      if (isAccepted) {
        print('Excluding transaction with ID: ${t.id}');
      }
      return !isAccepted;
    }).toList();

// Debugging: Print final filtered list
    print('Filtered transaction list: ${transaction.map((t) => t.id)}');

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Wheelzrus',
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: GridView.builder(
          itemCount: transaction.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 1,
            mainAxisSpacing: 20,
            crossAxisSpacing: 20,
            childAspectRatio: 2,
          ),
          itemBuilder: (context, index) {
            // Determine the color based on the status
            Color statusColor;
            switch (transaction[index].status) {
              case 'Ongoing':
                statusColor = Colors.orange;
                break;
              case 'Success':
                statusColor = Colors.green;
                break;
              case 'Pending':
              default:
                statusColor = Colors.deepOrangeAccent;
            }

            return Stack(
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  color: getRandomPastelColor().withOpacity(0.75),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 0, vertical: 15),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment
                                  .start, // Align text to the left
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      "Origin : ",
                                      style: GoogleFonts.poppins(
                                        // color: Colors.white,
                                        // fontSize: 15, // Updated font size to 20
                                        fontWeight: FontWeight.w500,
                                      ),
                                      textAlign: TextAlign
                                          .center, // Ensure the text is centered
                                    ),
                                    Text(
                                      transaction[index].location,
                                      style: GoogleFonts.poppins(
                                        // color: Colors.white,
                                        // fontSize: 16, // Updated font size to 20
                                        fontWeight: FontWeight.bold,
                                      ),
                                      textAlign: TextAlign
                                          .center, // Ensure the text is centered
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    Text(
                                      "Destination : ",
                                      style: GoogleFonts.poppins(
                                        // color: Colors.white,
                                        // fontSize: 15, // Updated font size to 20
                                        fontWeight: FontWeight.w500,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    Text(
                                      transaction[index].destination,
                                      style: GoogleFonts.poppins(
                                        // color: Colors.white,
                                        // fontSize: 16, // Updated font size to 20
                                        fontWeight: FontWeight.bold,
                                      ),
                                      textAlign: TextAlign
                                          .center, // Ensure the text is centered
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    Text(
                                      "Delivery : ",
                                      style: GoogleFonts.poppins(
                                        // color: Colors.white,
                                        // fontSize: 15, // Updated font size to 20
                                        fontWeight: FontWeight.w500,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    Text(
                                      transaction[index].eta,
                                      style: GoogleFonts.poppins(
                                        // color: Colors.white,
                                        // fontSize: 16, // Updated font size to 20
                                        fontWeight: FontWeight.bold,
                                      ),
                                      textAlign: TextAlign
                                          .center, // Ensure the text is centered
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          )
                        ],
                      ),
                      // Wrap Row in a Container to add color
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          if (!acceptedTransaction.contains(transaction[index]))
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 45,
                                  vertical: 12,
                                ),
                              ),
                              onPressed: () {
                                ref
                                    .read(acceptedTransactionProvider.notifier)
                                    .addProduct(transaction[index]);
                              },
                              child: Text(
                                'Accept'.toUpperCase(),
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 16, // Updated font size to 20
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign
                                    .center, // Ensure the text is centered
                              ),
                            ),
                          if (!acceptedTransaction.contains(transaction[index]))
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 45,
                                  vertical: 12,
                                ),
                              ),
                              onPressed: () {
                                ref
                                    .read(acceptedTransactionProvider.notifier)
                                    .removeProduct(transaction[index]);
                              },
                              child: Text(
                                'Decline'.toUpperCase(),
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 16, // Updated font size to 20
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign
                                    .center, // Ensure the text is centered
                              ),
                            ),
                          if (acceptedTransaction.contains(transaction[index]))
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 45,
                                  vertical: 12,
                                ),
                              ),
                              onPressed: () {
                                ref
                                    .read(acceptedTransactionProvider.notifier)
                                    .removeProduct(transaction[index]);
                              },
                              child: Text(
                                'Cancel'.toUpperCase(),
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 16, // Updated font size to 20
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign
                                    .center, // Ensure the text is centered
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Positioned status in the upper-right corner
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 0),
                        child: Text(
                          transaction[index].booking,
                          style: GoogleFonts.poppins(
                              // color: Colors.black, // Text color for status
                              fontWeight: FontWeight.bold,
                              fontSize: 22,
                              letterSpacing: 0.9),
                        )),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 36, vertical: 8),
                      decoration: BoxDecoration(
                        color: statusColor, // Background color for status
                        borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(5)),
                      ),
                      child: Text(
                        transaction[index].status,
                        style: GoogleFonts.poppins(
                          color: Colors.white, // Text color for status
                          // fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
