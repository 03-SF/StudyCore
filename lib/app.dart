import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'config/app_theme.dart';
import 'config/router.dart';
import 'providers/auth_provider.dart';
import 'providers/theme_notifier.dart';

class StudyCoreApp extends StatelessWidget {
  const StudyCoreApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        final router = GoRouter(
          navigatorKey: appNavigatorKey,
          initialLocation: '/splash',
          redirect: (ctx, state) {
            final isAuthenticated = authProvider.isAuthenticated;
            final location = state.uri.toString();

            if (location == '/splash') {
              return null;
            }

            if (!isAuthenticated &&
                location != '/login' &&
                location != '/signup') {
              return '/login';
            }

            if (isAuthenticated &&
                (location == '/login' || location == '/signup')) {
              return '/home';
            }

            return null;
          },
          refreshListenable: authProvider,
          routes: appRoutes,
        );

        final themeNotifier = context.watch<ThemeNotifier>();

        return MaterialApp.router(
          title: 'StudyCore',
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: themeNotifier.themeMode,
          routerConfig: router,
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}
