import 'package:flutter/material.dart';
import 'package:the_news/constant/design_constants.dart';

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
    final colorScheme = Theme.of(context).colorScheme;
    return TextFormField(
      controller: controller,
      style: TextStyle(color: colorScheme.onSurface),
      keyboardType: labelText == 'Email' ? TextInputType.emailAddress : TextInputType.text,
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        prefixIcon: Icon(
          prefixIcon,
          color: colorScheme.onSurfaceVariant,
        ),
        border: OutlineInputBorder(borderRadius: KBorderRadius.md),
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest,
        labelStyle: TextStyle(color: colorScheme.onSurfaceVariant),
      ),
      validator: valiadateName,
    );
  }
}
