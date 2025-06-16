// ignore_for_file: unused_import, avoid_print

import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:animated_toggle_switch/animated_toggle_switch.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/models/transaction_model.dart';
import 'package:frontend/notifiers/auth_notifier.dart';
import 'package:frontend/provider/accepted_transaction.dart' as accepted_transaction;
import 'package:frontend/provider/theme_provider.dart';
import 'package:frontend/provider/transaction_list_notifier.dart';
import 'package:frontend/provider/transaction_provider.dart';
import 'package:frontend/screen/navigation_menu.dart';
import 'package:frontend/theme/colors.dart';
import 'package:frontend/theme/text_styles.dart';
import 'package:frontend/user/proof_of_delivery_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:signature/signature.dart';

class ConfirmationScreen extends ConsumerStatefulWidget {
  final String uid;
  final Transaction? transaction;

  const ConfirmationScreen({super.key, required this.uid, required this.transaction});

  @override
  ConsumerState<ConfirmationScreen> createState() => _ConfirmationState();
}

class _ConfirmationState extends ConsumerState<ConfirmationScreen> {
  String? uid;
 final List<File?> _images = [];

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
                  final List<XFile>? pickedFile = await picker.pickMultiImage();
                  if (mounted && pickedFile != null) {
                    setState(() {
                      _images.addAll(pickedFile.map((pickedFile) => File(pickedFile.path))); // Add image to the list
                    });
                  }
                  if (mounted) {
                    Navigator.of(context).pop();
                  }
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
                  if (mounted) {
                    Navigator.of(context).pop();
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<List<String>> _convertImagestoBase64(List<File> images) async {
    List<String> base64Images = [];

    for (File image in images) {
      final bytes = await image.readAsBytes();
      base64Images.add(base64Encode(bytes));
    }
    return base64Images;
  }


  
   
  @override
  void initState() {
    super.initState();
  }

  String getNullableValue(String? value, {String fallback = ''}) {
    return value ?? fallback;
  }
  
  @override
  Widget build(BuildContext context) {
   
    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: mainColor),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: ListView(
            children: [
              Container(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  getNullableValue(widget.transaction?.name).toUpperCase(),
                  style:AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.bold,
                    color: mainColor,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              progressRow(3), // Pass an integer value for currentStep

              const SizedBox(height: 20),
              Container(
                height: 250,
                padding: const EdgeInsets.all(16.0), // Add padding inside the container
                
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(20.0), // Rounded edges
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row (
                    children: [
                      GestureDetector(
                        onTap: () async {
                          _pickImage();
                        },
                        child: Container (
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade400),
                          ),
                          child: const Icon(Icons.camera_alt_outlined,
                            size: 40,
                            color: mainColor
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      ..._images.map((imageFile){
                        return Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(
                                  imageFile!,
                                  width: 100,
                                  height: 100,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Positioned(
                                top: 2,
                                right: 2,
                                child: GestureDetector(
                                  onTap: (){
                                    setState(() {
                                      _images.remove(imageFile);
                                    });
                                  },
                                  child: const CircleAvatar(
                                    radius: 12,
                                    backgroundColor: Colors.red,
                                    child: Icon(Icons.close, size: 16, color: Colors.white),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),
                
              ),
            
              const SizedBox(height: 10),
              Center(
                child: Text(
                  'Upload Picture as Proof of Delivery',
                  style: AppTextStyles.caption.copyWith(
                    color:  Colors.black54,
                  ),
                ), 
              ),
              const SizedBox(height: 70),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          top: 8,
          left: 16,
          right: 16,
        ),
        child: ElevatedButton(
        onPressed:() async {
          if (_images.isEmpty) {
            showDialog(
              context: context,
              builder: (context) {
                return AlertDialog(
                  title: Text(
                    'Upload Error!', 
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
                        'Please select at least one image.',
                        style: AppTextStyles.body.copyWith(
                          color: Colors.black87
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      const Icon (
                        Icons.image_outlined,
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
            final validImages = _images.whereType<File>().toList();

            if (validImages.isEmpty) {
              return;
            }
            final base64Images =  await _convertImagestoBase64(validImages);
             print('Base64 Image: $base64Images\n');
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProofOfDeliveryScreen(uid: widget.uid, transaction: widget.transaction,base64Images: base64Images),
              ),
            );
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
          "Confirm",
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
      // bottomNavigationBar: const NavigationMenu(),
    );
  }

   Widget progressRow(int currentStep) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: List.generate(3 * 2 - 1, (index) {
      // Step indices: 0, 2, 4; Connector indices: 1, 3
      if (index.isEven) {
        int stepIndex = index ~/ 2 + 1;
        Color stepColor = stepIndex < currentStep
            ? mainColor     // Completed
            : stepIndex == currentStep
                ? mainColor  // Active
                : Colors.grey;     // Upcoming

        bool isCurrent = stepIndex == currentStep;

        String label;
        switch (stepIndex) {
          case 1:
            label = "Delivery Log";
            break;
          case 2:
            label = "Schedule";
            break;
          case 3:
          default:
            label = "Confirmation";
        }

        return buildStep(label, stepColor, isCurrent);
      } else {
        int connectorIndex = (index - 1) ~/ 2 + 1;
        Color connectorColor = connectorIndex < currentStep
            ? mainColor
            : Colors.grey;

        return buildConnector(connectorColor);
      }
    }),
  );
}


  /// Single Progress Step Widget
 Widget buildStep(String label, Color color, bool isCurrent) {
  return Column(
    children: [
      CircleAvatar(
        radius: 10,
        backgroundColor: color,
        child: isCurrent
            ? const CircleAvatar(
                radius: 7,
                backgroundColor: Colors.white,
              )
            : null,
      ),
      const SizedBox(height: 5),
      Text(
        label,
        style: AppTextStyles.caption.copyWith(
          color: color,
        ),
      ),
    ],
  );
}


  /// Connector Line Between Steps
  Widget buildConnector(Color color) {
    return Transform.translate(
      offset: const Offset(0, -10),
      child: 
        Container(
          width: 40,
          height: 4,
          color: color,
        ),
    );
  }
}
