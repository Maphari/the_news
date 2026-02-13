import 'package:flutter/material.dart';
import 'package:the_news/constant/design_constants.dart';

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
    final colorScheme = Theme.of(context).colorScheme;
    return TextFormField(
      controller: widget.controller,
      style: TextStyle(color: colorScheme.onSurface),
      obscureText: !isPasswordVisible,
      focusNode: widget.focusNode,
      decoration: InputDecoration(
        labelText: widget.labelText,
        hintText: widget.hintText,
        prefixIcon: Icon(
          widget.prefixIcon,
          color: colorScheme.onSurfaceVariant,
        ),
        suffixIcon: IconButton(
          icon: Icon(
            isPasswordVisible
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
            color: colorScheme.onSurfaceVariant,
          ),
          onPressed: () {
            setState(() {
              isPasswordVisible = !isPasswordVisible;
            });
          },
        ),
        border: OutlineInputBorder(borderRadius: KBorderRadius.md),
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest,
        labelStyle: TextStyle(color: colorScheme.onSurfaceVariant),
      ),
      validator: widget.valiadate,
    );
  }
}
