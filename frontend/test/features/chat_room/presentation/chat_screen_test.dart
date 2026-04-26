import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/app/router/app_router.dart';
import 'package:frontend/app/theme/app_theme.dart';
import 'package:frontend/features/auth/auth_session_provider.dart';
import 'package:frontend/features/auth/domain/entities/auth_session.dart';
import 'package:frontend/features/chat_lobby/domain/entities/chat_room.dart';
import 'package:frontend/features/chat_room/chat_room_providers.dart';
import 'package:frontend/features/chat_room/domain/entities/chat_message.dart';
import 'package:frontend/features/chat_room/domain/entities/chat_messages_observation.dart';
import 'package:frontend/features/chat_room/domain/repositories/chat_messages_repository.dart';
import 'package:frontend/features/chat_room/presentation/chat_screen.dart';
import 'package:go_router/go_router.dart';

void main() {
  group('ChatScreen leave room confirmation', () {
    testWidgets('opens and cancels the confirmation dialog', (tester) async {
      final router = _buildRouter();
      addTearDown(router.dispose);

      await _pumpChatScreen(tester, router);

      await tester.tap(find.widgetWithText(TextButton, 'Leave room'));
      await tester.pumpAndSettle();

      expect(find.text('Leave room?'), findsOneWidget);
      expect(find.text(_leaveRoomWarning), findsOneWidget);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('Leave room?'), findsNothing);
      expect(find.text('Project Mars'), findsWidgets);
      expect(find.text('Lobby destination'), findsNothing);
    });

    testWidgets('confirming leaves the chat room', (tester) async {
      final router = _buildRouter();
      addTearDown(router.dispose);

      await _pumpChatScreen(tester, router);

      await tester.tap(find.widgetWithText(TextButton, 'Leave room'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Leave'));
      await tester.pumpAndSettle();

      expect(find.text('Lobby destination'), findsOneWidget);
      expect(find.text('Project Mars'), findsNothing);
    });
  });
}

Future<void> _pumpChatScreen(WidgetTester tester, GoRouter router) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authSessionProvider.overrideWith(() => _FakeAuthSessionController()),
        chatMessagesRepositoryProvider.overrideWith(
          (_) => _FakeChatMessagesRepository(),
        ),
      ],
      child: MaterialApp.router(
        theme: AppTheme.light(),
        routerConfig: router,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

GoRouter _buildRouter() {
  return GoRouter(
    initialLocation: AppRoutes.chatPath(_room.id),
    routes: [
      GoRoute(
        path: AppRoutes.lobby,
        builder: (_, _) => const Scaffold(body: Text('Lobby destination')),
      ),
      GoRoute(
        path: AppRoutes.chat,
        builder: (_, _) => const ChatScreen(chatId: 7, room: _room),
      ),
    ],
  );
}

class _FakeAuthSessionController extends AuthSessionController {
  @override
  AuthSession? build() {
    return AuthSession(
      userId: 42,
      username: 'tester',
      tokenType: 'Bearer',
      accessToken: 'token',
      expiresAt: DateTime.utc(2026, 1, 1),
    );
  }
}

class _FakeChatMessagesRepository implements ChatMessagesRepository {
  @override
  Future<List<ChatMessage>> loadMessages({required int roomId}) async {
    return const [];
  }

  @override
  ChatMessagesObservation observeMessages({required int roomId}) {
    return ChatMessagesObservation(
      messages: const Stream<ChatMessage>.empty(),
      ready: Future<void>.value(),
    );
  }

  @override
  Future<void> sendMessage({
    required int roomId,
    required int userId,
    required String username,
    required String content,
  }) async {}
}

const _room = ChatRoom(id: 7, name: 'Project Mars', inviteCode: 'abcdef');

const _leaveRoomWarning =
    'If you leave this room, you will be able to join it again only by invite code. Make sure you saved the room invite code.';
