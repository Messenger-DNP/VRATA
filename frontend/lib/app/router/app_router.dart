import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/features/auth/auth_session_provider.dart';
import 'package:frontend/features/auth/domain/entities/auth_session.dart';
import 'package:frontend/features/auth/presentation/login_screen.dart';
import 'package:frontend/features/auth/presentation/register_screen.dart';
import 'package:frontend/features/auth/presentation/welcome_screen.dart';
import 'package:frontend/features/chat_lobby/presentation/lobby_screen.dart';
import 'package:go_router/go_router.dart';

abstract final class AppRoutes {
  static const root = '/';
  static const welcome = '/welcome';
  static const login = '/login';
  static const register = '/register';
  static const lobby = '/lobby';
}

final _routerRefreshProvider = Provider<ValueNotifier<int>>((ref) {
  final notifier = ValueNotifier<int>(0);

  ref.listen<AuthSession?>(authSessionProvider, (previous, next) {
    notifier.value++;
  });

  ref.onDispose(notifier.dispose);
  return notifier;
});

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.welcome,
    refreshListenable: ref.watch(_routerRefreshProvider),
    redirect: (_, state) {
      final currentLocation = state.matchedLocation;
      final isAuthenticated = ref.read(authSessionProvider) != null;
      final isAuthRoute = currentLocation == AppRoutes.welcome ||
          currentLocation == AppRoutes.login ||
          currentLocation == AppRoutes.register;

      if (currentLocation == AppRoutes.root) {
        return isAuthenticated ? AppRoutes.lobby : AppRoutes.welcome;
      }

      if (!isAuthenticated && currentLocation == AppRoutes.lobby) {
        return AppRoutes.welcome;
      }

      if (isAuthenticated && isAuthRoute) {
        return AppRoutes.lobby;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.root,
        redirect: (_, _) => AppRoutes.welcome,
      ),
      GoRoute(
        path: AppRoutes.welcome,
        builder: (_, _) => const WelcomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (_, _) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (_, _) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.lobby,
        builder: (_, _) => const LobbyScreen(),
      ),
    ],
  );
});
