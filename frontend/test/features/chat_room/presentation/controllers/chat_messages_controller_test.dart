import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/auth/auth_session_provider.dart';
import 'package:frontend/features/auth/domain/entities/auth_session.dart';
import 'package:frontend/features/chat_room/chat_room_providers.dart';
import 'package:frontend/features/chat_room/domain/entities/chat_message.dart';
import 'package:frontend/features/chat_room/domain/entities/chat_message_failure.dart';
import 'package:frontend/features/chat_room/domain/repositories/chat_messages_repository.dart';
import 'package:frontend/features/chat_room/presentation/controllers/chat_messages_controller.dart';
import 'package:frontend/features/chat_room/presentation/state/chat_messages_state.dart';

void main() {
  group('ChatMessagesController', () {
    test('loads messages when provider opens', () async {
      final repository = FakeChatMessagesRepository(
        onLoadMessages: ({required roomId, required userId}) async {
          expect(roomId, 7);
          expect(userId, 42);
          return [sampleOwnMessage];
        },
      );
      final container = _buildContainer(repository: repository);
      addTearDown(container.dispose);
      final subscription = container.listen(
        chatMessagesControllerProvider(7),
        (previous, next) {},
      );
      addTearDown(subscription.close);

      await pumpEventQueue();

      final state = subscription.read();
      expect(state.status, ChatMessagesLoadStatus.ready);
      expect(state.messages, hasLength(1));
      expect(state.messages.single.content, 'hello');
    });

    test('sends message with session body and refreshes messages', () async {
      var loadCalls = 0;
      _SentMessage? sentMessage;
      final repository = FakeChatMessagesRepository(
        onLoadMessages: ({required roomId, required userId}) async {
          loadCalls++;
          return loadCalls == 1 ? [] : [sampleOwnMessage];
        },
        onSendMessage: ({
          required roomId,
          required userId,
          required username,
          required content,
        }) async {
          sentMessage = _SentMessage(
            roomId: roomId,
            userId: userId,
            username: username,
            content: content,
          );
        },
      );
      final container = _buildContainer(repository: repository);
      addTearDown(container.dispose);
      final subscription = container.listen(
        chatMessagesControllerProvider(7),
        (previous, next) {},
      );
      addTearDown(subscription.close);
      await pumpEventQueue();

      final sent = await container
          .read(chatMessagesControllerProvider(7).notifier)
          .sendMessage('  hello  ');

      expect(sent, isTrue);
      expect(sentMessage?.roomId, 7);
      expect(sentMessage?.userId, 42);
      expect(sentMessage?.username, 'tester');
      expect(sentMessage?.content, 'hello');
      expect(loadCalls, 2);
      expect(subscription.read().isSending, isFalse);
      expect(subscription.read().messages.single.content, 'hello');
    });

    test('validates empty content before send request', () async {
      var sendCalls = 0;
      final repository = FakeChatMessagesRepository(
        onLoadMessages: ({required roomId, required userId}) async => [],
        onSendMessage: ({
          required roomId,
          required userId,
          required username,
          required content,
        }) async {
          sendCalls++;
        },
      );
      final container = _buildContainer(repository: repository);
      addTearDown(container.dispose);
      final subscription = container.listen(
        chatMessagesControllerProvider(7),
        (previous, next) {},
      );
      addTearDown(subscription.close);
      await pumpEventQueue();

      final sent = await container
          .read(chatMessagesControllerProvider(7).notifier)
          .sendMessage('   ');

      expect(sent, isFalse);
      expect(sendCalls, 0);
      expect(subscription.read().sendErrorMessage, 'Please enter a message.');
    });

    test('merges only new received messages without obvious duplicates',
        () async {
      var loadCalls = 0;
      final repository = FakeChatMessagesRepository(
        onLoadMessages: ({required roomId, required userId}) async {
          loadCalls++;
          if (loadCalls == 1) {
            return [sampleOwnMessage];
          }

          return [
            sampleOwnMessageWithDifferentId,
            sampleOtherMessage,
          ];
        },
      );
      final container = _buildContainer(repository: repository);
      addTearDown(container.dispose);
      final subscription = container.listen(
        chatMessagesControllerProvider(7),
        (previous, next) {},
      );
      addTearDown(subscription.close);
      await pumpEventQueue();

      await container
          .read(chatMessagesControllerProvider(7).notifier)
          .refreshMessages();

      final messages = subscription.read().messages;
      expect(messages, hasLength(2));
      expect(messages.first.id, sampleOwnMessage.id);
      expect(messages.last.id, sampleOtherMessage.id);
    });

    test('does not overlap message refresh requests', () async {
      final firstLoad = Completer<List<ChatMessage>>();
      var loadCalls = 0;
      final repository = FakeChatMessagesRepository(
        onLoadMessages: ({required roomId, required userId}) {
          loadCalls++;
          return firstLoad.future;
        },
      );
      final container = _buildContainer(repository: repository);
      addTearDown(container.dispose);
      final subscription = container.listen(
        chatMessagesControllerProvider(7),
        (previous, next) {},
      );
      addTearDown(subscription.close);
      await pumpEventQueue();

      final refresh = container
          .read(chatMessagesControllerProvider(7).notifier)
          .refreshMessages();

      await pumpEventQueue();
      expect(loadCalls, 1);

      firstLoad.complete([]);
      await refresh;

      expect(subscription.read().status, ChatMessagesLoadStatus.ready);
    });

    test('send waits for active poll then starts a fresh refresh', () async {
      final pollingLoad = Completer<List<ChatMessage>>();
      final sendRefreshLoad = Completer<List<ChatMessage>>();
      var loadCalls = 0;
      var sendCalls = 0;
      var activeLoads = 0;
      var maxActiveLoads = 0;
      final repository = FakeChatMessagesRepository(
        onLoadMessages: ({required roomId, required userId}) {
          loadCalls++;
          activeLoads++;
          if (activeLoads > maxActiveLoads) {
            maxActiveLoads = activeLoads;
          }

          late final Future<List<ChatMessage>> result;
          if (loadCalls == 2) {
            result = pollingLoad.future;
          } else if (loadCalls == 3) {
            result = sendRefreshLoad.future;
          } else {
            result = Future.value([]);
          }

          return result.whenComplete(() {
            activeLoads--;
          });
        },
        onSendMessage: ({
          required roomId,
          required userId,
          required username,
          required content,
        }) async {
          sendCalls++;
        },
      );
      final container = _buildContainer(
        repository: repository,
        pollingInterval: const Duration(milliseconds: 10),
      );
      final subscription = container.listen(
        chatMessagesControllerProvider(7),
        (previous, next) {},
      );

      await pumpEventQueue();
      expect(loadCalls, 1);

      await Future<void>.delayed(const Duration(milliseconds: 15));
      expect(loadCalls, 2);

      final send = container
          .read(chatMessagesControllerProvider(7).notifier)
          .sendMessage('hello');
      await pumpEventQueue();

      expect(sendCalls, 1);
      expect(loadCalls, 2);

      pollingLoad.complete([]);
      await pumpEventQueue();

      expect(loadCalls, 3);
      expect(maxActiveLoads, 1);

      sendRefreshLoad.complete([sampleOwnMessage]);
      expect(await send, isTrue);
      expect(subscription.read().messages, [sampleOwnMessage]);

      subscription.close();
      container.dispose();
    });

    test('ignores duplicate send while post-send refresh is pending', () async {
      final sendRefreshLoad = Completer<List<ChatMessage>>();
      var loadCalls = 0;
      var sendCalls = 0;
      final repository = FakeChatMessagesRepository(
        onLoadMessages: ({required roomId, required userId}) {
          loadCalls++;
          if (loadCalls == 2) {
            return sendRefreshLoad.future;
          }

          return Future.value([]);
        },
        onSendMessage: ({
          required roomId,
          required userId,
          required username,
          required content,
        }) async {
          sendCalls++;
        },
      );
      final container = _buildContainer(repository: repository);
      addTearDown(container.dispose);
      final subscription = container.listen(
        chatMessagesControllerProvider(7),
        (previous, next) {},
      );
      addTearDown(subscription.close);

      await pumpEventQueue();
      expect(loadCalls, 1);

      final firstSend = container
          .read(chatMessagesControllerProvider(7).notifier)
          .sendMessage('hello');
      await pumpEventQueue();

      expect(sendCalls, 1);
      expect(loadCalls, 2);
      expect(subscription.read().isSending, isTrue);

      final duplicateSend = await container
          .read(chatMessagesControllerProvider(7).notifier)
          .sendMessage('hello');

      expect(duplicateSend, isFalse);
      expect(sendCalls, 1);

      sendRefreshLoad.complete([sampleOwnMessage]);

      expect(await firstSend, isTrue);
      expect(subscription.read().isSending, isFalse);
      expect(subscription.read().messages, [sampleOwnMessage]);
    });

    test('polling does not overlap and stops after dispose', () async {
      final pollingLoad = Completer<List<ChatMessage>>();
      var loadCalls = 0;
      final repository = FakeChatMessagesRepository(
        onLoadMessages: ({required roomId, required userId}) {
          loadCalls++;
          if (loadCalls == 2) {
            return pollingLoad.future;
          }

          return Future.value([]);
        },
      );
      final container = _buildContainer(
        repository: repository,
        pollingInterval: const Duration(milliseconds: 10),
      );
      final subscription = container.listen(
        chatMessagesControllerProvider(7),
        (previous, next) {},
      );

      await pumpEventQueue();
      expect(loadCalls, 1);

      await Future<void>.delayed(const Duration(milliseconds: 15));
      expect(loadCalls, 2);

      await Future<void>.delayed(const Duration(milliseconds: 30));
      expect(loadCalls, 2);

      pollingLoad.complete([]);
      await pumpEventQueue();
      subscription.close();
      container.dispose();

      final callsAfterDispose = loadCalls;
      await Future<void>.delayed(const Duration(milliseconds: 30));
      expect(loadCalls, callsAfterDispose);
    });

    test('maps repository load failures to initial error state', () async {
      final repository = FakeChatMessagesRepository(
        onLoadMessages: ({required roomId, required userId}) async {
          throw const ChatMessageFailureException(
            RoomNotFoundChatMessageFailure(),
          );
        },
      );
      final container = _buildContainer(repository: repository);
      addTearDown(container.dispose);
      final subscription = container.listen(
        chatMessagesControllerProvider(7),
        (previous, next) {},
      );
      addTearDown(subscription.close);

      await pumpEventQueue();

      final state = subscription.read();
      expect(state.status, ChatMessagesLoadStatus.failure);
      expect(state.errorMessage, 'This chat room was not found.');
    });
  });
}

ProviderContainer _buildContainer({
  required ChatMessagesRepository repository,
  AuthSession? session,
  Duration? pollingInterval,
}) {
  final effectiveSession = session ?? sampleSession;

  return ProviderContainer(
    overrides: [
      authSessionProvider.overrideWith(
        () => FakeAuthSessionController(effectiveSession),
      ),
      chatMessagesRepositoryProvider.overrideWith((ref) => repository),
      if (pollingInterval != null)
        chatMessagesPollingIntervalProvider.overrideWithValue(pollingInterval),
    ],
  );
}

class FakeAuthSessionController extends AuthSessionController {
  FakeAuthSessionController(this._session);

  final AuthSession? _session;

  @override
  AuthSession? build() => _session;
}

class FakeChatMessagesRepository implements ChatMessagesRepository {
  FakeChatMessagesRepository({
    required this.onLoadMessages,
    this.onSendMessage,
  });

  final Future<List<ChatMessage>> Function({
    required int roomId,
    required int userId,
  }) onLoadMessages;
  final Future<void> Function({
    required int roomId,
    required int userId,
    required String username,
    required String content,
  })? onSendMessage;

  @override
  Future<List<ChatMessage>> loadMessages({
    required int roomId,
    required int userId,
  }) {
    return onLoadMessages(roomId: roomId, userId: userId);
  }

  @override
  Future<void> sendMessage({
    required int roomId,
    required int userId,
    required String username,
    required String content,
  }) {
    final callback = onSendMessage;
    if (callback == null) {
      throw StateError('onSendMessage was not configured.');
    }

    return callback(
      roomId: roomId,
      userId: userId,
      username: username,
      content: content,
    );
  }
}

class _SentMessage {
  const _SentMessage({
    required this.roomId,
    required this.userId,
    required this.username,
    required this.content,
  });

  final int roomId;
  final int userId;
  final String username;
  final String content;
}

final sampleSession = AuthSession(
  userId: 42,
  username: 'tester',
  tokenType: 'Bearer',
  accessToken: 'token',
  expiresAt: DateTime.utc(2026, 1, 1),
);

const sampleOwnMessage = ChatMessage(
  id: 'message-1',
  roomId: 7,
  userId: 42,
  username: 'tester',
  content: 'hello',
);

const sampleOwnMessageWithDifferentId = ChatMessage(
  id: 'message-1-reissued',
  roomId: 7,
  userId: 42,
  username: 'tester',
  content: 'hello',
);

const sampleOtherMessage = ChatMessage(
  id: 'message-2',
  roomId: 7,
  userId: 99,
  username: 'teammate',
  content: 'hi',
);
