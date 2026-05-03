import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'config/app_theme.dart';
import 'config/router.dart';
import 'providers/auth_provider.dart';
import 'providers/theme_notifier.dart';

class StudyCoreApp extends StatefulWidget {
  const StudyCoreApp({super.key});

  @override
  State<StudyCoreApp> createState() => _StudyCoreAppState();
}

class _StudyCoreAppState extends State<StudyCoreApp> {
  GoRouter? _router;
  bool _routerInitialized = false;

  GoRouter _buildRouter(AuthProvider authProvider) {
    return GoRouter(
      navigatorKey: appNavigatorKey,
      initialLocation: '/splash',
      redirect: (ctx, state) {
        final isAuthenticated = authProvider.isAuthenticated;
        final location = state.uri.toString();

        if (location == '/splash') {
          return null;
        }

        if (!isAuthenticated && location != '/login' && location != '/signup') {
          return '/login';
        }

        if (isAuthenticated && (location == '/login' || location == '/signup')) {
          return '/home';
        }

        return null;
      },
      refreshListenable: authProvider,
      routes: appRoutes,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_routerInitialized) {
      _routerInitialized = true;
      final authProvider = context.read<AuthProvider>();
      _router = _buildRouter(authProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeNotifier = context.watch<ThemeNotifier>();

    if (_router == null) return const SizedBox();

    return MaterialApp.router(
      title: 'StudyCore',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeNotifier.themeMode,
      routerConfig: _router!,
      debugShowCheckedModeBanner: false,
    );
  }
}
