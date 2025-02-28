import 'package:flutter/material.dart';
import 'package:frontend/models/transaction_model.dart'; // Import your model file
// import 'package:frontend/provider/accepted_transaction.dart';
// import 'package:frontend/user/transaction_screen.dart';
import 'package:google_fonts/google_fonts.dart';




class TransactionDetails extends StatelessWidget {
  final Transaction? transaction; // Keep it nullable

  // Constructor to accept the nullable Transaction object
  const TransactionDetails({Key? key, required this.transaction}) : super(key: key);

  // Helper function to handle null values and provide fallback
  String getNullableValue(String? value, {String fallback = ''}) {
    return value ?? fallback; // If value is null, return fallback
  }

 
  @override
  Widget build(BuildContext context) {
    // If transaction is null, display a fallback message
    if (transaction == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Booking Details"),
        ),
        body: const Center(
          child: Text("No transaction details available."),
        ),
      );
    }

    String originPort = transaction?.dispatchType == 'ot'
    ? transaction?.destination ?? 'N/A'
    : transaction?.dispatchType == 'dt'
        ? transaction?.destination ?? 'N/A' 
        : 'N/A';




    // If transaction is not null, display its details
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "YXE Driver",
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView( // Use ListView to allow scrolling
          children: [
            Container(
              // color: Colors.green[500], // Set background color for this section
              padding: const EdgeInsets.all(8.0),
              child: Text(
                " ${getNullableValue(transaction?.name)}", // Section Title
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16.0), // Add padding inside the container
              
              child: Column( // Use a Column to arrange the widgets vertically
                crossAxisAlignment: CrossAxisAlignment.start, // Align text to the left
                children: [
                  Row(
                    children: [
                      const Text(
                        "Request No: ",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                        textAlign: TextAlign
                            .center, // Ensure the text is centered
                      ),
                      Text(
                        " ${(transaction?.requestNumber)}",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.normal,
                          color: Colors.black,
                        ),
                        textAlign: TextAlign
                            .center, // Ensure the text is centered
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Text(
                        "Port: ",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                        textAlign: TextAlign
                            .center, // Ensure the text is centered
                      ),
                      Flexible(
                        child: Text(
                          " $originPort",
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w500,
                          ),
                          softWrap: true, // Text will wrap if it's too long
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Text(
                        "Freight Forwarder: ",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                        textAlign: TextAlign
                            .center, // Ensure the text is centered
                      ),
                      Flexible(
                        child: Text(
                          " ${getNullableValue(transaction?.freightForwarderName)}",
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w500,
                          ),
                          softWrap: true, // Text will wrap if it's too long
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Text(
                        "Pickup Address: ",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                        textAlign: TextAlign
                            .center, // Ensure the text is centered
                      ),
                      Flexible(
                        child: Text(
                          " ${(transaction?.destination)}",
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w500,
                          ),
                          softWrap: true, // Text will wrap if it's too long
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Text(
                        "Delivery Address: ",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                        textAlign: TextAlign
                            .center, // Ensure the text is centered
                      ),
                      Flexible(
                        child: Text(
                          " ${(transaction?.origin)}",
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w500,
                          ),
                          softWrap: true, // Text will wrap if it's too long
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                   Row(
                    children: [
                     const Text(
                        "Contact Person: ",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                        textAlign: TextAlign
                            .center, // Ensure the text is centered
                      ),
                      Flexible(
                        child: Text(
                          " to be continued",
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w500,
                          ),
                          softWrap: true, // Text will wrap if it's too long
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                   Row(
                    children: [
                     const Text(
                        "Contact Person No: ",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                        textAlign: TextAlign
                            .center, // Ensure the text is centered
                      ),
                      Flexible(
                        child: Text(
                          " to be continued",
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w500,
                          ),
                          softWrap: true, // Text will wrap if it's too long
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            //SECOND BOX
            Container(
              // color: Colors.green[500], // Set background color for this section
              padding: const EdgeInsets.all(8.0),
              child: Text(
                "Freight and Container Info", // Section Title
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16.0), // Add padding inside the container
              
              child: Column( // Use a Column to arrange the widgets vertically
                crossAxisAlignment: CrossAxisAlignment.start, // Align text to the left
                children: [
                  Row(
                    children: [
                      const Text(
                        "Freight Booking No: ",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                        textAlign: TextAlign
                            .center, // Ensure the text is centered
                      ),
                      Text(
                        " ${getNullableValue(transaction?.freightBookingNumber)}",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.normal,
                          color: Colors.black,
                        ),
                        textAlign: TextAlign
                            .center, // Ensure the text is centered
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Text(
                        "Bill of Lading No: ",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                        textAlign: TextAlign
                            .center, // Ensure the text is centered
                      ),
                      Text(
                        " ${getNullableValue(transaction?.freightBlNumber)}",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.normal,
                          color: Colors.black,
                        ),
                        textAlign: TextAlign
                            .center, // Ensure the text is centered
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Text(
                        "Container No: ",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                        textAlign: TextAlign
                            .center, // Ensure the text is centered
                      ),
                      Text(
                        " ${getNullableValue(transaction?.sealNumber)}",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.normal,
                          color: Colors.black,
                        ),
                        textAlign: TextAlign
                            .center, // Ensure the text is centered
                      ),
                    ],
                  ),
                const SizedBox(height: 8),
                  Row(
                    children: [
                      const Text(
                        "Container Seal No: ",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                        textAlign: TextAlign
                            .center, // Ensure the text is centered
                      ),
                      Text(
                        " ${getNullableValue(transaction?.sealNumber)}",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.normal,
                          color: Colors.black,
                        ),
                        textAlign: TextAlign
                            .center, // Ensure the text is centered
                      ),
                    ],
                  ),
                ],
              ),
            ),
            //THIRD BOX
            Container(
              // color: Colors.green[500], // Set background color for this section
              padding: const EdgeInsets.all(8.0),
              child: Text(
                "Schedules", // Section Title
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16.0), // Add padding inside the container
              
              child: Column( // Use a Column to arrange the widgets vertically
                crossAxisAlignment: CrossAxisAlignment.start, // Align text to the left
                children: [
                  Row(
                    children: [
                      const Text(
                        "Pick-up Schedule: ",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                        textAlign: TextAlign
                            .center, // Ensure the text is centered
                      ),
                      Text(
                        " ${getNullableValue(transaction?.arrivalDate)}",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.normal,
                          color: Colors.black,
                        ),
                        textAlign: TextAlign
                            .center, // Ensure the text is centered
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Text(
                        "Delivery Schedule: ",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                        textAlign: TextAlign
                            .center, // Ensure the text is centered
                      ),
                      Text(
                        " ${getNullableValue(transaction?.deliveryDate)}",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.normal,
                          color: Colors.black,
                        ),
                        textAlign: TextAlign
                            .center, // Ensure the text is centered
                      ),
                    ],
                  ),
                ],
              ),
            ),
            //MILESTONE
            Container(
              // color: Colors.green[500], // Set background color for this section
              padding: const EdgeInsets.all(8.0),
              child: Text(
                "Milestones", // Section Title
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16.0), // Add padding inside the container
              
              child: Column( // Use a Column to arrange the widgets vertically
                crossAxisAlignment: CrossAxisAlignment.start, // Align text to the left
                children: [
                  Row(
                    children: [
                      const Text(
                        "Pick-up Empty: ",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                        textAlign: TextAlign
                            .center, // Ensure the text is centered
                      ),
                      Text(
                        " ${getNullableValue(transaction?.arrivalDate)}",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.normal,
                          color: Colors.black,
                        ),
                        textAlign: TextAlign
                            .center, // Ensure the text is centered
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Text(
                        "Delivery Empty: ",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                        textAlign: TextAlign
                            .center, // Ensure the text is centered
                      ),
                      Text(
                        " ${getNullableValue(transaction?.deliveryDate)}",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.normal,
                          color: Colors.black,
                        ),
                        textAlign: TextAlign
                            .center, // Ensure the text is centered
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Button Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      
                      ElevatedButton(
                        onPressed: () {
                          if (transaction?.requestStatus == 'Accepted') {
                            // Navigate to another screen or perform a different action for accepted transactions
                            // Navigator.push(
                            //   context,
                            //   MaterialPageRoute(
                            //     builder: (context) => TransactionScreen(user: user),
                            //   ),
                            // );
                            print("SUCCESS");
                          } else {
                            // Perform the original action for non-accepted transactions
                            // ref.read(acceptedTransactionProvider.notifier).addProduct(transaction);
                            print("FAILED");
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: transaction?.requestStatus == 'Accepted'
                              ? const Color.fromARGB(255, 244, 176, 74) // Example color for accepted status
                              : const Color.fromARGB(255, 244, 176, 74), // Default color
                        ),
                        child: Text(
                          transaction?.requestStatus == 'Accepted'
                              ? 'Proof of Delivery'.toUpperCase() // New label for accepted transactions
                              : 'Accept'.toUpperCase(), // Default label
                          style: GoogleFonts.poppins(
                            color: Colors.black,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (transaction?.requestStatus != 'Accepted') // Conditional rendering for Reject button
                        ElevatedButton(
                          onPressed: () {
                            // Handle Reject
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color.fromARGB(255, 255, 0, 0), // Set the button color to red
                          ),
                          child: Text(
                            'Reject'.toUpperCase(),
                            style: GoogleFonts.poppins(
                              color: Colors.white, // White text color
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        
      ),
      
    );
  }
}
