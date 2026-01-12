import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:the_news/constant/theme/default_theme.dart';
import 'package:the_news/controller/otp_controller.dart';

Widget buildOtpField(
  int index, {
  required OtpController otp,
  required BuildContext context,
}) {
  final merged = Listenable.merge([
    otp.textControllers[index],
    otp.focusNodes[index],
    otp.hasError, // Add error listener
  ]);

  return AnimatedBuilder(
    animation: merged,
    builder: (_, __) {
      final _ = otp.focusNodes[index].hasFocus;
      final hasValue = otp.textControllers[index].text.isNotEmpty;
      final hasErrorState = otp.hasError.value;

      return SizedBox(
        width: 50,
        height: 60,
        child: TextField(
          controller: otp.textControllers[index],
          focusNode: otp.focusNodes[index],
          textAlign: TextAlign.center,
          keyboardType: TextInputType.number,
          maxLength: 1,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: hasErrorState ? Colors.red : KAppColors.onSurface,
            height: 1.0,
          ),
          cursorColor: hasErrorState ? Colors.red : KAppColors.secondary,
          cursorWidth: 2,
          cursorHeight: 24,
          decoration: InputDecoration(
            counterText: '',
            filled: true,
            fillColor: hasErrorState 
                ? Colors.red.withValues(alpha: 0.1)
                : KAppColors.onSurface.withValues(alpha: 0.05),
            contentPadding: const EdgeInsets.symmetric(vertical: 18),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: hasErrorState
                    ? Colors.red
                    : KAppColors.onSurface.withValues(alpha: 0.2),
                width: 1.5,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: hasErrorState
                    ? Colors.red
                    : hasValue
                        ? KAppColors.secondary.withValues(alpha: 0.5)
                        : KAppColors.onSurface.withValues(alpha: 0.2),
                width: 1.5,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: hasErrorState ? Colors.red : KAppColors.secondary,
                width: 2,
              ),
            ),
          ),
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          onChanged: (v) {
            if (hasErrorState) {
              otp.hasError.value = false; // Clear error when user types
            }
            otp.onChanged(v, index);
          },
          onTap: () => otp.textControllers[index].clear(),
          onEditingComplete: () {
            if (index == 5) {
              otp.verifyOtpCodeAndSaveUser(
                context: context,
                userOtp: otp.otp,
              );
            }
          },
        ),
      );
    },
  );
}