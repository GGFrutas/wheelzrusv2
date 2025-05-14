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

class CompanyRegisterScreen extends ConsumerStatefulWidget {
  const CompanyRegisterScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _CompanyRegisterScreenState createState() => _CompanyRegisterScreenState();
}

class _CompanyRegisterScreenState extends ConsumerState<CompanyRegisterScreen> {
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
  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile =
        await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path); // Store the selected image
      });
    }
  }

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
      final companyCode = _companyCodeController.text.isNotEmpty
          ? _companyCodeController.text
          : null;

      ref.read(authNotifierProvider.notifier).register(
            name: name,
            email: email,
            companyCode: companyCode,
            mobile: mobile,
            password: password,
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
          'Company',
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
                        .maxLength(11)
                        .build(),
                  ),
                  const SizedBox(height: 16.0),
                  InputWidget(
                    hintText: 'Company Code',
                    prefixIcon: const Icon(Icons.business),
                    controller: _companyCodeController,
                    validator: ValidationBuilder()
                        .required()
                        .minLength(5)
                        .maxLength(5)
                        .build(),
                    obscureText: false,
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
