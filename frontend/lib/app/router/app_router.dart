import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/features/auth/auth_session_provider.dart';
import 'package:frontend/features/auth/domain/entities/auth_session.dart';
import 'package:frontend/features/auth/presentation/login_screen.dart';
import 'package:frontend/features/auth/presentation/register_screen.dart';
import 'package:frontend/features/auth/presentation/welcome_screen.dart';
import 'package:frontend/features/chat_lobby/domain/entities/chat_room.dart';
import 'package:frontend/features/char_room/presentation/chat_screen.dart';
import 'package:frontend/features/chat_lobby/presentation/create_chat_screen.dart';
import 'package:frontend/features/chat_lobby/presentation/join_chat_screen.dart';
import 'package:frontend/features/chat_lobby/presentation/lobby_screen.dart';
import 'package:go_router/go_router.dart';

abstract final class AppRoutes {
  static const root = '/';
  static const welcome = '/welcome';
  static const login = '/login';
  static const register = '/register';
  static const lobby = '/lobby';
  static const createChat = '/create-chat';
  static const joinChat = '/join-chat';
  static const chat = '/chat/:chatId';

  static String chatPath(int chatId) => '/chat/$chatId';
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
      final path = state.uri.path;
      final isAuthenticated = ref.read(authSessionProvider) != null;
      final isAuthRoute =
          currentLocation == AppRoutes.welcome ||
          currentLocation == AppRoutes.login ||
          currentLocation == AppRoutes.register;
      final isInternalRoute =
          currentLocation == AppRoutes.lobby ||
          currentLocation == AppRoutes.createChat ||
          currentLocation == AppRoutes.joinChat ||
          path.startsWith('/chat/');

      if (currentLocation == AppRoutes.root) {
        return isAuthenticated ? AppRoutes.lobby : AppRoutes.welcome;
      }

      if (!isAuthenticated && isInternalRoute) {
        return AppRoutes.welcome;
      }

      if (isAuthenticated && isAuthRoute) {
        return AppRoutes.lobby;
      }

      return null;
    },
    routes: [
      GoRoute(path: AppRoutes.root, redirect: (_, _) => AppRoutes.welcome),
      GoRoute(
        path: AppRoutes.welcome,
        builder: (_, _) => const WelcomeScreen(),
      ),
      GoRoute(path: AppRoutes.login, builder: (_, _) => const LoginScreen()),
      GoRoute(
        path: AppRoutes.register,
        builder: (_, _) => const RegisterScreen(),
      ),
      GoRoute(path: AppRoutes.lobby, builder: (_, _) => const LobbyScreen()),
      GoRoute(
        path: AppRoutes.createChat,
        builder: (_, _) => const CreateChatScreen(),
      ),
      GoRoute(
        path: AppRoutes.joinChat,
        builder: (_, _) => const JoinChatScreen(),
      ),
      GoRoute(
        path: AppRoutes.chat,
        builder: (_, state) {
          final chatId =
              int.tryParse(state.pathParameters['chatId'] ?? '') ?? 0;
          final room = state.extra is ChatRoom ? state.extra as ChatRoom : null;

          return ChatScreen(chatId: chatId, room: room);
        },
      ),
    ],
  );
});
