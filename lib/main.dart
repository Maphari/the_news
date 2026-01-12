import 'package:flutter/material.dart';
import 'package:the_news/config/env_config.dart';
import 'package:the_news/constant/theme/app_theme.dart';
import 'package:the_news/model/register_login_success_model.dart';
import 'package:the_news/service/auth_service.dart';
import 'package:the_news/service/app_initialization_service.dart';
import 'package:the_news/service/theme_service.dart';
import 'package:the_news/service/notification_navigation_service.dart';
import 'package:the_news/config/firebase_config.dart';
import 'package:the_news/view/welcome/welcome_page.dart';
import 'package:the_news/routes/app_routes.dart';

void main() async {
  //? Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  //? initialise firebase
  initFirebase();

  //? Load environment variables
  await EnvConfig().load();

  //? Initialize app services (subscription, news API, etc.)
  try {
    await AppInitializationService.instance.initialize();
  } catch (e) {
    debugPrint('Warning: App initialization had errors: $e');
    // Continue anyway - app can still work with fallback data
  }

  // await AuthService().signOut();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final ThemeService _themeService = ThemeService.instance;
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    // Listen to theme changes
    _themeService.addListener(_onThemeChanged);
    // Set up navigation key for notifications
    NotificationNavigationService.instance.setNavigatorKey(_navigatorKey);
  }

  @override
  void dispose() {
    _themeService.removeListener(_onThemeChanged);
    super.dispose();
  }

  void _onThemeChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'The News',
      debugShowCheckedModeBanner: false,
      navigatorKey: _navigatorKey,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _themeService.themeMode,
      onGenerateRoute: AppRoutes.generateRoute,
      initialRoute: '/',
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final AuthService _authService = AuthService();
  bool _isLoading = true;
  bool _isAuthenticated = false;
  RegisterLoginUserSuccessModel? _userData;

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    try {
      final isAuth = await _authService.isAuthenticated();
      if (!mounted) return;

      if (isAuth) {
        final userData = await _authService.getCurrentUser();
        if (!mounted) return;

        if (userData != null) {
          final userId = userData['id'] ?? '';

          _userData = RegisterLoginUserSuccessModel(
            token: '',
            userId: userId,
            name: userData['name'] ?? '',
            email: userData['email'] ?? '',
            message: 'Welcome back!',
            success: userData['success'] ?? false,
            createdAt: userData['createdAt'] ?? '',
            updatedAt: userData['updatedAt'] ?? '',
            lastLogin: userData['lastLogin'] ?? '',
          );

          // Initialize subscription for this user
          if (userId.isNotEmpty) {
            try {
              await AppInitializationService.instance
                  .initializeSubscriptionForUser(userId);
            } catch (e) {
              debugPrint('Failed to initialize subscription: $e');
            }
          }

          setState(() {
            _isAuthenticated = true;
          });
        }
      }
    } catch (e) {
      if (!mounted) return;
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    //? Navigate to home route (with MainScaffold) if authenticated, otherwise to WelcomePage
    if (_isAuthenticated && _userData != null) {
      // Use Navigator to go to home route which wraps HomePage with MainScaffold
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(
          context,
          AppRoutes.home,
          arguments: _userData,
        );
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return const WelcomePage();
  }
}
