import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'models/app_user.dart';
import 'models/match_post.dart';
import 'navigation/app_routes.dart';
import 'pages/create_match_page.dart';
import 'pages/home_page.dart';
import 'pages/login_page.dart';
import 'pages/profile_setup_page.dart';
import 'pages/register_page.dart';
import 'pages/splash_page.dart';
import 'state/auth_controller.dart';

class SaleFulboApp extends ConsumerWidget {
  const SaleFulboApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<AppUser?> authState = ref.watch(authControllerProvider);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SaleFulbo',
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF0A7C3F),
        useMaterial3: true,
      ),
      initialRoute: AppRoutes.login,
      onGenerateRoute: (RouteSettings settings) {
        final bool isLogged = authState.valueOrNull != null;
        final bool isLoading = authState.isLoading;
        
        switch (settings.name) {
          case AppRoutes.login:
            if (isLoading) {
              return MaterialPageRoute<void>(
                builder: (BuildContext context) => const SplashPage(),
                settings: settings,
              );
            }
            return MaterialPageRoute<void>(
              builder: (BuildContext context) =>
                  isLogged ? const HomePage() : const LoginPage(),
              settings: settings,
            );
          case AppRoutes.register:
            if (isLoading) {
              return MaterialPageRoute<void>(
                builder: (BuildContext context) => const SplashPage(),
                settings: settings,
              );
            }
            return MaterialPageRoute<void>(
              builder: (BuildContext context) =>
                  isLogged ? const HomePage() : const RegisterPage(),
              settings: settings,
            );
          case AppRoutes.home:
            if (isLoading) {
              return MaterialPageRoute<void>(
                builder: (BuildContext context) => const SplashPage(),
                settings: settings,
              );
            }
            return MaterialPageRoute<void>(
              builder: (BuildContext context) =>
                  isLogged ? const HomePage() : const LoginPage(),
              settings: settings,
            );
          case AppRoutes.createMatch:
            final AppUser? creator = settings.arguments as AppUser?;
            return MaterialPageRoute<MatchPost>(
              builder: (BuildContext context) => isLogged && creator != null
                  ? CreateMatchPage(currentUser: creator)
                  : const LoginPage(),
              settings: settings,
            );
          case AppRoutes.profileSetup:
            return MaterialPageRoute<void>(
              builder: (BuildContext context) =>
                  isLogged ? const ProfileSetupPage() : const LoginPage(),
              settings: settings,
            );
          default:
            if (isLoading) {
              return MaterialPageRoute<void>(
                builder: (BuildContext context) => const SplashPage(),
                settings: settings,
              );
            }
            return MaterialPageRoute<void>(
              builder: (BuildContext context) =>
                  isLogged ? const HomePage() : const LoginPage(),
              settings: settings,
            );
        }
      },
    );
  }
}
