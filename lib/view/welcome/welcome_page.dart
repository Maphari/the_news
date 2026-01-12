import 'package:flutter/material.dart';
import 'package:the_news/constant/theme/default_theme.dart';
import 'package:the_news/utils/statusbar_helper_utils.dart';
import 'package:the_news/view/login/login_page.dart';
import 'package:the_news/view/register/register_page.dart';
import 'package:the_news/view/welcome/floating_avatars_widget.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage>
    with SingleTickerProviderStateMixin {

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    
    //? Set status bar for dark background
    StatusBarHelper.setLightStatusBar();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.3, 1.0, curve: Curves.easeIn),
      ),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StatusBarHelper.wrapWithStatusBar(
      backgroundColor: KAppColors.surface,
      child: Scaffold(
        backgroundColor: KAppColors.surface,
        body: SafeArea(
          child: Stack(
            children: [
              //? Floating Profile Avatars Background
              const FloatingAvatars(),

              //? Main Content
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    const Spacer(flex: 10),
                    const SizedBox(height: 32),

                    //? Headline
                    SlideTransition(
                      position: _slideAnimation,
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: Column(
                          children: [
                            Text(
                              'Stories with a',
                              style: KAppTextStyles.displaySmall.copyWith(
                                color: KAppColors.onSurface,
                                fontSize: 36,
                                fontWeight: FontWeight.w300,
                                letterSpacing: 0.5,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            Text(
                              'Human touch!',
                              style: KAppTextStyles.displaySmall.copyWith(
                                color: KAppColors.onSurface,
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    //? Subtitle
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: Text(
                        'Discover news curated by real people,\nfor people who care',
                        style: KAppTextStyles.bodyLarge.copyWith(
                          color: KAppColors.onSurface.withValues(alpha: 0.7),
                          fontSize: 16,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),

                    const Spacer(flex: 3),

                    //? Get Started Button
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: () {
                            //? Navigate to register
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const RegisterPage(),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: KAppColors.secondary,
                            foregroundColor: KAppColors.onSecondary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            'Get started',
                            style: KAppTextStyles.labelLarge.copyWith(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    //? Sign In Link
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Already have an account? ',
                            style: KAppTextStyles.bodyMedium.copyWith(
                              color: KAppColors.onSurface.withValues(alpha: 0.7),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              //? Navigate to login
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const LoginPage(),
                                ),
                              );
                            },
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                            ),
                            child: Text(
                              'Sign in',
                              style: KAppTextStyles.labelLarge.copyWith(
                                color: KAppColors.secondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}