import 'package:flutter/material.dart';
import 'package:the_news/constant/design_constants.dart';
import 'package:the_news/constant/theme/default_theme.dart';
import 'package:the_news/controller/otp_controller.dart';
import 'package:the_news/model/register_login_success_model.dart';
import 'package:the_news/model/register_user_model.dart';
import 'package:the_news/utils/statusbar_helper_utils.dart';
import 'package:the_news/view/widgets/buildotp_widget.dart';
import 'package:the_news/view/widgets/show_message_widget.dart';
import 'package:the_news/view/widgets/app_back_button.dart';

class OtpVerificationPage extends StatefulWidget {
  final RegisterLoginUserSuccessModel successUser;
  final RegisterUserModel registerUserModel;

  const OtpVerificationPage({
    super.key,
    required this.successUser,
    required this.registerUserModel,
  });

  @override
  State<OtpVerificationPage> createState() => _OtpVerificationPageState();
}

class _OtpVerificationPageState extends State<OtpVerificationPage>
    with SingleTickerProviderStateMixin {
  late final OtpController otp;
  late String message;
  late String generatedOtpCode;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final String _verificationHeader = 'Verify Your Email';
  final String _verificationSubHeader = 'Enter the 6-digit code sent to';
  final String _resendText = "Didn't receive the code? ";
  final String _awaitingOtpMessage = 'Awaiting verification, please verify email';
  final String _successMessage = 'Otp sent Successufully';

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );

    _animationController.forward();

    otp = OtpController(
      user: widget.successUser,
      registerUserModel: widget.registerUserModel,
    )..startTimer();

    _sendInitialOtp();
  }

  @override
  void dispose() {
    _animationController.dispose();
    otp.dispose();
    super.dispose();
  }

  Future<void> _sendInitialOtp() async {
    final (message, otpCode) = await otp.sendOtp(
      email: widget.successUser.email,
      names: widget.successUser.name,
    );
    if (mounted) {
      if (message == _successMessage || message == _awaitingOtpMessage) {
        generatedOtpCode = otpCode;
        successMessage(context: context, message: message);
        return;
      }

      errorMessage(context: context, message: message);
      Navigator.pop(context);  
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final backgroundColor = KAppColors.getBackground(context);
    final onSurface = KAppColors.getOnSurface(context);
    final onBackground = KAppColors.getOnBackground(context);

    return StatusBarHelper.wrapWithStatusBar(
      backgroundColor: backgroundColor,
      child: Scaffold(
        backgroundColor: backgroundColor,
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                backgroundColor,
                backgroundColor,
                // _screenBackgroundColor.withValues(alpha: 0.95),
                // colorScheme.primary.withValues(alpha: 0.05),
              ],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                //? Custom AppBar
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      AppBackButton(
                        onPressed: () => Navigator.pop(context),
                        backgroundColor: onSurface.withValues(alpha: 0.1),
                        iconColor: onSurface,
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: SingleChildScrollView(
                        padding: KDesignConstants.paddingLg,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: KDesignConstants.spacing20),

                            //? Icon Container with gradient
                            Center(
                              child: Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      colorScheme.primary.withValues(
                                        alpha: 0.2,
                                      ),
                                      colorScheme.primary.withValues(
                                        alpha: 0.05,
                                      ),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(30),
                                  border: Border.all(
                                    color: colorScheme.primary.withValues(
                                      alpha: 0.3,
                                    ),
                                    width: 2,
                                  ),
                                ),
                                child: Icon(
                                  Icons.mail_outline_rounded,
                                  size: 48,
                                  color: colorScheme.primary,
                                ),
                              ),
                            ),

                            const SizedBox(height: KDesignConstants.spacing32),

                            //? Header
                            Center(
                              child: Text(
                                _verificationHeader,
                                style: Theme.of(context).textTheme.displaySmall
                                    ?.copyWith(
                                      color: onSurface,
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: -0.5,
                                    ),
                              ),
                            ),

                            const SizedBox(height: KDesignConstants.spacing12),

                            //? Sub-header
                            Center(
                              child: Column(
                                children: [
                                  Text(
                                    _verificationSubHeader,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: onBackground.withValues(alpha: 0.4),
                                      fontSize: 15,
                                    ),
                                  ),
                                  const SizedBox(height: KDesignConstants.spacing4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: colorScheme.primary.withValues(
                                        alpha: 0.1,
                                      ),
                                      borderRadius: KBorderRadius.xl,
                                      border: Border.all(
                                        color: colorScheme.primary.withValues(
                                          alpha: 0.3,
                                        ),
                                        width: 1,
                                      ),
                                    ),
                                    child: Text(
                                      widget.successUser.email,
                                      style: TextStyle(
                                        color: colorScheme.primary,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: KDesignConstants.spacing48),

                            //? OTP Fields Container
                            Container(
                              padding: KDesignConstants.paddingLg,
                              decoration: BoxDecoration(
                                color: onSurface.withValues(
                                  alpha: 0.05,
                                ),
                                borderRadius: KBorderRadius.xxl,
                                border: Border.all(
                                  color: onSurface.withValues(
                                    alpha: 0.1,
                                  ),
                                  width: 1,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: List.generate(
                                      OtpController.otpLength,
                                      (index) => buildOtpField(
                                        index,
                                        otp: otp,
                                        context: context,
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: KDesignConstants.spacing24),

                                  //? Timer/Resend Section
                                  AnimatedBuilder(
                                    animation: Listenable.merge([
                                      otp.secondsRemaining,
                                      otp.canResend,
                                    ]),
                                    builder: (_, __) {
                                      if (!otp.canResend.value) {
                                        return Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 12,
                                          ),
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                colorScheme.primary.withValues(
                                                  alpha: 0.1,
                                                ),
                                                colorScheme.primary.withValues(
                                                  alpha: 0.05,
                                                ),
                                              ],
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              16,
                                            ),
                                            border: Border.all(
                                              color: colorScheme.primary
                                                  .withValues(alpha: 0.2),
                                              width: 1,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.timer_outlined,
                                                color: colorScheme.primary,
                                                size: 20,
                                              ),
                                              const SizedBox(width: KDesignConstants.spacing8),
                                              Text(
                                                otp.timerText,
                                                style: TextStyle(
                                                  color: colorScheme.primary,
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      }

                                      return Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            _resendText,
                                            style: TextStyle(
                                              color: onBackground.withValues(alpha: 0.4),
                                            ),
                                          ),
                                          GestureDetector(
                                            onTap: otp.resend,
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                    vertical: 6,
                                                  ),
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  colors: [
                                                    colorScheme.primary
                                                        .withValues(alpha: 0.2),
                                                    colorScheme.primary
                                                        .withValues(alpha: 0.1),
                                                  ],
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                'Resend Code',
                                                style: TextStyle(
                                                  color: colorScheme.primary,
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 16,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: KDesignConstants.spacing32),

                            //? Verify Button
                            SizedBox(
                              width: double.infinity,
                              height: 58,
                              child: ValueListenableBuilder(
                                valueListenable: otp.isLoading,
                                builder: (_, loading, __) {
                                  return Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: loading
                                            ? [
                                                colorScheme.primary.withValues(
                                                  alpha: 0.9,
                                                ),
                                                colorScheme.primary.withValues(
                                                  alpha: 0.9,
                                                ),
                                              ]
                                            : [
                                                colorScheme.primary,
                                                colorScheme.primary.withValues(
                                                  alpha: 0.9,
                                                ),
                                              ],
                                      ),
                                      borderRadius: KBorderRadius.lg,
                                      boxShadow: loading
                                          ? []
                                          : [
                                              BoxShadow(
                                                color: colorScheme.onPrimary
                                                    .withValues(alpha: 0.3),
                                                blurRadius: 20,
                                                offset: const Offset(0, 10),
                                              ),
                                            ],
                                    ),
                                    child: FilledButton(
                                      onPressed: loading
                                          ? null
                                          : () => otp.verifyOtpCodeAndSaveUser(
                                              context: context,
                                              userOtp: generatedOtpCode,
                                            ),
                                      style: FilledButton.styleFrom(
                                        backgroundColor: Colors.transparent,
                                        foregroundColor: colorScheme.onPrimary,
                                        shadowColor: Colors.transparent,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                        ),
                                      ),
                                      child: loading
                                          ? SizedBox(
                                              width: 24,
                                              height: 24,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2.5,
                                                color: colorScheme.onPrimary,
                                              ),
                                            )
                                          : const Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Text(
                                                  'Verify Email',
                                                  style: TextStyle(
                                                    fontSize: 17,
                                                    fontWeight: FontWeight.w600,
                                                    letterSpacing: 0.5,
                                                  ),
                                                ),
                                                SizedBox(width: KDesignConstants.spacing8),
                                                Icon(
                                                  Icons.arrow_forward_rounded,
                                                  size: 20,
                                                ),
                                              ],
                                            ),
                                    ),
                                  );
                                },
                              ),
                            ),

                            const SizedBox(height: KDesignConstants.spacing24),

                            //? Security note
                            Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: onSurface.withValues(
                                    alpha: 0.05,
                                  ),
                                  borderRadius: KBorderRadius.md,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.lock_outline,
                                      size: 16,
                                      color: onBackground.withValues(alpha: 0.5),
                                    ),
                                    const SizedBox(width: KDesignConstants.spacing8),
                                    Text(
                                      'Your data is secure and encrypted',
                                      style: TextStyle(
                                        color: onBackground.withValues(alpha: 0.5),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
