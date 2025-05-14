// ignore_for_file: library_private_types_in_public_api, use_build_context_synchronously

import 'dart:io'; // Required for File
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:form_validator/form_validator.dart';
import 'package:frontend/notifiers/auth_notifier.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart'; // For image picking
import 'package:frontend/screen/login_screen.dart';
import 'package:frontend/widgets/input_widget.dart'; // Assuming InputWidget is already implemented
import 'package:flutter/gestures.dart';
import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';

class IndividualRegisterScreen extends ConsumerStatefulWidget {
  const IndividualRegisterScreen({super.key});

  @override
  _IndividualRegisterScreenState createState() =>
      _IndividualRegisterScreenState();
}

class _IndividualRegisterScreenState
    extends ConsumerState<IndividualRegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _mobileController = TextEditingController();
  final _companyCodeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final GlobalKey<FormState> _formKey =
      GlobalKey<FormState>(); // Correct placement
  File? _image; // Variable to store the selected image
  bool _isTermsAccepted = false;

  // Future<void> _pickImage() async {
  //   final ImagePicker picker = ImagePicker();
  //   final XFile? pickedFile =
  //       await picker.pickImage(source: ImageSource.gallery);

  //   if (pickedFile != null) {
  //     setState(() {
  //       _image = File(pickedFile.path); // Store the selected image
  //     });
  //   }
  // }

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
                      _image = File(pickedFile.path); // Add image to the list
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
                      _image = File(pickedFile.path); // Add image to the list
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

  void _showPrivacyPolicyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Privacy Policy'),
          content: const SizedBox(
            height: 250, // Set a fixed height for the dialog
            width: double.infinity,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your Privacy Matters',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'We value your privacy and are committed to protecting your personal information. This policy outlines how we collect, use, and safeguard your data.',
                    style: TextStyle(fontSize: 14),
                  ),
                  SizedBox(height: 10),
                  Text(
                    '1. Information Collection',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  Text(
                    'We collect various types of information to provide and improve our services. This may include personal data, such as your name, email address, and usage data.',
                    style: TextStyle(fontSize: 14),
                  ),
                  SizedBox(height: 10),
                  Text(
                    '2. Use of Information',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  Text(
                    'We use the information we collect for various purposes, including to provide our services, notify you about changes to our services, and provide customer support.',
                    style: TextStyle(fontSize: 14),
                  ),
                  SizedBox(height: 10),
                  Text(
                    '3. Data Security',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  Text(
                    'We take the security of your data seriously and implement appropriate technical and organizational measures to protect your personal information.',
                    style: TextStyle(fontSize: 14),
                  ),
                  SizedBox(height: 10),
                  Text(
                    '4. Changes to This Privacy Policy',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  Text(
                    'We may update our Privacy Policy from time to time. We will notify you of any changes by posting the new policy on this page.',
                    style: TextStyle(fontSize: 14),
                  ),
                  SizedBox(height: 10),
                  Text(
                    '5. Contact Us',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  Text(
                    'If you have any questions about this Privacy Policy, please contact us at support@example.com.',
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showAlertDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Terms of Service'),
          content: const SizedBox(
            height: 250, // Set a fixed height for the dialog
            width: double.infinity,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome to Our App',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'By using this application, you agree to the following terms and conditions:',
                    style: TextStyle(fontSize: 14),
                  ),
                  SizedBox(height: 10),
                  Text(
                    '1. Acceptance of Terms',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  Text(
                    'By accessing and using our services, you accept and agree to be bound by the terms and provisions of this agreement. In addition, when using these particular services, you are subject to any posted guidelines or rules applicable to such services.',
                    style: TextStyle(fontSize: 14),
                  ),
                  SizedBox(height: 10),
                  Text(
                    '2. Modification of Terms',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  Text(
                    'We reserve the right to update or change our Terms of Service at any time. Continued use of the service after any such changes shall constitute your consent to such changes.',
                    style: TextStyle(fontSize: 14),
                  ),
                  SizedBox(height: 10),
                  Text(
                    '3. User Responsibilities',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  Text(
                    'You are responsible for maintaining the confidentiality of your account and password, and for all activities that occur under your account.',
                    style: TextStyle(fontSize: 14),
                  ),
                  SizedBox(height: 10),
                  Text(
                    '4. Limitation of Liability',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  Text(
                    'Our company shall not be liable for any damages, direct or indirect, that arise from the use or inability to use the service.',
                    style: TextStyle(fontSize: 14),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'For further details, please contact our support team.',
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  //End Alert Dialog
  void _validate() {
    final formState = _formKey.currentState; // Corrected key reference
    if (formState != null && formState.validate()) {
      formState.save();
      // Form is valid and saved
      _register();
    }
  }

  void _register() {
    if (!_isTermsAccepted) {
      if (context.mounted) {
        const snackBar = SnackBar(
          elevation: 0,
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.transparent,
          content: AwesomeSnackbarContent(
            title: 'Oh Hey!!',
            message: 'Please accept the Terms of Service & Privacy Policy.',
            contentType: ContentType.warning,
          ),
        );
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(snackBar);
      }
      return;
    }

    if (_formKey.currentState!.validate()) {
      final name = _nameController.text;
      final email = _emailController.text;
      final mobile = _mobileController.text;
      final password = _passwordController.text;
      final companyCode = _companyCodeController.text;

      ref.read(authNotifierProvider.notifier).register(
            name: name,
            email: email,
            companyCode: companyCode,
            mobile: mobile,
            password: password,
            picture: _image,
            context: context,
          );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    _companyCodeController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1d3c34),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1d3c34),
        title: Text(
          'Individual',
          style: GoogleFonts.montserrat(
            fontSize: 24,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back,
              color: Colors.white), // Back arrow icon
          onPressed: () {
            Navigator.pop(context); // Go back to the previous screen
          },
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          // Prevent overflow issues
          child: Form(
            key: _formKey, // Correct placement
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                children: [
                  // Image picker button
                  // const SizedBox(height: 20.0),
                  GestureDetector(
                    onTap: _pickImage,
                    child: CircleAvatar(
                      radius: 50,
                      backgroundColor: const Color(0xFFFFC72C),
                      child: _image != null
                          ? ClipOval(
                              child: Image.file(
                                _image!,
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                              ),
                            )
                          : const Icon(
                              Icons.camera_alt,
                              size: 50,
                              color: Colors.black,
                            ),
                    ),
                  ),
                  const SizedBox(height: 16.0),
                  Text(
                    'Create an Account',
                    style: GoogleFonts.montserrat(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16.0),
                  InputWidget(
                      hintText: 'Name',
                      prefixIcon: const Icon(Icons.person),
                      controller: _nameController,
                      obscureText: false,
                      validator:
                          ValidationBuilder().required().minLength(2).build()),
                  const SizedBox(height: 16.0),
                  InputWidget(
                    hintText: 'Email',
                    isEmail: true,
                    prefixIcon: const Icon(Icons.mail),
                    controller: _emailController,
                    validator: ValidationBuilder()
                        .required()
                        .email()
                        .maxLength(50)
                        .build(),
                    obscureText: false,
                  ),
                  const SizedBox(height: 16.0),
                  InputWidget(
                    hintText: 'Mobile',
                    digitsOnly: true,
                    prefixIcon: const Icon(Icons.phone_android),
                    controller: _mobileController,
                    obscureText: false,
                    validator: ValidationBuilder()
                        .required()
                        .phone()
                        .minLength(11)
                        .maxLength(11)
                        .build(),
                  ),
                  const SizedBox(height: 16.0),
                  InputWidget(
                    hintText: 'Password',
                    prefixIcon: const Icon(Icons.lock),
                    controller: _passwordController,
                    obscureText: true,
                    validator:
                        ValidationBuilder().required().minLength(6).build(),
                  ),
                  const SizedBox(height: 16.0),
                  InputWidget(
                    hintText: 'Confirm Password',
                    prefixIcon: const Icon(Icons.lock),
                    controller: _confirmPasswordController,
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please confirm your password';
                      } else if (value != _passwordController.text) {
                        return 'Passwords do not match';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 10.0),

                  Row(
                    children: [
                      Checkbox(
                        value: _isTermsAccepted,
                        onChanged: (bool? value) {
                          setState(() {
                            _isTermsAccepted = value ?? false;
                          });
                        },
                        focusColor: const Color(0xFFFFC72C),
                        checkColor: Colors.black, // Color of the checkmark
                        activeColor:
                            Colors.black, // Color of the checkbox when checked
                        fillColor: WidgetStateProperty.all(
                            Colors.white), // Accent blue color
                      ),
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            text: 'I agree with the ',
                            style: GoogleFonts.montserrat(
                              fontSize: 14,
                              color: Colors.white,
                            ),
                            children: [
                              TextSpan(
                                text: 'Terms of Service',
                                style: GoogleFonts.montserrat(
                                  fontSize: 14,
                                  color: const Color(
                                      0xFFFFC72C), // Accent blue color
                                  decoration: TextDecoration.underline,
                                ),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () {
                                    // Open Terms and Conditions link
                                    // You can use URL launcher to open it
                                    _showAlertDialog(context);
                                  },
                              ),
                              TextSpan(
                                  text: ' and ',
                                  style: GoogleFonts.montserrat(
                                      fontSize: 14, color: Colors.white)),
                              TextSpan(
                                text: 'Privacy Policy.',
                                style: GoogleFonts.montserrat(
                                  fontSize: 14,
                                  color: const Color(
                                      0xFFFFC72C), // Accent blue color
                                  decoration: TextDecoration.underline,
                                ),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () {
                                    _showPrivacyPolicyDialog(context);
                                    // Open Privacy Policy link
                                    // You can use URL launcher to open it
                                  },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10.0),
                  Consumer(
                    builder: (context, ref, _) {
                      final authState = ref.watch(authNotifierProvider);
                      bool isLoading = authState.isLoading;
                      // bool isError = authState.isError;
                      return SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: isLoading ? null : _validate,
                            // onPressed: null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFFC72C),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 120,
                                vertical: 15,
                              ),
                              disabledForegroundColor: const Color(0xFFFFC72C),
                              disabledBackgroundColor: const Color(0xFFFFC72C),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: isLoading
                                ? const SizedBox(
                                    width:
                                        24, // Set the width for the CircularProgressIndicator
                                    height:
                                        24, // Set the height for the CircularProgressIndicator
                                    child: CircularProgressIndicator(
                                      color: Colors.black,
                                      strokeWidth:
                                          3, // Adjust the thickness of the spinner
                                    ),
                                  )
                                : Text(
                                    'Sign Up',
                                    style: GoogleFonts.montserrat(
                                      color: Colors.black,
                                      fontSize: 16, // Updated font size to 20
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign
                                        .center, // Ensure the text is centered
                                  ),
                          ));
                    },
                  ),
                  const SizedBox(height: 10.0),
                  RichText(
                    text: TextSpan(
                      text: "Already have an account? ",
                      style: GoogleFonts.montserrat(
                        textStyle: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                      children: [
                        TextSpan(
                          text: 'Sign In',
                          style: GoogleFonts.montserrat(
                            textStyle: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Color(0xFFFFC72C),
                              decoration:
                                  TextDecoration.underline, // Underlined text
                            ),
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () {
                              // Navigate to Register page when 'Sign Up' is tapped
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const LoginScreen(),
                                ),
                              );
                            },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
