import 'package:flutter/material.dart';

class TextFormPrefixIconWidget extends StatelessWidget {
  const TextFormPrefixIconWidget({
    super.key,
    required this.labelText,
    required this.hintText,
    required this.prefixIcon,
    required this.valiadateName,
    required this.controller,
  });

  final TextEditingController controller;
  final String labelText;
  final String hintText;
  final IconData prefixIcon;
  final String? Function(String?) valiadateName;
  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      style: TextStyle(color: Color.fromARGB(255, 168, 167, 167),),
      keyboardType: labelText == 'Email' ? TextInputType.emailAddress : TextInputType.text,
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        prefixIcon: Icon(
          prefixIcon,
          color: Color.fromARGB(255, 168, 167, 167),
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: const Color.fromARGB(255, 25, 24, 24),
        labelStyle: TextStyle(color: Color.fromARGB(255, 168, 167, 167)),
      ),
      validator: valiadateName,
    );
  }
}
