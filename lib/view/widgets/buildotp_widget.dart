import 'package:flutter/material.dart';
import 'package:the_news/constant/design_constants.dart';
import 'package:flutter/services.dart';
import 'package:the_news/constant/theme/default_theme.dart';
import 'package:the_news/controller/otp_controller.dart';

Widget buildOtpField(
  int index, {
  required OtpController otp,
  required BuildContext context,
}) {
  final colorScheme = Theme.of(context).colorScheme;
  final onSurface = KAppColors.getOnSurface(context);

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
            color: hasErrorState ? colorScheme.error : onSurface,
            height: 1.0,
          ),
          cursorColor: hasErrorState ? colorScheme.error : colorScheme.primary,
          cursorWidth: 2,
          cursorHeight: 24,
          decoration: InputDecoration(
            counterText: '',
            filled: true,
            fillColor: hasErrorState 
                ? colorScheme.error.withValues(alpha: 0.1)
                : onSurface.withValues(alpha: 0.05),
            contentPadding: const EdgeInsets.symmetric(vertical: 18),
            border: OutlineInputBorder(
              borderRadius: KBorderRadius.md,
              borderSide: BorderSide(
                color: hasErrorState ? colorScheme.error : onSurface.withValues(alpha: 0.2),
                width: 1.5,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: KBorderRadius.md,
              borderSide: BorderSide(
                color: hasErrorState
                    ? colorScheme.error
                    : hasValue
                        ? colorScheme.primary.withValues(alpha: 0.5)
                        : onSurface.withValues(alpha: 0.2),
                width: 1.5,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: KBorderRadius.md,
              borderSide: BorderSide(
                color: hasErrorState ? colorScheme.error : colorScheme.primary,
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
