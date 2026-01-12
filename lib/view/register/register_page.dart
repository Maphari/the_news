import 'package:flutter/material.dart';
import 'package:the_news/constant/theme/default_theme.dart';
import 'package:the_news/controller/apple_controller.dart';
import 'package:the_news/controller/google_controller.dart';
import 'package:the_news/controller/register_controller.dart';
import 'package:the_news/state/form_state.dart';
import 'package:the_news/utils/form_validations_utils.dart';
import 'package:the_news/utils/statusbar_helper_utils.dart';
import 'package:the_news/view/login/login_page.dart';
import 'package:the_news/view/widgets/password_form_prefix_sufix_icon_widget.dart';
import 'package:the_news/view/widgets/register_login_bottom_section_widget.dart';
import 'package:the_news/view/widgets/text_form_prefix_icon_widget.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  //? Form Key and Controllers
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final _passwordFocusNode = FocusNode();
  final _confirmPasswordFocusNode = FocusNode();

  bool _acceptTerms = false;

  //? Static Texts
  final String _registerHeader = 'Create Account';
  final String _registerSubHeader = 'Join us to discover news tailored for you';
  final String _termsAndConditionsText =
      'By creating an account, you agree to our ';
  final String _termsAndConditionsLinkText = 'Terms & Conditions';
  final String _loginPrompt = 'Already have an account? ';

  //? Colors
  final Color _screenBackgroundColor = KAppColors.background;

  @override
  void initState() {
    super.initState();
    //? Set status bar to light mode for this page
    StatusBarHelper.setLightStatusBar();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
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
                      _registerHeader,
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        color: KAppColors.onSurface,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      _registerSubHeader,
                      style: Theme.of(
                        context,
                      ).textTheme.bodyLarge?.copyWith(color: KAppColors.getOnBackground(context).withValues(alpha: 0.5)),
                    ),

                    const SizedBox(height: 30),

                    //? Name Field
                    TextFormPrefixIconWidget(
                      labelText: 'Full Name',
                      hintText: 'Enter your full name',
                      prefixIcon: Icons.person_outline,
                      valiadateName: valiadateName,
                      controller: _nameController,
                    ),
                    const SizedBox(height: 16),

                    //? Email Field
                    TextFormPrefixIconWidget(
                      labelText: 'Email',
                      hintText: 'Enter your email',
                      prefixIcon: Icons.email_outlined,
                      valiadateName: validateEmail,
                      controller: _emailController,
                    ),

                    const SizedBox(height: 16),

                    //? Password Field
                    PasswordFormPrefixSufixIconWidget(
                      labelText: 'Password',
                      hintText: 'Create a password',
                      prefixIcon: Icons.lock_outline,
                      valiadate: validatePassword,
                      controller: _passwordController,
                      focusNode: _passwordFocusNode,
                    ),

                    const SizedBox(height: 16),

                    //? Confirm Password Field
                    PasswordFormPrefixSufixIconWidget(
                      labelText: 'Confirm Password',
                      hintText: 'Re-enter your password',
                      prefixIcon: Icons.lock_outline,
                      valiadate: validatePassword,
                      controller: _confirmPasswordController,
                      focusNode: _confirmPasswordFocusNode,
                    ),

                    const SizedBox(height: 16),

                    //? Terms and Conditions Checkbox
                    Row(
                      children: [
                        Checkbox(
                          value: _acceptTerms,
                          onChanged: (value) {
                            setState(() {
                              _acceptTerms = value ?? false;
                            });
                          },
                          activeColor: KAppColors.secondary,
                          checkColor: KAppColors.onPrimary,
                          side: const BorderSide(
                            color: KAppColors.secondary,
                            width: 2,
                          ),
                        ),
                        Expanded(
                          child: Wrap(
                            children: [
                              Text(
                                _termsAndConditionsText,
                                style: TextStyle(color: KAppColors.getOnBackground(context).withValues(alpha: 0.5)),
                              ),
                              GestureDetector(
                                onTap: () {
                                  // Show terms and conditions
                                },
                                child: Text(
                                  _termsAndConditionsLinkText,
                                  style: TextStyle(
                                    color: KAppColors.onSurface,
                                    fontWeight: FontWeight.w600,
                                    decoration: TextDecoration.underline,
                                    decorationColor: KAppColors.onSurface,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    //? Register Button
                    SizedBox(
                      height: 53,
                      width: double.infinity,
                      child: ValueListenableBuilder(
                        valueListenable: isRegisterPageLoading,
                        builder: (context, bool isLoading, _) {
                          return FilledButton(
                            onPressed: isLoading
                                ? null
                                : () => handleAuthButtonPress(
                                    context: context,
                                    formKey: _formKey,
                                    isLoading: isLoading,
                                    names: _nameController.text,
                                    email: _emailController.text,
                                    password: _passwordController.text,
                                    confirmPassword:
                                        _confirmPasswordController.text,
                                    acceptedTerms: _acceptTerms,
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
                                    'Create Account',
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
                      formType: 'Sign up',
                      toFormType: 'Sign in',
                      onPressedGoogle: () {
                        handleGoogleSignIn(context);
                      },
                      onPressedApple: () {
                        handleAppleSignIn(context);
                      },
                      whichPage: LoginPage(),
                      whichPagePrompt: _loginPrompt,
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
