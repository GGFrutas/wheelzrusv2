// ignore_for_file: unused_import, avoid_print

import 'dart:convert';
import 'dart:io';

import 'package:animated_toggle_switch/animated_toggle_switch.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/models/transaction_model.dart';
import 'package:frontend/notifiers/auth_notifier.dart';
import 'package:frontend/provider/accepted_transaction.dart' as accepted_transaction;
import 'package:frontend/provider/theme_provider.dart';
import 'package:frontend/provider/transaction_list_notifier.dart';
import 'package:frontend/provider/transaction_provider.dart';
import 'package:frontend/theme/colors.dart';
import 'package:frontend/theme/text_styles.dart';
import 'package:frontend/user/schedule.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
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

 
   
  final SignatureController _controller = SignatureController(
    penStrokeWidth: 5,
    penColor: Colors.black,
    exportBackgroundColor: Colors.white,
  );

  

  Future<void> _printFilenames() async {
   
    Uint8List? signatureImage = await _controller.toPngBytes();
    String? base64Signature = signatureImage != null ? base64Encode(signatureImage) : null;

    var url = Uri.parse('http://192.168.118.102:8000/api/odoo/upload_pod?uid=$uid');

    // List<String?> base64Images =[];
    // for (var image in _images) {
    //   if (image != null) {
    //     File file = File(image.path);
    //     List<int> imageBytes = await file.readAsBytes();
    //     String base64Image = base64Encode(imageBytes);
    //     base64Images.add(base64Image);
    //   }
    // }

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

    var response = await http.post(url,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'password': ref.read(authNotifierProvider).password ?? '',
      },
      body: jsonEncode({
        'id': widget.transaction?.id,
        'signature': base64Signature,
        'images': imageToUpload,
        'dispatch_type': widget.transaction?.dispatchType,
        'request_number': widget.transaction?.requestNumber,
      }),
    );

    if (response.statusCode == 200) {
      print("Files uploaded successfully!");
      print("Signature (base64): $base64Signature");
      print("Image (base64): ${widget.base64Images}");
      

      // final ongoingTransactionNotifier = ref.read(accepted_transaction.acceptedTransactionProvider.notifier);
      // ongoingTransactionNotifier.updateStatus(widget.transaction?.id.toString() ?? '', widget.transaction?.requestNumber.toString() ?? '', 'Ongoing', ref);

      // final updated = await fetchTransactionStatus(ref, widget.transaction?.id.toString() ?? '');
      // print('Updated Status: ${updated.requestStatus}');
      showSuccessDialog(context, "Proof of delivery has been successfully uploaded!");
    } else {
      showSuccessDialog(context, "Failed to upload files :()");
      print("Failed to upload files: ${response.statusCode}");
    }

    
  }

  @override
  void initState() {
    // initLocation();
    super.initState();
    uid = ref.read(authNotifierProvider).uid ?? '';
    _controller.addListener(() {
      if (mounted) {  
        setState(() {}); // Update the UI whenever the signature content changes
      }
      setState(() {}); // Rebuild to update the visibility of the Clear button
    });
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
      body: Padding (
        padding: const EdgeInsetsDirectional.only(top: 100),
        
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          
          children: [
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
              height: 350,
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
      bottomSheet: Container(
        color: Colors.transparent,
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
          onPressed:() async {
          if (_controller.isEmpty) {
            showDialog(
              context: context, 
              builder: (BuildContext context) {
                return AlertDialog(
                  title: Text(
                    "No Signature Provided",
                    style: AppTextStyles.body,
                  ),
                  content: Text(
                    "Please provide signature.",
                    style: AppTextStyles.caption,
                  ),
                  actions: [
                      TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: Text(
                        "OK",
                        style: AppTextStyles.body
                      ),
                    ),
                  ],
                );
              },
            );
          } else {
            print("UID: ${widget.uid}");
            print("Request Number: ${widget.transaction?.requestNumber}");
              _printFilenames();
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
        ),
      ),
    );
  }  
  void showSuccessDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
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
                  color: Colors.green,
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
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                child: const Text("OK", style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }

}