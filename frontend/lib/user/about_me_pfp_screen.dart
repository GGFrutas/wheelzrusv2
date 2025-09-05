// ignore_for_file: unused_import

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:animated_toggle_switch/animated_toggle_switch.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/notifiers/auth_notifier.dart';
import 'package:frontend/provider/theme_provider.dart';
import 'package:frontend/screen/login_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import 'package:frontend/theme/colors.dart';
import 'package:frontend/theme/text_styles.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AboutMeScreen extends ConsumerStatefulWidget{
  final String uid;

  const AboutMeScreen({super.key, required this.uid});

  @override

  ConsumerState<AboutMeScreen> createState() => _AboutMeScreenPageState();
}

class ProfileMenuWidget extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onPress;
  final Color? textColor;
  final bool endIcon;

  const ProfileMenuWidget({
    super.key,
    required this.title,
    required this.icon,
    required this.onPress,
    this.textColor,
    this.endIcon = true,
  });
  
  

  @override
  Widget build(BuildContext context) {
    
    return ListTile(
      onTap: onPress,
      leading: Icon(icon, color: textColor ?? Theme.of(context).iconTheme.color),
      title: Text(title, style: AppTextStyles.subtitle.copyWith(color: textColor ?? Theme.of(context).textTheme.bodyLarge?.color)),
      trailing: endIcon ? const Icon(Icons.arrow_forward_ios, size: 16) : null,
    );
  }
  
}

  

class _AboutMeScreenPageState extends ConsumerState<AboutMeScreen>{

  // Define tPrimaryColor
  final Color tPrimaryColor = Colors.green; // Replace Colors.green with your desired color
  bool isNameEditable = false;
  bool isEmailEditable = false;
  bool isNumberEditable = false;

  bool _isNameChanged = false;
  bool _isEmailChanged = false;
  bool _isNumberChanged = false;

  late TextEditingController nameController;
  late TextEditingController emailController;
  late TextEditingController numberController;

  File? _image;

  @override
  void initState() {
    super.initState();
    final authState = ref.read(authNotifierProvider);
    nameController = TextEditingController(text: authState.driverName ?? '');
    emailController = TextEditingController(text: authState.login ?? '');
    numberController = TextEditingController(text: authState.driverNumber ?? '');
  }
  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    numberController.dispose();
    super.dispose();
  }

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
                  final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery);
                  if (mounted && pickedFile != null) {
                    setState(() {
                      _image = File(pickedFile.path); // Add image to the list
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
                      _image = File(pickedFile.path); // Add image to the list
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

  @override
  Widget build(BuildContext context) {
  
    final authState = ref.watch(authNotifierProvider);
    Uint8List? imageBytes;
    if (authState.partnerImageBase64 != null &&
        authState.partnerImageBase64!.isNotEmpty) {
      try {
        imageBytes = base64Decode(authState.partnerImageBase64!);
      } catch (e) {
        // Handle invalid base64
        imageBytes = null;
      }
    }
    
   
    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: mainColor),
        title: Text(
          'About Me',
          style: AppTextStyles.subtitle.copyWith(
            color: mainColor,
          ),
        ),
        // backgroundColor: const Color(0xFF1d3c34),
        centerTitle: true,
        actions: [
          if (_isNameChanged || _isEmailChanged || _isNumberChanged || _image != null)
            IconButton(
              icon: const Icon(Icons.download, color: mainColor),
              onPressed: () {
                print("Save changes");
              },
            )
          else 
           IconButton(
              icon: const Icon(Icons.more_vert, color: mainColor),
              onPressed: () {
                print("More options");
              },
            ),
          ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 130,
                    height: 130,
                    decoration: BoxDecoration(
                      color:Colors.grey.shade300,
                      shape: BoxShape.circle,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(100), 
                      child: _image != null ? Image.file(
                        _image!,
                        fit: BoxFit.cover,
                        width: 130,
                        height: 130,
                      )
                      :authState.partnerImageBase64 != null && authState.partnerImageBase64!.isNotEmpty && imageBytes != null
                        ? Image.memory(
                          imageBytes,
                          fit: BoxFit.cover,
                          width: 120,
                          height: 120,
                        )
                      : Image.asset(
                          'assets/xlogo.png',
                          fit: BoxFit.cover,
                          width: 120,
                          height: 120,
                        ), 
                    ) 
                  ),
                  
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(255, 126, 129, 128),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Theme.of(context).scaffoldBackgroundColor,
                          width: 2,
                        ),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                        onPressed: () {
                          _pickImage();
                        },
                      ),
                    ),
                  ),
                ],
              ),
              
            ),
            const SizedBox(height: 50),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Full Name",
                    style: AppTextStyles.caption.copyWith(
                      fontWeight: FontWeight.bold,  
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: nameController,
                    readOnly: !isNameEditable,
                    onChanged: (value) {
                      setState(() {
                        _isNameChanged = value.trim() != (authState.driverName ?? '').trim();
                      });
                    },
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                        borderSide: BorderSide.none,
                      ),
                      hintText: authState.driverName ?? '',
                      filled: true,
                      fillColor: const Color.fromARGB(255, 234, 240, 238),
                      hintStyle: AppTextStyles.body, // Use caption style for hint text
                      suffixIcon: IconButton(
                        icon: Icon(
                          isNameEditable ? Icons.check : Icons.edit,
                          color: mainColor,
                        ),
                        onPressed: () {
                          setState(() {
                            isNameEditable = !isNameEditable;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "Email Address",
                    style: AppTextStyles.caption.copyWith(
                      fontWeight: FontWeight.bold,  
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: emailController,
                    readOnly: !isEmailEditable,
                    onChanged: (value) {
                      setState(() {
                        _isEmailChanged = value.trim() != (authState.login ?? '').trim();
                      });
                    },
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                        borderSide: BorderSide.none,
                      ),
                      hintText: authState.login ?? ' ',
                      filled: true,
                      fillColor: const Color.fromARGB(255, 234, 240, 238),
                      hintStyle: AppTextStyles.body, // Use caption style for hint text
                      suffixIcon: IconButton(
                        icon: Icon(
                          isEmailEditable ? Icons.check : Icons.edit,
                          color: mainColor,
                        ),
                        onPressed: () {
                          setState(() {
                            isEmailEditable = !isEmailEditable;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Text(
                  //   "Phone Number",
                  //   style: AppTextStyles.caption.copyWith(
                  //     fontWeight: FontWeight.bold,  
                  //   ),
                  // ),
                  // const SizedBox(height: 10),
                  // TextField(
                  //   readOnly: true,
                  //   decoration: InputDecoration(
                  //     border: OutlineInputBorder(
                  //       borderRadius: BorderRadius.circular(8.0),
                  //       borderSide: BorderSide.none,
                  //     ),
                  //     hintText: authState.driverphone ?? '',
                  //     filled: true,
                  //     fillColor: const Color.fromARGB(255, 234, 240, 238),
                  //     hintStyle: AppTextStyles.body, // Use caption style for hint text
                  //   ),
                  // ),
                  // const SizedBox(height: 20),
                  Text(
                    "Mobile Number",
                    style: AppTextStyles.caption.copyWith(
                      fontWeight: FontWeight.bold,  
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: numberController,
                    readOnly: !isNumberEditable,
                    onChanged: (value) {
                      setState(() {
                        _isNumberChanged = value.trim() != (authState.driverNumber ?? '').trim();
                      });
                    },
                    
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                        borderSide: BorderSide.none,
                      ),
                      hintText: authState.driverNumber ?? '',
                      filled: true,
                      fillColor: const Color.fromARGB(255, 234, 240, 238),
                      hintStyle: AppTextStyles.body, // Use caption style for hint text
                      
                      suffixIcon: IconButton(
                        icon: Icon(
                          isNumberEditable ? Icons.check : Icons.edit,
                          color: mainColor,
                        ),
                        onPressed: () {
                          setState(() {
                            isNumberEditable = !isNumberEditable;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "Job Position",
                    style: AppTextStyles.caption.copyWith(
                      fontWeight: FontWeight.bold,  
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    readOnly: true,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                        borderSide: BorderSide.none,
                      ),
                      hintText: 'Driver',
                      filled: true,
                      fillColor: const Color.fromARGB(255, 234, 240, 238),
                      hintStyle: AppTextStyles.body, // Use caption style for hint text
                    ),
                  ),
                  const SizedBox(height: 50),
                  Text(
                    "Company Name and Code",
                    style: AppTextStyles.caption.copyWith(
                      fontWeight: FontWeight.bold,  
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    readOnly: true,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                        borderSide: BorderSide.none,
                      ),
                      hintText: authState.companyName ?? '',
                      filled: true,
                      fillColor: const Color.fromARGB(255, 234, 240, 238),
                      hintStyle: AppTextStyles.body, // Use caption style for hint text
                    ),
                  ),
                  
                   const SizedBox(height: 20)
                ]
              )
            ),
          ]
        ),
      ),
     
    );
  }
  

}



