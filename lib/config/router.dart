import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../screens/auth/splash_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/signup_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/deck/deck_detail_screen.dart';
import '../screens/deck/create_edit_deck_screen.dart';
import '../screens/deck/add_edit_card_screen.dart';
import '../screens/deck/ai_generate_screen.dart';
import '../screens/study/flashcard_study_screen.dart';
import '../screens/study/quiz_screen.dart';
import '../screens/study/session_results_screen.dart';
import '../screens/progress/progress_screen.dart';
import '../screens/groups/groups_screen.dart';
import '../screens/groups/create_group_screen.dart';
import '../screens/groups/group_detail_screen.dart';
import '../screens/groups/group_chat_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/profile/settings_screen.dart';

final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final List<RouteBase> appRoutes = [
  GoRoute(
    path: '/splash',
    builder: (context, state) => const SplashScreen(),
  ),
  GoRoute(
    path: '/login',
    builder: (context, state) => const LoginScreen(),
  ),
  GoRoute(
    path: '/signup',
    builder: (context, state) => const SignupScreen(),
  ),
  ShellRoute(
    navigatorKey: _shellNavigatorKey,
    builder: (context, state, child) =>
        ScaffoldShell(child: child, state: state),
    routes: [
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeScreen(),
        routes: [
          GoRoute(
            path: 'deck/create',
            parentNavigatorKey: appNavigatorKey,
            builder: (context, state) =>
                const CreateEditDeckScreen(deck: null),
          ),
          GoRoute(
            path: 'deck/:deckId',
            parentNavigatorKey: appNavigatorKey,
            builder: (context, state) =>
                DeckDetailScreen(deckId: state.pathParameters['deckId']!),
            routes: [
              GoRoute(
                path: 'edit',
                parentNavigatorKey: appNavigatorKey,
                builder: (context, state) => CreateEditDeckScreen(
                  deckId: state.pathParameters['deckId'],
                  deck: null,
                ),
              ),
              GoRoute(
                path: 'card/new',
                parentNavigatorKey: appNavigatorKey,
                builder: (context, state) => AddEditCardScreen(
                  deckId: state.pathParameters['deckId']!,
                  card: null,
                ),
              ),
              GoRoute(
                path: 'card/:cardId',
                parentNavigatorKey: appNavigatorKey,
                builder: (context, state) => AddEditCardScreen(
                  deckId: state.pathParameters['deckId']!,
                  cardId: state.pathParameters['cardId'],
                  card: null,
                ),
              ),
              GoRoute(
                path: 'generate',
                parentNavigatorKey: appNavigatorKey,
                builder: (context, state) => AiGenerateScreen(
                  deckId: state.pathParameters['deckId']!,
                ),
              ),
            ],
          ),
          GoRoute(
            path: 'study/:deckId/flashcard',
            parentNavigatorKey: appNavigatorKey,
            builder: (context, state) => FlashcardStudyScreen(
              deckId: state.pathParameters['deckId']!,
            ),
          ),
          GoRoute(
            path: 'study/:deckId/quiz',
            parentNavigatorKey: appNavigatorKey,
            builder: (context, state) => QuizScreen(
              deckId: state.pathParameters['deckId']!,
            ),
          ),
          GoRoute(
            path: 'study/:deckId/results',
            parentNavigatorKey: appNavigatorKey,
            builder: (context, state) => SessionResultsScreen(
              deckId: state.pathParameters['deckId']!,
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/groups',
        builder: (context, state) => const GroupsScreen(),
        routes: [
          GoRoute(
            path: 'create',
            parentNavigatorKey: appNavigatorKey,
            builder: (context, state) => const CreateGroupScreen(),
          ),
          GoRoute(
            path: ':groupId',
            parentNavigatorKey: appNavigatorKey,
            builder: (context, state) => GroupDetailScreen(
              groupId: state.pathParameters['groupId']!,
            ),
            routes: [
              GoRoute(
                path: 'chat',
                parentNavigatorKey: appNavigatorKey,
                builder: (context, state) => GroupChatScreen(
                  groupId: state.pathParameters['groupId']!,
                ),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/progress',
        builder: (context, state) => const ProgressScreen(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
    ],
  ),
  GoRoute(
    path: '/settings',
    builder: (context, state) => const SettingsScreen(),
  ),
];

class ScaffoldShell extends StatelessWidget {
  final Widget child;
  final GoRouterState state;

  const ScaffoldShell({super.key, required this.child, required this.state});

  int _selectedIndex(String location) {
    if (location.startsWith('/home')) return 0;
    if (location.startsWith('/groups')) return 1;
    if (location.startsWith('/progress')) return 2;
    if (location.startsWith('/profile')) return 3;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final location = state.uri.toString();
    final idx = _selectedIndex(location);

    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: idx,
        onTap: (i) {
          switch (i) {
            case 0:
              context.go('/home');
            case 1:
              context.go('/groups');
            case 2:
              context.go('/progress');
            case 3:
              context.go('/profile');
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.menu_book_outlined),
            activeIcon: Icon(Icons.menu_book),
            label: 'Study',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_outline),
            activeIcon: Icon(Icons.people),
            label: 'Groups',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart_outlined),
            activeIcon: Icon(Icons.bar_chart),
            label: 'Progress',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
