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
import 'package:frontend/provider/base_url_provider.dart';
import 'package:frontend/provider/theme_provider.dart';
import 'package:frontend/provider/transaction_list_notifier.dart';
import 'package:frontend/provider/transaction_provider.dart';
import 'package:frontend/screen/navigation_menu.dart';
import 'package:frontend/theme/colors.dart';
import 'package:frontend/theme/text_styles.dart';
import 'package:frontend/user/proof_of_delivery_screen.dart';
import 'package:frontend/widgets/progress_row.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:signature/signature.dart';

class ConfirmationScreen extends ConsumerStatefulWidget {
  final String uid;
  final Transaction? transaction;

  const ConfirmationScreen({super.key, required this.uid, required this.transaction, required relatedFF, required requestNumber, required int id});

  @override
  ConsumerState<ConfirmationScreen> createState() => _ConfirmationState();
}

class _ConfirmationState extends ConsumerState<ConfirmationScreen> {
  String? uid;
  Transaction? transaction;
 
 late List<List<UploadImage>> _imageLists;

 List<DocumentRequirement> _requirements = [];
 bool _loadingRequirements = true;
 // true when _requirements came from the internal system's DI/DR checklist;
 // false when there was no checklist for this leg and we fell back to a single POD photo.
 bool _usingChecklist = false;

 // Which leg (route_type) of the dispatch is currently active, matching the
 // ROUTE_TYPES on dispatch.document.requirement in the internal system.
 String? _resolveRouteType() {
  final requestNumber = widget.transaction?.requestNumber;
  if (requestNumber == null || requestNumber.isEmpty || requestNumber == 'null') {
    return null;
  }
  if (widget.transaction?.plRequestNumber == requestNumber) return 'PL';
  if (widget.transaction?.dlRequestNumber == requestNumber) return 'DL';
  if (widget.transaction?.peRequestNumber == requestNumber) return 'PE';
  if (widget.transaction?.deRequestNumber == requestNumber) return 'DE';
  return null;
 }

 // Matches the pre-refactor hardcoded rules for when each leg's DI/DR checklist applies:
 // DE/DL only on the Ongoing -> Completed transition, PL/PE only on the
 // Accepted/Pending/Assigned -> Ongoing transition. Outside those windows the leg
 // always stays a plain POD photo, regardless of what Odoo's checklist has configured.
 bool _checklistEligible(String routeType) {
  if (routeType == 'DE') return widget.transaction?.deRequestStatus == 'Ongoing';
  if (routeType == 'DL') return widget.transaction?.dlRequestStatus == 'Ongoing';
  if (routeType == 'PL') return widget.transaction?.plRequestStatus == 'Assigned';
  if (routeType == 'PE') return widget.transaction?.peRequestStatus == 'Assigned';
  return true;
 }

 Future<void> _fetchDocumentRequirements() async {
  final routeType = _resolveRouteType();
  final dispatchId = widget.transaction?.id;

  List<DocumentRequirement> requirements = [];
  bool usingChecklist = false;

  if (routeType != null && dispatchId != null && _checklistEligible(routeType)) {
    try {
      final baseUrl = ref.read(baseUrlProvider);
      final auth = ref.read(authNotifierProvider);
      final url = Uri.parse(
        '$baseUrl/api/odoo/booking/document-requirements/$dispatchId?uid=${widget.uid}&route_type=$routeType',
      );

      final response = await http.get(
        url,
        headers: {
          'Accept': 'application/json',
          'login': auth.login ?? '',
          'password': auth.password ?? '',
        },
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final list = (body['data']?['requirements'] as List<dynamic>?) ?? [];
        requirements = list
            .whereType<Map<String, dynamic>>()
            .map((r) => DocumentRequirement(
                  id: r['id'] as int,
                  name: (r['name'] ?? '').toString(),
                ))
            .toList();
        usingChecklist = requirements.isNotEmpty;
      } else {
        print('Failed to load document checklist: ${response.statusCode}');
      }
    } catch (e) {
      print('Failed to load document checklist: $e');
    }
  }

  // No checklist configured in the internal system for this leg — fall back
  // to the single always-required delivery photo.
  if (!usingChecklist) {
    requirements = [DocumentRequirement(id: 0, name: 'POD')];
  }

  if (!mounted) return;
  setState(() {
    _requirements = requirements;
    _usingChecklist = usingChecklist;
    _imageLists = List.generate(_requirements.length, (_) => <UploadImage>[]);
    _loadingRequirements = false;
  });
 }

  Future<void> _pickImage(int index) async {
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
                  final navigator = Navigator.of(context);
                  final List<XFile> pickedFile = await picker.pickMultiImage();
                  if (mounted && pickedFile.isNotEmpty) {
                  final validFiles = <UploadImage>[];

                  for (final xfile in pickedFile) {
                    final file = File(xfile.path);
                    final sizeInMB = (await file.length()) / (1024 * 1024);

                    if (sizeInMB > 10) {
                      // ❌ Too large — show message
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              "❌ ${xfile.name} is too large (${sizeInMB.toStringAsFixed(2)} MB). Max allowed: 10 MB.",
                              style: AppTextStyles.caption.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        duration: const Duration(seconds: 3),
                        behavior: SnackBarBehavior.floating, // ✅ Makes it float with margin
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder( // ✅ Rounded corners
                          borderRadius: BorderRadius.circular(12),
                        ),
                        backgroundColor: Colors.red, // ✅ Soft black, not pure #000
                        elevation: 6,
                          ),
                        );
                      }
                    } else {
                      // ✅ Valid file
                      validFiles.add(
                        UploadImage(file: file, label: _requirements[index].name),
                      );
                    }
                  }

                  // ✅ Only add valid files
                  if (validFiles.isNotEmpty) {
                    setState(() {
                      _imageLists[index].addAll(validFiles);
                    });
                  }
                }
                  navigator.pop();
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Camera'),
                onTap: () async {
                  final navigator = Navigator.of(context);
                  final XFile? pickedFile =
                      await picker.pickImage(source: ImageSource.camera);
                  if (pickedFile != null && mounted) {
                  final file = File(pickedFile.path);
                  final sizeInMB = (await file.length()) / (1024 * 1024);

                  if (sizeInMB > 10) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          "❌ ${pickedFile.name} is too large (${sizeInMB.toStringAsFixed(2)} MB). Max allowed: 10 MB.",
                          style: AppTextStyles.caption.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        duration: const Duration(seconds: 3),
                        behavior: SnackBarBehavior.floating, // ✅ Makes it float with margin
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder( // ✅ Rounded corners
                          borderRadius: BorderRadius.circular(12),
                        ),
                        backgroundColor: Colors.red, // ✅ Soft black, not pure #000
                        elevation: 6,
                      ),
                    );
                  } else {
                    setState(() {
                      _imageLists[index].add(
                        UploadImage(file: file, label: _requirements[index].name),
                      );
                    });
                  }
                }
                  navigator.pop();
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

  // Returns the extra body fields the proof-of-delivery submission should merge in:
  // {'documents': {requirementId: {...}}} when driven by the internal system's checklist,
  // or {'images': {'POD': {...}}} for the single-photo fallback (no checklist configured).
  Future<Map<String, dynamic>> buildUploadMap() async {
    final Map<String, dynamic> documentMap = {};
    for (int i = 0; i < _requirements.length; i++) {
      final requirement = _requirements[i];

      if (_imageLists[i].isEmpty) continue;

      final upload = _imageLists[i].first;
      final file = upload.file;

      final ext = file.path.split('.').last.toLowerCase();
      final safeExt = (ext == 'jpg' || ext == 'png') ? ext : 'jpg';

      final bytes = await file.readAsBytes();
      final base64Str = base64Encode(bytes);

      final filename = '${requirement.name.replaceAll(' ', '_')}.$safeExt';
      final key = _usingChecklist ? requirement.id.toString() : requirement.name;

      documentMap[key] = {
        'filename': filename,
        'content': base64Str,
      };
    }

    return {_usingChecklist ? 'documents' : 'images': documentMap};
  }


  
   
  @override
  void initState() {
    super.initState();
    _imageLists = [];
    _fetchDocumentRequirements();
  }

  String getNullableValue(String? value, {String fallback = ''}) {
    return value ?? fallback;
  }
  
  @override
  Widget build(BuildContext context) {

    print('Confirmation Screen - Transaction Request Number: ${widget.transaction?.requestNumber}');
   
  int currentStep = 3; // Assuming Confirmation is step 3 (0-based index)

  final bookingNumber = widget.transaction?.bookingRefNumber;

    final allTransactions = ref.watch(transactionListProvider);
    // print("All Transaction: $allTransactions");

    // for (var tx in allTransactions) {
    //   print("🔍 TX → bookingRefNumber: '${tx.bookingRefNumber}', dispatchType: '${tx.dispatchType}'");
    // }

    final relatedFF = allTransactions.cast<Transaction?>().firstWhere(
        (tx) {
          final refNum = tx?.bookingRefNumber?.trim();
          final currentRef = bookingNumber?.trim();
          final dispatch = tx?.dispatchType!.toLowerCase().trim();

          return refNum != null &&
                refNum == currentRef &&
                dispatch == 'ff'; // ✅ specifically look for FF
        },
        orElse: () => null,
      );
   

   
    final navigator = Navigator.of(context);
    final dialogContext = context;


    return PopScope(
      canPop: false,
  onPopInvokedWithResult:  (didPop, result) async {
   final shouldpop = await _showConfirmationDialog(dialogContext);
   if(shouldpop && !didPop){
     navigator.maybePop();
   }
  },
  child: Scaffold(
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
              ProgressRow(currentStep: currentStep, uid: widget.uid, transaction: widget.transaction,relatedFF: relatedFF,),

              const SizedBox(height: 20),

             if (_loadingRequirements)
               const Center(child: CircularProgressIndicator())
             else
             GridView.builder(
                itemCount: _requirements.length,
                shrinkWrap: true, // ✅ prevents unbounded height error
            physics: const NeverScrollableScrollPhysics(), // ✅ disables nested scrolling
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1,
                ),
              itemBuilder: (context,index) {

                return Container (
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column (
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        _requirements[index].name,
                        style:  AppTextStyles.caption,
                      ),
                      // const SizedBox(height: 5),
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              // const SizedBox(width:),
                              ..._imageLists[index].map((upload) {
                                return Padding(
                                  padding: const EdgeInsets.only(right: 10),
                                  child: Stack(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.file(
                                          upload.file,
                                          width: 100,
                                          height: 100,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                      Positioned(
                                        top: 2,
                                        right: 2,
                                        child: GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              _imageLists[index].remove(upload);
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
                              }),
                              GestureDetector(
                                onTap: () => _pickImage(index),
                                child: Container(
                                  width: 80,
                                  height: 80,
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
                            ],
                          ),
                        ),
                      )
                    ],
                  )
                );
              }
            
            ),

              // ...List.generate(5, (index) {
              //   return Column(
              //     children: [
              //       Padding(
              //         padding: const EdgeInsets.all(16.0), // Add padding inside the container
              //         child: Container(
              //           height: 150,
              //           width: 150,
              //           padding: const EdgeInsets.all(16.0), // Add padding inside the container
              //           decoration: BoxDecoration(
              //             color: bgColor,
              //             borderRadius: BorderRadius.circular(20.0), // Rounded edges
              //           ),
              //           child: SingleChildScrollView(
              //             scrollDirection: Axis.horizontal,
              //             child: Row(
              //               children: [
              //                 const SizedBox(width: 10),
              //                 ..._imageLists[index].map((file) {
              //                   return Padding(
              //                     padding: const EdgeInsets.only(right: 10),
              //                     child: Stack(
              //                       children: [
              //                         ClipRRect(
              //                           borderRadius: BorderRadius.circular(8),
              //                           child: Image.file(
              //                             file,
              //                             width: 100,
              //                             height: 100,
              //                             fit: BoxFit.cover,
              //                           ),
              //                         ),
              //                         Positioned(
              //                           top: 2,
              //                           right: 2,
              //                           child: GestureDetector(
              //                             onTap: () {
              //                               setState(() {
              //                                 _imageLists[index].remove(file);
              //                               });
              //                             },
              //                             child: const CircleAvatar(
              //                               radius: 12,
              //                               backgroundColor: Colors.red,
              //                               child: Icon(Icons.close, size: 16, color: Colors.white),
              //                             ),
              //                           ),
              //                         ),
              //                       ],
              //                     ),
              //                   );
              //                 }).toList(),
              //               ],
              //             ),
              //           ),
              //         ),
              //       ),
              //       const SizedBox(height: 10),
              //       Center(
              //         child: GestureDetector(
              //           onTap: () => _pickImage(index),
              //           child: Container(
              //             width: 80,
              //             height: 80,
              //             decoration: BoxDecoration(
              //               color: Colors.white,
              //               borderRadius: BorderRadius.circular(12),
              //               border: Border.all(color: Colors.grey.shade400),
              //             ),
              //             child: const Icon(Icons.camera_alt_outlined,
              //                 size: 40,
              //                 color: mainColor
              //             ),
              //           ),
              //         ),
              //       ),
              //       const SizedBox(height: 10),
              //       Center(
              //         child: Text(
              //           'Upload Picture as Proof of Delivery',
              //           style: AppTextStyles.caption.copyWith(
              //             color: Colors.black54,
              //           ),
              //         ),
              //       ),
              //     ],
              //   );
              // }),
              const SizedBox(height: 70),
            ],
          ),
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
                      final hasAnyImage = _imageLists.any((list) => list.isNotEmpty);
                      if (!hasAnyImage) {
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
                        final validImages = _imageLists
    .expand((list) => list)
    .map((upload) => upload.file) // ✅ extract File from UploadImage
    .toList();

                        if (validImages.isEmpty) {
                          return;
                        }
                        final navigator  = Navigator.of(context);
                        final base64Images =  await _convertImagestoBase64(validImages);
                        print('Base64 Image: $base64Images\n');
                        final podPayloadExtras = await buildUploadMap();
                        navigator.push(
                          MaterialPageRoute(
                            builder: (context) => ProofOfDeliveryScreen(uid: widget.uid, transaction: widget.transaction, podPayloadExtras: podPayloadExtras),
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
                  )
                )
              ],
            )
            
          ),
          NavigationMenu(
            onItemTap: (index) async {
              // Intercept menu taps
              final navigator = Navigator.of(context);
              final dialogContext = context;
              if(!context.mounted) return;
              final shouldLeave = await _showConfirmationDialog(dialogContext);
              if(!navigator.mounted) return;
              if (shouldLeave) {
                switch (index) {
                  case 0:
                    navigator.popUntil((route) => route.isFirst);
                    break;
                  case 1:
                    navigator.popUntil((route) => route.isFirst);
                    break;
                  case 2:
                    navigator.popUntil((route) => route.isFirst);
                    break;
                }
              }
            },
          ),
        ],
      )
      
   
   ) // bottomNavigationBar: const NavigationMenu(),
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

class UploadImage {
  final File file;
  final String label;

  UploadImage({required this.file, required this.label});
}

class DocumentRequirement {
  final int id;
  final String name;

  DocumentRequirement({required this.id, required this.name});
}

Future<bool> _showConfirmationDialog(BuildContext context) async {
   final shouldLeave = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title:  Text(
            "Are you sure?",
            style: AppTextStyles.title.copyWith(
              color: mainColor,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),

          content: Text(
            "Leaving now will discard any changes you made.",
            textAlign: TextAlign.center,
            style: AppTextStyles.subtitle.copyWith(
              color: Colors.black87
            ),
          ),

          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded (
                  child: Padding (
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: mainColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () => Navigator.of(context).pop(false),
                      child: Text("Stay", style: AppTextStyles.body.copyWith(color: Colors.white)),
                    ),
                  )
                ),
                Expanded (
                  child: Padding (
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () => Navigator.of(context).pop(true),
                      child: Text("Leave", style: AppTextStyles.body.copyWith(color: Colors.white)),
                    ),
                  )
                )
              ],
            ),
          ],
        );
      },
    );
    return shouldLeave ?? false; // return true if user confirms leave
}