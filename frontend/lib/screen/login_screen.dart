import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:form_validator/form_validator.dart';
import 'package:frontend/notifiers/auth_notifier.dart';
import 'package:frontend/theme/colors.dart';
import 'package:frontend/theme/text_styles.dart';
import 'package:frontend/widgets/input_widget.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_custom_clippers/flutter_custom_clippers.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  LoginScreenState createState() => LoginScreenState();
}

class LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final GlobalKey<FormState> _form = GlobalKey<FormState>();
  bool _rememberMe = false;

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

  void _login() async {
    final email = _emailController.text;
    final password = _passwordController.text;
 
    final authNotifier = ref.read(authNotifierProvider.notifier);

    await authNotifier.login(
          email: email,
          password: password,
          context: context,
        );

    final authState = ref.read(authNotifierProvider);

    if(authState.isError){
      if(mounted) {
        showDialog(builder: (context) {
          return AlertDialog(
            title: Text(
              'Login Failed!', 
              style: AppTextStyles.subtitle.copyWith(
                color: Colors.red, 
                fontWeight: FontWeight.bold
              ),
              textAlign: TextAlign.center,
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Invalid email or password.\nPlease try again.',
                  style: AppTextStyles.body.copyWith(
                    color: Colors.black87
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                const Icon (
                  Icons.warning_rounded,
                  color: Colors.red,
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
        }, context: context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 254, 254, 254),
      body: Form(
        key: _form,
        
        child:SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                children: [
                  ClipPath(
                    clipper: WaveClipperOne(),
                    child: ColorFiltered(
                      colorFilter: ColorFilter.mode(
                        mainColor.withValues(alpha: 0.8), 
                        BlendMode.srcATop
                      ), // Apply color filter to the image
                      child: SizedBox(
                        height: MediaQuery.of(context).size.height * 0.4,
                        width: double.infinity,
                        child: Image.asset(
                          'assets/Freight Forwarding.jpg', // Replace with your background image
                          fit: BoxFit.cover,
                        ),
                      ),
                    )
                  ),
                  Positioned.fill(
                    child: Center(
                      child: Image.asset(
                        'assets/Yello X white.png',
                        width: 250, // Adjust size of the top image
                        height: 250,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 20.0),
                    Text(
                      'Welcome Back',
                      style: GoogleFonts.montserrat(
                        color: mainColor,
                        fontSize: 34,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Login to your account',
                      style: GoogleFonts.montserrat(
                        color: Colors.grey,
                        fontSize:16,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 20.0),
                    Column(
                      children: [
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
                                color:  mainColor,
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
                                color: mainColor,
                              ),
                              validator:
                                  ValidationBuilder().minLength(5).maxLength(50).build(),
                              errorText: isError
                                  ? "Invalid email or password"
                                  : null, // Conditionally show error text
                            );
                          },
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Row(
                            //   children:[
                            //     Checkbox(
                            //       value: _rememberMe,
                            //       activeColor: mainColor,
                            //       checkColor: Colors.white,
                            //       materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            //       visualDensity: VisualDensity.compact,
                            //       onChanged: (value) {
                            //         setState(() {
                            //           _rememberMe = value!;
                            //         });
                            //       }, 
                            //     ),
                            //     // const SizedBox(width: 4.0),
                            //     Text(
                            //       'Remember Me',
                            //       style: GoogleFonts.montserrat(
                            //         color: mainColor,
                            //         fontSize: 12,
                            //         fontWeight: FontWeight.bold,
                                    
                            //       ),
                            //     ),
                            //   ]
                            // ),
                            Row(
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _rememberMe = !_rememberMe;
                                    });
                                  },
                                  child: Container(
                                    width: 20,
                                    height: 20,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: mainColor,
                                        width: 2,
                                      ),
                                      color: _rememberMe
                                          ? mainColor
                                          : Colors.transparent,
                                    ),
                                    child: _rememberMe
                                        ? const Center(
                                            child: Icon(
                                              Icons.check,
                                              size: 10,
                                              color: Colors.white,
                                            ),
                                          )
                                        : null,
                                  ),
                                ),
                                const SizedBox(width: 8.0),
                                Text(
                                  'Remember Me',
                                  style: GoogleFonts.montserrat(
                                    color: mainColor,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),

                            TextButton(
                              onPressed: () {
                                //Forgot password action
                              },
                              child: Text(
                                'Forgot Password?',
                                style: GoogleFonts.montserrat(
                                  color: mainColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            )
                          ],  
                        ),
                      
                      
                        const SizedBox(height: 32.0),
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
                                  backgroundColor: mainColor,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 20,
                                  ),
                                  disabledForegroundColor: mainColor,
                                  disabledBackgroundColor: mainColor,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30.0),
                                  ),
                                ),
                                child: isLoading
                                    ? const SizedBox(
                                        width:
                                            24, // Set the width for the CircularProgressIndicator
                                        height:
                                            24, // Set the height for the CircularProgressIndicator
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth:
                                              2, // Adjust the thickness of the spinner
                                        ),
                                      )
                                    : Text(
                                        'Sign In',
                                        style: GoogleFonts.montserrat(
                                          color: Colors.white,
                                          fontSize: 16, // Updated font size to 20
                                          fontWeight: FontWeight.bold,
                                        ),
                                        textAlign: TextAlign.center, // Ensure the text is centered
                                      ),
                                ));
                            },
                          ),
                        ],
                      )
                    ]
                
                    // const SizedBox(height: 8.0),
                    
                    
                    
                    
                    
                  
                    // const SizedBox(height: 25.0),
                    // RichText(
                    //   text: TextSpan(
                    //     text: "Don't have an account? ",
                    //     style: GoogleFonts.montserrat(
                    //       textStyle: const TextStyle(
                    //         fontSize: 16,
                    //         color: Colors.white,
                    //       ),
                    //     ),
                    //     children: [
                    //       TextSpan(
                    //         text: 'Sign Up',
                    //         style: GoogleFonts.montserrat(
                    //           textStyle: const TextStyle(
                    //             fontWeight: FontWeight.bold,
                    //             decoration: TextDecoration.underline,
                    //             fontSize: 16,
                    //             color: Color(0xFFFFC72C),
                    //           ),
                    //         ),
                    //         recognizer: TapGestureRecognizer()
                    //           ..onTap = () {
                    //             Navigator.push(
                    //               context,
                    //               MaterialPageRoute(
                    //                 builder: (context) => const RegisterOptionsScreen(),
                    //               ),
                    //             );
                    //           },
                    //       ),
                    //     ],
                    //   ),
                    // ),
                  ),
                ),
              ],
          ),
        ),
      )
    );
  }
}
