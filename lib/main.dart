import 'package:flutter/material.dart';

import 'package:civic_voice/core/theme/app_theme.dart';
import 'package:civic_voice/features/authentication/screens/forgot_password_screen.dart';
import 'package:civic_voice/features/authentication/screens/login_screen.dart';
import 'package:civic_voice/features/authentication/screens/registration_screen.dart';
import 'package:civic_voice/features/authentication/screens/splash_screen.dart';
import 'package:civic_voice/features/authentication/screens/welcome_screen.dart';

void main() {
  runApp(const CivicVoiceApp());
}

class CivicVoiceApp extends StatelessWidget {
  const CivicVoiceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CivicVoice',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      initialRoute: AppRoutes.splash,
      routes: {
        AppRoutes.splash: (context) => const SplashFlowScreen(),

        AppRoutes.welcome: (context) {
          return WelcomeScreen(
            state: WelcomeViewState.loading,
            onLogin: () {
              Navigator.of(context).pushNamed(AppRoutes.login);
            },
            onRegister: () {
              Navigator.of(context).pushNamed(AppRoutes.registration);
            },
          );
        },

        AppRoutes.login: (context) {
          return LoginScreen(
            state: LoginViewState.ready,
            onBack: () {
              Navigator.of(context).maybePop();
            },
            onSignIn: () {
              // Firebase login will be connected later.
            },
            onForgotPassword: () {
              Navigator.of(context).pushNamed(AppRoutes.forgotPassword);
            },
            onRegister: () {
              Navigator.of(
                context,
              ).pushReplacementNamed(AppRoutes.registration);
            },
          );
        },

        AppRoutes.registration: (context) {
          return RegistrationScreen(
            state: RegistrationViewState.ready,
            onBack: () {
              Navigator.of(context).maybePop();
            },
            onCreateAccount: () {
              // Firebase registration will be connected later.
            },
            onLogin: () {
              Navigator.of(context).pushReplacementNamed(AppRoutes.login);
            },
          );
        },

        AppRoutes.forgotPassword: (context) {
          return ForgotPasswordScreen(
            state: ForgotPasswordViewState.ready,
            onBack: () {
              Navigator.of(context).maybePop();
            },
            onSendResetLink: (emailAddress) {
              // Firebase password reset will be connected later.
            },
            onBackToLogin: () {
              Navigator.of(context).maybePop();
            },
          );
        },
      },
    );
  }
}

class SplashFlowScreen extends StatefulWidget {
  const SplashFlowScreen({super.key});

  @override
  State<SplashFlowScreen> createState() => _SplashFlowScreenState();
}

class _SplashFlowScreenState extends State<SplashFlowScreen> {
  @override
  void initState() {
    super.initState();

    Future<void>.delayed(const Duration(seconds: 2), () {
      if (!mounted) {
        return;
      }

      Navigator.of(context).pushReplacementNamed(AppRoutes.welcome);
    });
  }

  @override
  Widget build(BuildContext context) {
    return const SplashScreen(state: SplashViewState.loading);
  }
}

abstract final class AppRoutes {
  static const splash = '/';
  static const welcome = '/welcome';
  static const login = '/login';
  static const registration = '/registration';
  static const forgotPassword = '/forgot-password';
}
