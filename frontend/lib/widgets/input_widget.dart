import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class InputWidget extends StatefulWidget {
  final String hintText;
  final TextEditingController controller;
  final bool obscureText;
  final bool digitsOnly;
  final bool isEmail;
  final Icon? prefixIcon;
  final String? Function(String?)? validator;
  final bool isError; // Add a validator function

  const InputWidget({
    super.key,
    required this.hintText,
    required this.controller,
    this.digitsOnly = false,
    this.obscureText = false,
    this.isEmail = false,
    this.prefixIcon, // Accept the prefix icon as a parameter
    this.validator,
    this.isError = false,
    String? errorText, // Accept the validator as a parameter
  });

  @override
  _InputWidgetState createState() => _InputWidgetState();
}

class _InputWidgetState extends State<InputWidget> {
  bool _showPassword = false; // Control the visibility of the password
  String? _errorText;

  @override
  Widget build(BuildContext context) {
    // final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: widget.controller,
          keyboardType: widget.digitsOnly || widget.isEmail
              ? widget.isEmail
                  ? TextInputType.emailAddress
                  : TextInputType.number
              : null,
          obscureText:
              widget.obscureText && !_showPassword, // Toggle obscure text
          decoration: InputDecoration(
            filled: true, // To enable the background color
            // fillColor: widget.isError || _errorText != null
            //     ? Colors.red
            //     : Colors.white,
            labelText: widget.hintText,
            labelStyle: GoogleFonts.poppins(
              fontSize: 16,
              // color: widget.isError || _errorText != null
              //     ? Colors.white
              //     : Colors.black,
              fontWeight:
                  FontWeight.w400, // You can adjust the font weight as needed
              //color: Colors.grey, // Adjust label color if needed
            ),
            floatingLabelBehavior: FloatingLabelBehavior.auto,
            prefixIcon: widget.prefixIcon,
            hintStyle: const TextStyle(
              color: Colors.black, // Text color
              fontSize: 18.0, // Text size
            ), // Add the prefix icon here
            suffixIcon: widget.obscureText
                ? IconButton(
                    icon: Icon(
                      _showPassword ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _showPassword =
                            !_showPassword; // Toggle password visibility
                      });
                    },
                  )
                : null, // Only show eye icon if it's a password field
            errorText: _errorText, // Display error text if any
          ),
          onChanged: (value) {
            if (widget.validator != null) {
              setState(() {
                _errorText = widget
                    .validator!(value); // Update error text if validation fails
              });
            }
          },
        ),
      ],
    );
  }
}
