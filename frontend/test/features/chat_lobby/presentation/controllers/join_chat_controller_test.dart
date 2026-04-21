import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/auth/auth_session_provider.dart';
import 'package:frontend/features/auth/domain/entities/auth_session.dart';
import 'package:frontend/features/chat_lobby/chat_lobby_providers.dart';
import 'package:frontend/features/chat_lobby/domain/entities/chat_lobby_failure.dart';
import 'package:frontend/features/chat_lobby/domain/entities/chat_room.dart';
import 'package:frontend/features/chat_lobby/domain/repositories/chat_lobby_repository.dart';
import 'package:frontend/features/chat_lobby/presentation/controllers/join_chat_controller.dart';
import 'package:frontend/features/chat_lobby/presentation/state/chat_lobby_submission_status.dart';

void main() {
  group('JoinChatController', () {
    test('validates invalid invite code before repository call', () async {
      var called = false;
      final container = _buildContainer(
        repository: FakeChatLobbyRepository(
          onJoinChat: ({required userId, required inviteCode}) async {
            called = true;
            return sampleRoom;
          },
        ),
      );
      addTearDown(container.dispose);
      final subscription = container.listen(
        joinChatControllerProvider,
        (previous, next) {},
      );
      addTearDown(subscription.close);

      final controller = container.read(joinChatControllerProvider.notifier);

      await controller.submit(inviteCode: 'abc12x');

      final state = subscription.read();
      expect(state.status, ChatLobbySubmissionStatus.failure);
      expect(state.inviteCodeError, 'Invite code must be 6 Latin letters.');
      expect(called, isFalse);
    });

    test('emits success state when room is joined', () async {
      final container = _buildContainer(
        repository: FakeChatLobbyRepository(
          onJoinChat: ({required userId, required inviteCode}) async {
            expect(userId, 42);
            expect(inviteCode, 'AbCdEf');
            return sampleRoom;
          },
        ),
      );
      addTearDown(container.dispose);
      final subscription = container.listen(
        joinChatControllerProvider,
        (previous, next) {},
      );
      addTearDown(subscription.close);

      final controller = container.read(joinChatControllerProvider.notifier);

      await controller.submit(inviteCode: 'AbCdEf');

      final state = subscription.read();
      expect(state.status, ChatLobbySubmissionStatus.success);
      expect(state.room?.id, 7);
      expect(state.inviteCodeError, isNull);
    });

    test('ignores duplicate submit while join request is loading', () async {
      final completer = Completer<ChatRoom>();
      var calls = 0;
      final container = _buildContainer(
        repository: FakeChatLobbyRepository(
          onJoinChat: ({required userId, required inviteCode}) {
            calls++;
            return completer.future;
          },
        ),
      );
      addTearDown(container.dispose);
      final subscription = container.listen(
        joinChatControllerProvider,
        (previous, next) {},
      );
      addTearDown(subscription.close);

      final controller = container.read(joinChatControllerProvider.notifier);
      final future = controller.submit(inviteCode: 'AbCdEf');

      expect(subscription.read().status, ChatLobbySubmissionStatus.loading);

      await controller.submit(inviteCode: 'abc12x');

      expect(calls, 1);
      expect(subscription.read().status, ChatLobbySubmissionStatus.loading);
      expect(subscription.read().inviteCodeError, isNull);

      completer.complete(sampleRoom);
      await future;

      expect(subscription.read().status, ChatLobbySubmissionStatus.success);
    });

    test('maps room not found to invite code feedback', () async {
      final container = _buildContainer(
        repository: FakeChatLobbyRepository(
          onJoinChat: ({required userId, required inviteCode}) async {
            throw const ChatLobbyFailureException(RoomNotFoundFailure());
          },
        ),
      );
      addTearDown(container.dispose);
      final subscription = container.listen(
        joinChatControllerProvider,
        (previous, next) {},
      );
      addTearDown(subscription.close);

      final controller = container.read(joinChatControllerProvider.notifier);

      await controller.submit(inviteCode: 'AbCdEf');

      final state = subscription.read();
      expect(state.status, ChatLobbySubmissionStatus.failure);
      expect(
        state.inviteCodeError,
        'This code was not found. Check the spelling.',
      );
    });
  });
}

ProviderContainer _buildContainer({required ChatLobbyRepository repository}) {
  return ProviderContainer(
    overrides: [
      authSessionProvider.overrideWith(() => FakeAuthSessionController()),
      chatLobbyRepositoryProvider.overrideWith((ref) => repository),
    ],
  );
}

class FakeAuthSessionController extends AuthSessionController {
  @override
  AuthSession? build() => sampleSession;
}

class FakeChatLobbyRepository implements ChatLobbyRepository {
  FakeChatLobbyRepository({
    this.onCreateChat,
    this.onJoinChat,
  });

  final Future<ChatRoom> Function({
    required int userId,
    required String name,
  })? onCreateChat;
  final Future<ChatRoom> Function({
    required int userId,
    required String inviteCode,
  })? onJoinChat;

  @override
  Future<ChatRoom> createChat({
    required int userId,
    required String name,
  }) {
    return onCreateChat!(userId: userId, name: name);
  }

  @override
  Future<ChatRoom> joinChat({
    required int userId,
    required String inviteCode,
  }) {
    return onJoinChat!(userId: userId, inviteCode: inviteCode);
  }
}

final sampleSession = AuthSession(
  userId: 42,
  username: 'tester',
  tokenType: 'Bearer',
  accessToken: 'token',
  expiresAt: DateTime.utc(2026, 1, 1),
);

const sampleRoom = ChatRoom(
  id: 7,
  name: 'Project Mars',
  inviteCode: 'abcdef',
);
