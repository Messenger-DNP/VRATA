import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/auth/auth_session_provider.dart';
import 'package:frontend/features/auth/domain/entities/auth_session.dart';
import 'package:frontend/features/chat_lobby/chat_lobby_providers.dart';
import 'package:frontend/features/chat_lobby/domain/entities/chat_lobby_failure.dart';
import 'package:frontend/features/chat_lobby/domain/entities/chat_room.dart';
import 'package:frontend/features/chat_lobby/domain/repositories/chat_lobby_repository.dart';
import 'package:frontend/features/chat_lobby/presentation/controllers/create_chat_controller.dart';
import 'package:frontend/features/chat_lobby/presentation/state/chat_lobby_submission_status.dart';

void main() {
  group('CreateChatController', () {
    test('validates empty chat name before repository call', () async {
      var called = false;
      final container = _buildContainer(
        repository: FakeChatLobbyRepository(
          onCreateChat: ({required userId, required name}) async {
            called = true;
            return sampleRoom;
          },
        ),
      );
      addTearDown(container.dispose);
      final subscription = container.listen(
        createChatControllerProvider,
        (previous, next) {},
      );
      addTearDown(subscription.close);

      final controller = container.read(createChatControllerProvider.notifier);

      await controller.submit(name: '');

      final state = subscription.read();
      expect(state.status, ChatLobbySubmissionStatus.failure);
      expect(state.nameError, 'Please enter a chat name.');
      expect(called, isFalse);
    });

    test('emits success state when room is created', () async {
      final container = _buildContainer(
        repository: FakeChatLobbyRepository(
          onCreateChat: ({required userId, required name}) async {
            expect(userId, 42);
            expect(name, 'Project Mars');
            return sampleRoom;
          },
        ),
      );
      addTearDown(container.dispose);
      final subscription = container.listen(
        createChatControllerProvider,
        (previous, next) {},
      );
      addTearDown(subscription.close);

      final controller = container.read(createChatControllerProvider.notifier);

      await controller.submit(name: 'Project Mars');

      final state = subscription.read();
      expect(state.status, ChatLobbySubmissionStatus.success);
      expect(state.room?.id, 7);
      expect(state.nameError, isNull);
    });

    test('emits loading state while create request is in flight', () async {
      final completer = Completer<ChatRoom>();
      final container = _buildContainer(
        repository: FakeChatLobbyRepository(
          onCreateChat: ({required userId, required name}) => completer.future,
        ),
      );
      addTearDown(container.dispose);
      final subscription = container.listen(
        createChatControllerProvider,
        (previous, next) {},
      );
      addTearDown(subscription.close);

      final controller = container.read(createChatControllerProvider.notifier);
      final future = controller.submit(name: 'Project Mars');

      expect(subscription.read().status, ChatLobbySubmissionStatus.loading);

      completer.complete(sampleRoom);
      await future;

      expect(subscription.read().status, ChatLobbySubmissionStatus.success);
    });

    test('ignores duplicate submit while create request is loading', () async {
      final completer = Completer<ChatRoom>();
      var calls = 0;
      final container = _buildContainer(
        repository: FakeChatLobbyRepository(
          onCreateChat: ({required userId, required name}) {
            calls++;
            return completer.future;
          },
        ),
      );
      addTearDown(container.dispose);
      final subscription = container.listen(
        createChatControllerProvider,
        (previous, next) {},
      );
      addTearDown(subscription.close);

      final controller = container.read(createChatControllerProvider.notifier);
      final future = controller.submit(name: 'Project Mars');

      expect(subscription.read().status, ChatLobbySubmissionStatus.loading);

      await controller.submit(name: '');

      expect(calls, 1);
      expect(subscription.read().status, ChatLobbySubmissionStatus.loading);
      expect(subscription.read().nameError, isNull);

      completer.complete(sampleRoom);
      await future;

      expect(subscription.read().status, ChatLobbySubmissionStatus.success);
    });

    test('maps invalid credentials to submission feedback', () async {
      final container = _buildContainer(
        repository: FakeChatLobbyRepository(
          onCreateChat: ({required userId, required name}) async {
            throw const ChatLobbyFailureException(
              InvalidCredentialsChatLobbyFailure(),
            );
          },
        ),
      );
      addTearDown(container.dispose);
      final subscription = container.listen(
        createChatControllerProvider,
        (previous, next) {},
      );
      addTearDown(subscription.close);

      final controller = container.read(createChatControllerProvider.notifier);

      await controller.submit(name: 'Project Mars');

      final state = subscription.read();
      expect(state.status, ChatLobbySubmissionStatus.failure);
      expect(state.submissionError, 'Invalid username or password.');
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
    this.onLeaveChat,
  });

  final Future<ChatRoom> Function({
    required int userId,
    required String name,
  })? onCreateChat;
  final Future<ChatRoom> Function({
    required int userId,
    required String inviteCode,
  })? onJoinChat;
  final Future<void> Function({
    required int userId,
  })? onLeaveChat;

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

  @override
  Future<void> leaveChat({required int userId}) {
    return onLeaveChat?.call(userId: userId) ?? Future.value();
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
