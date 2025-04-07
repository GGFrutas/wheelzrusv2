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
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:signature/signature.dart';

class ProofOfDeliveryScreen extends ConsumerStatefulWidget{
  final String uid;
  final Transaction? transaction; 

  const ProofOfDeliveryScreen({super.key, required this.uid, required this.transaction});

  @override

  ConsumerState<ProofOfDeliveryScreen> createState() => _ProofOfDeliveryPageState();
}

class _ProofOfDeliveryPageState extends ConsumerState<ProofOfDeliveryScreen>{
  final List<File?> _images = [];
  late final String uid;

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Gallery'),
                onTap: () async {
                  final XFile? pickedFile =
                      await picker.pickImage(source: ImageSource.gallery);
                  if (pickedFile != null) {
                    setState(() {
                      _images
                          .add(File(pickedFile.path)); // Add image to the list
                    });
                  }
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Camera'),
                onTap: () async {
                  final XFile? pickedFile =
                      await picker.pickImage(source: ImageSource.camera);
                  if (pickedFile != null) {
                    setState(() {
                      _images
                          .add(File(pickedFile.path)); // Add image to the list
                    });
                  }
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }
   Widget _buildImageThumbnail(File image) {
    return Stack(
      children: [
        Container(
          margin: const EdgeInsets.all(4),
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            image: DecorationImage(
              image: FileImage(image),
              fit: BoxFit.cover,
            ),
          ),
        ),
        Positioned(
          top: 0,
          right: 0,
          child: GestureDetector(
            onTap: () {
              setState(() {
                _images.remove(image); // Remove the selected image
              });
            },
            child: const Icon(
              Icons.cancel,
              color: Colors.red,
              size: 20,
            ),
          ),
        ),
      ],
    );
  }
  final SignatureController _controller = SignatureController(
    penStrokeWidth: 5,
    penColor: Colors.black,
    exportBackgroundColor: Colors.white,
  );

  Future<void> _printFilenames() async {
   
    Uint8List? signatureImage = await _controller.toPngBytes();
    String? base64Signature = signatureImage != null ? base64Encode(signatureImage) : null;

    var url = Uri.parse('http://192.168.118.102:8000/api/odoo/upload_pod?uid=$uid');

    List<String?> base64Images =[];
    for (var image in _images) {
      if (image != null) {
        File file = File(image.path);
        List<int> imageBytes = await file.readAsBytes();
        String base64Image = base64Encode(imageBytes);
        base64Images.add(base64Image);
      }
    }

    if(_controller.isNotEmpty){
      Uint8List? signatureImage = await _controller.toPngBytes();
      if(signatureImage != null){
        base64Signature = base64Encode(signatureImage);
      }
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
        'images': base64Images,
        'dispatch_type': widget.transaction?.dispatchType,
        'request_number': widget.transaction?.requestNumber,
      }),
    );

    if (response.statusCode == 200) {
      print("Files uploaded successfully!");
    } else {
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
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          'Proof of Delivery',
          style: GoogleFonts.poppins(
            fontSize: 24,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF1d3c34),
        centerTitle: true,
      ),
      body: Center (
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Please provide your signature below:',
              style: GoogleFonts.poppins(fontSize: 16),
            ),
            Signature(
              controller: _controller,
              width: MediaQuery.of(context).size.width * 0.9,
              height: 200,
              backgroundColor: Colors.grey[300]!,
            ),
            const SizedBox(height: 10),
            // Clear Button to clear the signature
            Visibility(
              visible: _controller
                  .isNotEmpty, // Show only if the canvas has content
              child: Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 5),
                  ),
                  onPressed: () {
                    _controller.clear(); // Clear the signature
                    setState(
                        () {}); // Trigger a rebuild to update visibility
                  },
                  child: const Text(
                    'Clear Signature',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
            Text(
              'Upload an Image Below:',
              style: GoogleFonts.poppins(fontSize: 16),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ..._images
                      .map((image) => _buildImageThumbnail(image!)),
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      margin: const EdgeInsets.all(4),
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey),
                      ),
                      child: const Icon(Icons.add,
                          size: 30, color: Colors.grey),
                    ),
                  ),
                ],
              ),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child:TextButton(
                onPressed: () async{
                  // _printFilenames();
                  print("ID: ${widget.transaction?.id}");
                  print("Request Number: ${widget.transaction?.requestNumber}");
                  print("Dispatch Type: ${widget.transaction?.dispatchType}");
                  final ongoingTransactionNotifier = ref.read(accepted_transaction.acceptedTransactionProvider.notifier);
                  ongoingTransactionNotifier.updateStatus(widget.transaction?.id.toString() ?? '', widget.transaction?.requestNumber.toString() ?? '', 'Ongoing', ref);

                  final updated = await fetchTransactionStatus(ref, widget.transaction?.id.toString() ?? '');
                  print('Updated Status: ${updated.requestStatus}');
                },
                style: TextButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 10),
                ),
                child: const Text(
                  'Done',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold),
                ),
              )
            ),
          ],
          
        ),
      )
    );
  }  
}

