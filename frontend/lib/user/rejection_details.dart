import 'package:flutter/material.dart';
import 'package:frontend/models/transaction_model.dart'; // Import your model file
// import 'package:frontend/provider/accepted_transaction.dart';
// import 'package:frontend/user/transaction_screen.dart';
import 'package:google_fonts/google_fonts.dart';




class RejectionDetails extends StatelessWidget {
  final Transaction? transaction; // Keep it nullable
  final String uid; // Add a field for uid

  // Constructor to accept the nullable Transaction object
  const RejectionDetails({super.key, required this.transaction, required int id, String? requestNumber, required this.uid});

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
          style: GoogleFonts.montserrat(
            fontSize: 24,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF1d3c34),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white), 
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Colors.white),
            onPressed: () {
              // Handle notification tap
            },
          ),
        ],
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
                style: GoogleFonts.montserrat(
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
                        "Booking Reference No: ",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                        textAlign: TextAlign
                            .center, // Ensure the text is centered
                      ),
                      Text(
                        " ${(transaction?.bookingRefNo)}",
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
                          style: GoogleFonts.montserrat(
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
                          " ${getNullableValue(transaction?.transportForwarderName)}",
                          style: GoogleFonts.montserrat(
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
                          style: GoogleFonts.montserrat(
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
                          style: GoogleFonts.montserrat(
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
                          " No data",
                          style: GoogleFonts.montserrat(
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
                          " No data",
                          style: GoogleFonts.montserrat(
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
                style: GoogleFonts.montserrat(
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
                style: GoogleFonts.montserrat(
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
                style: GoogleFonts.montserrat(
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
                ],
              ),
            ),
          ],
        ),
        
      ),
      
    );
  }
}
