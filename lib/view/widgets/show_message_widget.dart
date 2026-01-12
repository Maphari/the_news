import 'package:flutter/material.dart';
import 'package:the_news/view/widgets/snackbar_widget.dart';

void successMessage({required BuildContext context, required String message}) {
  showModernSnackBar(
    context,
    message,
    type: MessageType.success,
  );
}

void errorMessage({required BuildContext context, required String message}) {
  showModernSnackBar(
    context,
    message,
    type: MessageType.error,
  );
}

void warningMessage({required BuildContext context, required String message}) {
  showModernSnackBar(
    context,
    message,
    type: MessageType.warning,
  );
}

void infoMessage({required BuildContext context, required String message}) {
  showModernSnackBar(
    context,
    message,
    type: MessageType.info,
  );
}