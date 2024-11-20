import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:form_validator/form_validator.dart';
import 'package:frontend/notifiers/auth_notifier.dart';
import 'package:frontend/screen/register_options.dart';
import 'package:frontend/widgets/input_widget.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final GlobalKey<FormState> _form = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _validate() {
    final formState = _form.currentState;
    if (formState != null && formState.validate()) {
      formState.save();
      // Form is valid and saved
      _login();
    }
  }

  void _login() {
    final email = _emailController.text;
    final password = _passwordController.text;

    ref.read(authNotifierProvider.notifier).login(
          email: email,
          password: password,
          context: context,
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1d3c34),
      body: Form(
        key: _form,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 25.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                decoration: const BoxDecoration(
                  color: Colors.white, // Background color
                  shape: BoxShape.circle, // Circular shape
                ),
                height: 240, // Adjust as needed
                width: 240, // Adjust as needed
                child: ClipOval(
                  child: Image.asset(
                    'assets/xlogo.png',
                    height: 250, // Adjust as needed
                    width: 250, // Adjust as needed
                    fit: BoxFit.cover, // Adjust if needed to fit the circle
                  ),
                ),
              ),
              Text(
                'Yello Drive',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12.0),
              Consumer(
                builder: (context, ref, _) {
                  var authState = ref.watch(authNotifierProvider);
                  bool isError = authState.isError;
                  if (kDebugMode) {
                    print(isError);
                    print('Error from the Email');
                  }
                  return InputWidget(
                    hintText: 'Email',
                    isEmail: true,
                    controller: _emailController,
                    obscureText: false,
                    prefixIcon: const Icon(
                      Icons.mail,
                      color: Colors.black,
                    ),
                    validator:
                        ValidationBuilder().email().maxLength(50).build(),
                    errorText: isError
                        ? "Invalid email or password"
                        : null, // Conditionally show error text
                  );
                },
              ),
              const SizedBox(height: 16.0),
              Consumer(
                builder: (context, ref, _) {
                  var authState = ref.watch(authNotifierProvider);
                  bool isError = authState.isError;
                  if (kDebugMode) {
                    print(isError);
                    print('Erorr for the Password');
                  }
                  return InputWidget(
                    hintText: 'Password',
                    controller: _passwordController,
                    obscureText: true,
                    prefixIcon: const Icon(
                      Icons.lock,
                      color: Colors.black,
                    ),
                    validator:
                        ValidationBuilder().minLength(5).maxLength(50).build(),
                    errorText: isError
                        ? "Invalid email or password"
                        : null, // Conditionally show error text
                  );
                },
              ),
              const SizedBox(height: 16.0),
              Consumer(
                builder: (context, ref, _) {
                  final authState = ref.watch(authNotifierProvider);
                  bool isLoading = authState.isLoading;
                  bool isError = authState.isError;
                  if (kDebugMode) {
                    print('Erorr is occuring into our system');
                    print(isError);
                  }
                  return SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : _validate,
                        // onPressed: null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFC72C),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 150,
                            vertical: 20,
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
                                'Sign In',
                                style: GoogleFonts.poppins(
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
              const SizedBox(height: 25.0),
              RichText(
                text: TextSpan(
                  text: "Don't have an account? ",
                  style: GoogleFonts.poppins(
                    textStyle: const TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                  children: [
                    TextSpan(
                      text: 'Sign Up',
                      style: GoogleFonts.poppins(
                        textStyle: const TextStyle(
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.underline,
                          fontSize: 16,
                          color: Color(0xFFFFC72C),
                        ),
                      ),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const RegisterOptionsScreen(),
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
    );
  }
}
