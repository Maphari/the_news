import 'package:flutter/material.dart';

//? Registe & Login Screen
ValueNotifier<bool> isRegisterPageLoading = ValueNotifier(false);

ValueNotifier<bool> isLoginPageLoading = ValueNotifier(false);
ValueNotifier<bool> isLoginPageRememberMe = ValueNotifier(false);

ValueNotifier<TextEditingController> emailTextController = ValueNotifier(
  TextEditingController(),
);
ValueNotifier<TextEditingController> passwordTextController = ValueNotifier(
  TextEditingController(),
);

//? Otp screen
ValueNotifier<List<TextEditingController>> otpTextController = ValueNotifier(
  List.generate(6, (index) => TextEditingController()),
);
ValueNotifier<List<FocusNode>> otpFocusNodes = ValueNotifier(
  List.generate(6, (index) => FocusNode()),
);

ValueNotifier<String> message = ValueNotifier('');
