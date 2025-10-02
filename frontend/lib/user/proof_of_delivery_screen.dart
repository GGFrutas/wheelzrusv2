// ignore_for_file: unused_import, avoid_print, depend_on_referenced_packages

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
import 'package:frontend/provider/base_url_provider.dart';
import 'package:frontend/provider/theme_provider.dart';
import 'package:frontend/provider/transaction_list_notifier.dart';
import 'package:frontend/provider/transaction_provider.dart';
import 'package:frontend/screen/navigation_menu.dart';
import 'package:frontend/theme/colors.dart';
import 'package:frontend/theme/text_styles.dart';
import 'package:frontend/user/schedule.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:signature/signature.dart';

class ProofOfDeliveryScreen extends ConsumerStatefulWidget{
  final String uid;
  final Transaction? transaction; 
  final List<String> base64Images;
  
  const ProofOfDeliveryScreen({super.key, required this.uid, required this.transaction,required this.base64Images});

  @override

  ConsumerState<ProofOfDeliveryScreen> createState() => _ProofOfDeliveryPageState();
}

class _ProofOfDeliveryPageState extends ConsumerState<ProofOfDeliveryScreen>{
  // final List<File?> _images = [];
  late final String uid;

 String? _enteredName;
  String? _enteredContainerNumber;
   
  final SignatureController _controller = SignatureController(
    penStrokeWidth: 5,
    penColor: Colors.black,
    exportBackgroundColor: Colors.white,
  );
 
 late TextEditingController _containerController;
late String _originalContainerNumber;


  

  Future<void> _printFilenames() async {
   
    Uint8List? signatureImage = await _controller.toPngBytes();
    String? base64Signature = signatureImage != null ? base64Encode(signatureImage) : null;
    final now = DateTime.now();
    final adjustedTime = now.subtract(const Duration(hours: 8));
    final timestamp = DateFormat("yyyy-MM-dd HH:mm:ss").format(adjustedTime);

    String? enteredName = _enteredName;
    // String? enteredContainerNumber = _enteredContainerNumber;
final enteredContainerNumber = (_enteredContainerNumber == null || 
                                 _enteredContainerNumber!.trim().isEmpty || 
                                 _enteredContainerNumber == _originalContainerNumber)
      ? _originalContainerNumber
      : _enteredContainerNumber!.trim();

    if(_controller.isNotEmpty){
      Uint8List? signatureImage = await _controller.toPngBytes();
      if(signatureImage != null){
        base64Signature = base64Encode(signatureImage);
      }
    } 

    String imageToUpload = widget.base64Images[0];

    print("Received Image ${widget.base64Images.length} from the previous screen");
    for (int i = 0; i < widget.base64Images.length; i++) {
      print("Images ${i + 1} (base64, truncated): ${widget.base64Images[i].substring(1, 100)}");
    }

    final currentStatus = widget.transaction!.requestStatus;
    final baseUrl = ref.watch(baseUrlProvider);
    
    print("Entered Name: $enteredName");
     print("Entered Container number: $enteredContainerNumber");
    print("Current Status: $currentStatus");
    Uri url;
  
    String nextStatus;
    if (currentStatus == "Accepted" || currentStatus == "Pending" || currentStatus == "Assigned") {
      nextStatus = "Ongoing";
     url = Uri.parse('$baseUrl/api/odoo/pod-accepted-to-ongoing?uid=$uid');
      nextStatus = "Ongoing";
      

    } else if (currentStatus == "Ongoing") {
      nextStatus = "Completed";
     url = Uri.parse('$baseUrl/api/odoo/pod-ongoing-to-complete?uid=$uid');
    } else {
      if (!mounted) return;
      showSuccessDialog(context, "Invalid transaction!");
      return;
    }

    var response = await http.post(url,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'password': ref.read(authNotifierProvider).password ?? '',
        'login':ref.watch(authNotifierProvider).login ?? ''
      },
      body: jsonEncode({
        'id': widget.transaction?.id,
        'newStatus': nextStatus,
        'signature': base64Signature,
        'images': imageToUpload,
        'dispatch_type': widget.transaction?.dispatchType,
        'request_number': widget.transaction?.requestNumber,
        'timestamp': timestamp,
        'enteredName': enteredName,
        'enteredContainerNumber': enteredContainerNumber
      }),
    );
    print("Response status code: ${response.statusCode}");
    
    print('Posting to: $url for status update to $nextStatus');
    if (!mounted) return;
    if (response.statusCode == 200) {
      print("Files uploaded successfully!");
      print("Response body: ${response.body}");
      final ongoingTransactionNotifier = ref.read(accepted_transaction.acceptedTransactionProvider.notifier);

      if (currentStatus == "Accepted" || currentStatus == "Pending") {
        await ongoingTransactionNotifier.updateStatus(
          widget.transaction!.id.toString(),
          widget.transaction!.requestNumber.toString(),
          "Ongoing", 
          ref,
          context
        );
      } else if (currentStatus == "Ongoing") {
        await ongoingTransactionNotifier.updateStatus(
          widget.transaction!.id.toString(),
          widget.transaction!.requestNumber.toString(),
          "Completed", 
          ref,
          context
        );
      }
     
      final updatedTransaction = ref
        .read(ongoingTransactionProvider)
        .firstWhere(
          (t) =>
              t.id.toString() == widget.transaction!.id.toString() &&
              t.requestNumber == widget.transaction!.requestNumber.toString(),
          orElse: () => widget.transaction!,
        );

      print('Updated to Ongoing: ${updatedTransaction.requestStatus}');
      if (!mounted) return;
      Navigator.of(context).pop(); // Close the loading dialog
      showSuccessDialog(context, "Success!");
      
    } else {
      showSuccessDialog(context, "Failed to upload files!");
      print("Failed to upload files: ${response.statusCode}");
    }

    
  }

 @override
void initState() {
  super.initState();
  uid = ref.read(authNotifierProvider).uid ?? '';

  _controller.addListener(() {
    if (mounted) {
      setState(() {});
    }
  });

  _originalContainerNumber = widget.transaction?.containerNumber ?? '';
  _containerController = TextEditingController(text: _originalContainerNumber);
}


  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  
  @override
  Widget build(BuildContext context) {


    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        iconTheme: const IconThemeData(color: mainColor),
        backgroundColor: bgColor,
      ),
      body: SingleChildScrollView (

        padding: const EdgeInsetsDirectional.only(top: 10),
        
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          
          children: [
            Text(
              widget.transaction?.requestStatus == "Accepted" ? 'Released By:'
              : widget.transaction?.requestStatus == "Ongoing" ? 'Received By:'
              : "Released By:",
              style: AppTextStyles.subtitle.copyWith(
                color: mainColor
              ),
            ),
            const SizedBox(height: 10),
            Container (
              width: MediaQuery.of(context).size.width * 0.9,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
              child: TextField(
                onChanged: (val){
                  setState(() {
                    _enteredName = val;
                  });
                },
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  hintText: 'Enter name',
                  hintStyle: AppTextStyles.body, // Use caption style for hint text
                ),
              ),
            ),
           const SizedBox(height: 20),
           if(widget.transaction?.requestNumber == widget.transaction?.deRequestNumber) ... [
            Text(
              "Container Number: ",
              style: AppTextStyles.subtitle.copyWith(
                color: mainColor
              ),
            ),
            
             const SizedBox(height: 10),
            Container (
              width: MediaQuery.of(context).size.width * 0.9,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
              child: TextField(
                onChanged: (val){
                  setState(() {
                    _enteredContainerNumber = val;
                  });
                },
                enabled: (widget.transaction?.containerNumber ?? '').isEmpty,
                controller: _containerController,
                decoration: InputDecoration(
                border: const OutlineInputBorder(),
                label: (widget.transaction?.containerNumber ?? '').isEmpty
                  ? RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: 'Enter container number ',
                            style: AppTextStyles.body,
                          ),
                          TextSpan(
                            text: '(optional)',
                            style: AppTextStyles.caption.copyWith(
                              fontStyle: FontStyle.italic,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                    )
                  : Text(
                      '',
                      style: AppTextStyles.body,
                    ),

              ),

              ),
            ),
           ],
            
          
           const SizedBox(height: 20),
            Text(
              'Please provide your signature below:',
              style: AppTextStyles.subtitle.copyWith(
                color: mainColor
              ),
            ),
            const SizedBox(height: 20),
            Signature(
              controller: _controller,
              width: MediaQuery.of(context).size.width * 0.9,
              height: 150,
              backgroundColor: Colors.white,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                _controller.clear();
                setState(() {});

              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)
                ),
              ),
              child: Text(
                'Clear Signature',
                style: AppTextStyles.body.copyWith(
                  color: mainColor
                )
              )
            ),
           
          ],
          
        ),
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed:() async {
                      final missingSignature = _controller.isEmpty;
                      final missingName =  _enteredName == null || _enteredName!.trim().isEmpty;
                      if (missingSignature || missingName) {
                        String message = '';
                        if (missingSignature && missingName){
                          message = 'Please enter a name and provide signature.';
                        }else if (missingName) {
                          message = 'Please enter a name.';
                        }else if(missingSignature) {
                          message = 'Please provide a signature.';
                        }
                        showDialog(
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                              title: Text(
                                'Submission Error!', 
                                style: AppTextStyles.subtitle.copyWith(
                                  fontWeight: FontWeight.bold
                                ),
                                textAlign: TextAlign.center,
                              ),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    message,
                                    style: AppTextStyles.body.copyWith(
                                      color: Colors.black87
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 16),
                                  const Icon (
                                    Icons.edit,
                                    color: bgColor,
                                    size: 100
                                  )
                                ],
                              ),
                              actions: [
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 12.0),
                                  child: Center(
                                    child: SizedBox(
                                      width: 200,
                                      child: ElevatedButton(
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                      }, 
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red,
                                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(25),
                                        ),
                                      ),
                                      child: Text(
                                        "Try Again",
                                        style: AppTextStyles.body.copyWith(
                                          color: Colors.white,
                                        )
                                      )
                                    ),
                                    )
                                  )
                                )
                              ],
                            );
                          }
                        );
                      } else {

                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder:(context) {
                            return const Center (
                              child: CircularProgressIndicator(),
                            );
                          },
                        );
                        try {
                          print("UID: ${widget.uid}");
                          print("Request Number: ${widget.transaction?.requestNumber}");
                          print("Request Number: ${widget.transaction?.requestStatus}");
                          print("Entered Name: $_enteredName");
                          print("Entered Container: $_enteredName");
                            _printFilenames();
                        } catch (e) {
                          print("Error: $e");
                          Navigator.of(context).pop(); // Close the loading dialog
                          showSuccessDialog(context, "An error occurred while uploading the files.");
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: mainColor,
                      padding: const EdgeInsets.symmetric(horizontal: 100, vertical: 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30.0),
                      ),
                    ),
                    child: Text(
                      "Submit",
                      style: AppTextStyles.body.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),

                )
              ],
            )
            
          ),
          const NavigationMenu(),
        ],
        
      )
      
    );
  }  
  void showSuccessDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Consumer(
        builder: (context, ref, _) {
          return PopScope(
            canPop: false, // Prevent default pop behavior
            onPopInvokedWithResult: (didPop, result) {
              if (!didPop) {
                // Navigate to home if system back button is pressed
                ref.invalidate(bookingProvider);
                ref.invalidate(filteredItemsProvider);
                ref.invalidate(ongoingTransactionProvider);
                ref.invalidate(filteredItemsProviderForTransactionScreen);
                ref.invalidate(filteredItemsProviderForHistoryScreen);
                ref.invalidate(allTransactionProvider);
                Navigator.of(context).popUntil((route) => route.isFirst);
                ref.read(navigationNotifierProvider.notifier).setSelectedIndex(0);
              }
            },
            child: Consumer(
              builder: (context, ref, _) {
                return Dialog(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  backgroundColor: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 70,
                          height: 70,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: mainColor,
                          ),
                          child: const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 40,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          message,
                          textAlign: TextAlign.center,
                          style: AppTextStyles.body.copyWith(
                              color: Colors.black87
                            ),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: mainColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () {
                            ref.invalidate(bookingProvider);
                            ref.invalidate(filteredItemsProvider);
                            ref.invalidate(ongoingTransactionProvider);
                            ref.invalidate(filteredItemsProviderForTransactionScreen);
                            ref.invalidate(filteredItemsProviderForHistoryScreen);
                            ref.invalidate(allTransactionProvider);
                            Navigator.of(context).popUntil((route) => route.isFirst);
                            ref.read(navigationNotifierProvider.notifier).setSelectedIndex(0);
                          },
                          child: Text("OK", style: AppTextStyles.body.copyWith(color: Colors.white)),
                        ),
                      ],
                    ),
                  ),
                );
              }
            )
          );
        },
      ),
    );
  }
}