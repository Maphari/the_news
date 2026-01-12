import 'package:flutter/material.dart';
import 'package:the_news/constant/theme/default_theme.dart';
import 'package:the_news/controller/apple_controller.dart';
import 'package:the_news/controller/google_controller.dart';
import 'package:the_news/controller/login_controller.dart';
import 'package:the_news/state/form_state.dart';
import 'package:the_news/utils/form_validations_utils.dart';
import 'package:the_news/utils/statusbar_helper_utils.dart';
import 'package:the_news/view/register/register_page.dart';
import 'package:the_news/view/widgets/password_form_prefix_sufix_icon_widget.dart';
import 'package:the_news/view/widgets/register_login_bottom_section_widget.dart';
import 'package:the_news/view/widgets/text_form_prefix_icon_widget.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  //? Form Key and Controllers
  final _formKey = GlobalKey<FormState>();
  final _passwordFocusNode = FocusNode();

  //? Static Texts
  final String _loginHeader = 'Welcome Back';
  final String _loginSubHeader = 'Sign in to continue to your account';
  final String _forgotPasswordText = 'Forgot Password?';
  final String _registerPrompt = "Don't have an account? ";

  //? Colors
  final Color _screenBackgroundColor = KAppColors.background;

  @override
  void initState() {
    super.initState();
    //? Set status bar to light mode for this page
    StatusBarHelper.setLightStatusBar();
    //? Load saved credentials
    loadSavedCredentials(mounted: mounted);
  }

  @override
  void dispose() {
    _passwordFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StatusBarHelper.wrapWithStatusBar(
      backgroundColor: _screenBackgroundColor,
      child: Scaffold(
        backgroundColor: _screenBackgroundColor,
        body: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _loginHeader,
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        color: KAppColors.onSurface,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      _loginSubHeader,
                      style: Theme.of(
                        context,
                      ).textTheme.bodyLarge?.copyWith(color: KAppColors.getOnBackground(context).withValues(alpha: 0.5)),
                    ),

                    const SizedBox(height: 40),

                    //? Email Field
                    ValueListenableBuilder(
                      valueListenable: emailTextController,
                      builder:
                          (context, TextEditingController emailController, _) {
                            return TextFormPrefixIconWidget(
                              labelText: 'Email',
                              hintText: 'Enter your email',
                              prefixIcon: Icons.email_outlined,
                              valiadateName: validateEmail,
                              controller: emailController,
                            );
                          },
                    ),

                    const SizedBox(height: 16),

                    //? Password Field
                    ValueListenableBuilder(
                      valueListenable: passwordTextController,
                      builder:
                          (
                            context,
                            TextEditingController passwordController,
                            _,
                          ) {
                            return PasswordFormPrefixSufixIconWidget(
                              labelText: 'Password',
                              hintText: 'Enter your password',
                              prefixIcon: Icons.lock_outline,
                              valiadate: validatePassword,
                              controller: passwordController,
                              focusNode: _passwordFocusNode,
                            );
                          },
                    ),

                    const SizedBox(height: 12),

                    //? Remember Me and Forgot Password Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            ValueListenableBuilder(
                              valueListenable: isLoginPageRememberMe,
                              builder: (context, bool isChecked, _) {
                                return Checkbox(
                                  value: isChecked,
                                  onChanged: (value) async {
                                    await handleRememberMeToggle(
                                      value,
                                      email: emailTextController.value.text,
                                      password:
                                          passwordTextController.value.text,
                                    );
                                  },
                                  activeColor: KAppColors.secondary,
                                  checkColor: KAppColors.onPrimary,
                                  side: const BorderSide(
                                    color: KAppColors.secondary,
                                    width: 2,
                                  ),
                                );
                              },
                            ),
                            Text(
                              'Remember me',
                              style: TextStyle(color: KAppColors.getOnBackground(context).withValues(alpha: 0.4)),
                            ),
                          ],
                        ),
                        TextButton(
                          onPressed: () {},
                          child: Text(
                            _forgotPasswordText,
                            style: const TextStyle(
                              color: KAppColors.onSurface,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    //? Login Button
                    SizedBox(
                      height: 53,
                      width: double.infinity,
                      child: ValueListenableBuilder(
                        valueListenable: isLoginPageLoading,
                        builder: (context, bool isLoading, _) {
                          return FilledButton(
                            onPressed: isLoading
                                ? null
                                : () => handleLoginWithRememberMe(
                                    context: context,
                                    email: emailTextController.value.text,
                                    password: passwordTextController.value.text,
                                    formKey: _formKey,
                                  ),
                            style: FilledButton.styleFrom(
                              backgroundColor: KAppColors.secondary,
                              foregroundColor: KAppColors.onPrimary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 0,
                            ),
                            child: isLoading
                                ? const SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: KAppColors.secondary,
                                    ),
                                  )
                                : const Text(
                                    'Log In',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 24),

                    //? Bottom Section Widget for Social Login and Register Link
                    RegisterLoginBottomSectionWidget(
                      formType: 'Sign in',
                      toFormType: 'Sign up',
                      onPressedGoogle: () => handleGoogleSignIn(context),
                      onPressedApple: () => handleAppleSignIn(context),
                      whichPage: RegisterPage(),
                      whichPagePrompt: _registerPrompt,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
