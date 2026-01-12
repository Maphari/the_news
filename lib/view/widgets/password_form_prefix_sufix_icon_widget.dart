import 'package:flutter/material.dart';

class PasswordFormPrefixSufixIconWidget extends StatefulWidget {
  const PasswordFormPrefixSufixIconWidget({
    super.key,
    required this.labelText,
    required this.hintText,
    required this.prefixIcon,
    required this.valiadate,
    required this.controller, required this.focusNode,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String labelText;
  final String hintText;
  final IconData prefixIcon;
  final String? Function(String?) valiadate;

  @override
  State<PasswordFormPrefixSufixIconWidget> createState() => _PasswordFormPrefixSufixIconWidgetState();
}

class _PasswordFormPrefixSufixIconWidgetState extends State<PasswordFormPrefixSufixIconWidget> {
  late IconData sufixIcon;
  bool isPasswordVisible = false;
  bool isObscureText = true;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      style: TextStyle(color: Color.fromARGB(255, 168, 167, 167)),
      obscureText: !isPasswordVisible,
      focusNode: widget.focusNode,
      decoration: InputDecoration(
        labelText: widget.labelText,
        hintText: widget.hintText,
        prefixIcon: Icon(
          widget.prefixIcon,
          color: Color.fromARGB(255, 168, 167, 167),
        ),
        suffixIcon: IconButton(
          icon: Icon(
            isPasswordVisible
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
            color: Color.fromARGB(255, 168, 167, 167),
          ),
          onPressed: () {
            setState(() {
              isPasswordVisible = !isPasswordVisible;
            });
          },
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: const Color.fromARGB(255, 25, 24, 24),
        labelStyle: TextStyle(color: Color.fromARGB(255, 168, 167, 167)),
      ),
      validator: widget.valiadate,
    );
  }
}
