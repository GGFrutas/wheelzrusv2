import 'dart:io'; // Required for File
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:form_validator/form_validator.dart';
import 'package:frontend/notifiers/auth_notifier.dart';
import 'package:frontend/notifiers/navigation_notifier.dart';
import 'package:frontend/provider/base_url_provider.dart';
import 'package:frontend/provider/theme_provider.dart';
import 'package:frontend/screen/login_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart'; // For image picking
import 'package:frontend/widgets/input_widget.dart'; // Assuming InputWidget is already implemented
import 'package:animated_toggle_switch/animated_toggle_switch.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UpdateUserScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> user;
  final String uid;
  const UpdateUserScreen({super.key, required this.user, required this.uid});
  @override
  // ignore: library_private_types_in_public_api
  _UpdateUserScreenState createState() => _UpdateUserScreenState();
}

class _UpdateUserScreenState extends ConsumerState<UpdateUserScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _mobileController = TextEditingController();
  final _companyCodeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  //For toggle switch
  int value = 0;
  int? nullableValue;
  bool positive = false;
  bool loading = false;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.user['name'];
    _emailController.text = widget.user['email'];
    _mobileController.text = widget.user['mobile'];
    _companyCodeController.text = widget.user['company_code'];
  }

  String _getProfileImageUrl(String picture) {
    final baseUrl = ref.watch(baseUrlProvider);
    return '$baseUrl/storage/$picture'; // Correct URL for the emulator
  }

  final GlobalKey<FormState> _formKey =
      GlobalKey<FormState>(); // Correct placement
  File? _image; // Variable to store the selected image

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
                      _image =
                          File(pickedFile.path); // Store the selected image
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
                      _image =
                          File(pickedFile.path); // Store the selected image
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

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    // Update the theme state
    ref.read(themeProvider.notifier).state = true;
    ref.read(navigationNotifierProvider.notifier).setSelectedIndex(1);
    // Remove token from shared preferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');

    if (!context.mounted) return; // Ensure the widget is still mounted

    // Navigate to the Login screen
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const LoginScreen(),
      ),
    );
  }

  void _validate() {
    final formState = _formKey.currentState; // Corrected key reference
    if (formState != null && formState.validate()) {
      formState.save();
      // Form is valid and saved
      _update();
    }
  }

  void _update() {
    if (_formKey.currentState!.validate()) {
      final name = _nameController.text;
      final email = _emailController.text;
      final mobile = _mobileController.text;
      final password =
          _passwordController.text.isNotEmpty ? _passwordController.text : null;
      final companyCode = _companyCodeController.text.isNotEmpty
          ? _companyCodeController.text
          : null;

      ref.read(authNotifierProvider.notifier).update(
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
    final isLightTheme = ref.watch(themeProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Profile',
          style: GoogleFonts.montserrat(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: SizedBox(
              width: 55,
              height: 30,
              child: AnimatedToggleSwitch<bool>.dual(
                current: isLightTheme,
                first: false,
                second: true,
                spacing: 1,
                style: ToggleStyle(
                  backgroundColor:
                      isLightTheme ? Colors.white : Colors.grey[800],
                  borderColor: Colors.transparent,
                  boxShadow: [
                    const BoxShadow(
                      color: Colors.black26,
                      spreadRadius: 1,
                      blurRadius: 2,
                      offset: Offset(0, 1.5),
                    ),
                  ],
                ),
                borderWidth: 4,
                height: 50,
                onChanged: (b) {
                  ref.read(themeProvider.notifier).state = b;
                },
                styleBuilder: (b) => ToggleStyle(
                  indicatorColor: !b ? Colors.blue : Colors.green,
                ),
                iconBuilder: (value) => value
                    ? const FittedBox(
                        fit: BoxFit.contain,
                        child: Icon(
                          Icons.wb_sunny,
                          color: Colors.white,
                          size: 18,
                        ),
                      )
                    : const FittedBox(
                        fit: BoxFit.contain,
                        child: Icon(
                          Icons.nights_stay,
                          size: 18,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    Visibility(
                      visible: !positive,
                      child: Column(
                        children: [
                          GestureDetector(
                            onTap: _pickImage,
                            child: CircleAvatar(
                              radius: 50,
                              child: _image != null
                                  ? ClipOval(
                                      child: Image.file(
                                        _image!,
                                        fit: BoxFit.cover,
                                        width: 100,
                                        height: 100,
                                      ),
                                    )
                                  : (widget.user['picture'] != null &&
                                          (widget.user['picture'] as String)
                                              .isNotEmpty)
                                      ? ClipOval(
                                          child: Image.network(
                                            _getProfileImageUrl(
                                                widget.user['picture']),
                                            fit: BoxFit.cover,
                                            width: 100,
                                            height: 100,
                                          ),
                                        )
                                      : Text(
                                          (widget.user['name'] as String)
                                                  .isNotEmpty
                                              ? (widget.user['name']
                                                      as String)[0]
                                                  .toUpperCase()
                                              : '?',
                                          style:
                                              const TextStyle(fontSize: 40.0),
                                        ),
                            ),
                          ),
                          const SizedBox(height: 32.0),
                          InputWidget(
                              hintText: 'Name',
                              prefixIcon: const Icon(Icons.person),
                              controller: _nameController,
                              obscureText: false,
                              validator: ValidationBuilder()
                                  .required()
                                  .minLength(2)
                                  .build()),
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
                          Visibility(
                            visible: _companyCodeController.text.isNotEmpty,
                            child: Column(
                              children: [
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
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16.0),
                    Row(
                      children: [
                        SizedBox(
                          child: AnimatedToggleSwitch<bool>.dual(
                            current: positive,
                            first: false,
                            second: true,
                            spacing: 50.0,
                            style: const ToggleStyle(
                              borderColor: Colors.transparent,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black26,
                                  spreadRadius: 1,
                                  blurRadius: 2,
                                  offset: Offset(0, 1.5),
                                ),
                              ],
                            ),
                            borderWidth: 5.0,
                            height: 55,
                            onChanged: (b) => setState(() => positive = b),
                            styleBuilder: (b) => ToggleStyle(
                                indicatorColor: b ? Colors.red : Colors.green),
                            iconBuilder: (value) => value
                                ? const Icon(Icons.nightlight)
                                : const Icon(Icons.sunny),
                            textBuilder: (value) => value
                                ? const Center(child: Text('Oh no...'))
                                : const Center(child: Text('Nice :)')),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16.0),
                    Visibility(
                      visible: positive,
                      child: Column(
                        children: [
                          InputWidget(
                            hintText: 'Old Password',
                            prefixIcon: const Icon(Icons.lock),
                            controller: _passwordController,
                            obscureText: true,
                            validator: ValidationBuilder()
                                .required()
                                .minLength(6)
                                .build(),
                          ),
                          const SizedBox(height: 16.0),
                          InputWidget(
                            hintText: 'New Password',
                            prefixIcon: const Icon(Icons.lock),
                            controller: _passwordController,
                            obscureText: true,
                            validator: ValidationBuilder()
                                .required()
                                .minLength(6)
                                .build(),
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
                          const SizedBox(height: 16.0),
                        ],
                      ),
                    ),
                    Consumer(
                      builder: (context, ref, _) {
                        final authState = ref.watch(authNotifierProvider);
                        bool isLoading = authState.isLoading;
                        return SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: isLoading ? null : _validate,
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  Theme.of(context).colorScheme.primary,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 120,
                                vertical: 15,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: isLoading
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.black,
                                      strokeWidth: 3,
                                    ),
                                  )
                                : Text(
                                    'Update',
                                    style: GoogleFonts.montserrat(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onPrimary,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            Visibility(
              visible: !positive,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _logout(context, ref),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 120,
                        vertical: 15,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Logout',
                      style: GoogleFonts.montserrat(
                        color: Theme.of(context).colorScheme.onPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
