import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/auth/auth_session_provider.dart';
import 'package:frontend/features/auth/domain/entities/auth_session.dart';
import 'package:frontend/features/chat_room/chat_room_providers.dart';
import 'package:frontend/features/chat_room/domain/entities/chat_message.dart';
import 'package:frontend/features/chat_room/domain/entities/chat_message_failure.dart';
import 'package:frontend/features/chat_room/domain/entities/chat_messages_observation.dart';
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

    test('sends message with session body and keeps REST send separate',
        () async {
      var loadCalls = 0;
      _SentMessage? sentMessage;
      late StreamController<ChatMessage> liveMessages;
      final repository = FakeChatMessagesRepository(
        onLoadMessages: ({required roomId, required userId}) async {
          loadCalls++;
          return [];
        },
        onObserveMessages: ({required roomId}) {
          liveMessages = StreamController<ChatMessage>();
          return ChatMessagesObservation(
            messages: liveMessages.stream,
            ready: Future<void>.value(),
          );
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
      await _pumpUntil(() => loadCalls == 2);
      final loadCallsBeforeSend = loadCalls;

      final sent = await container
          .read(chatMessagesControllerProvider(7).notifier)
          .sendMessage('  hello  ');

      expect(sent, isTrue);
      expect(sentMessage?.roomId, 7);
      expect(sentMessage?.userId, 42);
      expect(sentMessage?.username, 'tester');
      expect(sentMessage?.content, 'hello');
      expect(loadCalls, loadCallsBeforeSend);
      expect(subscription.read().isSending, isFalse);
      expect(subscription.read().messages, isEmpty);

      liveMessages.add(sampleOwnMessage);
      await pumpEventQueue();

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

    test('merges only new received messages by id', () async {
      var loadCalls = 0;
      final repository = FakeChatMessagesRepository(
        onLoadMessages: ({required roomId, required userId}) async {
          loadCalls++;
          if (loadCalls == 1) {
            return [sampleOwnMessage];
          }

          return [
            sampleOwnMessage,
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

    test('live stream appends messages and ignores duplicate ids', () async {
      late StreamController<ChatMessage> liveMessages;
      var loadCalls = 0;
      final repository = FakeChatMessagesRepository(
        onLoadMessages: ({required roomId, required userId}) async {
          loadCalls++;
          return [sampleOwnMessage];
        },
        onObserveMessages: ({required roomId}) {
          expect(roomId, 7);
          liveMessages = StreamController<ChatMessage>();
          return ChatMessagesObservation(
            messages: liveMessages.stream,
            ready: Future<void>.value(),
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

      await _pumpUntil(() => loadCalls == 2);

      liveMessages
        ..add(sampleOwnMessage)
        ..add(sampleOtherMessage);
      await pumpEventQueue();

      final messages = subscription.read().messages;
      expect(messages, [sampleOwnMessage, sampleOtherMessage]);
    });

    test('ignores duplicate send while send request is pending', () async {
      final sendCompleter = Completer<void>();
      var loadCalls = 0;
      var sendCalls = 0;
      final repository = FakeChatMessagesRepository(
        onLoadMessages: ({required roomId, required userId}) async {
          loadCalls++;
          return [];
        },
        onSendMessage: ({
          required roomId,
          required userId,
          required username,
          required content,
        }) {
          sendCalls++;
          return sendCompleter.future;
        },
      );
      final container = _buildContainer(repository: repository);
      addTearDown(container.dispose);
      final subscription = container.listen(
        chatMessagesControllerProvider(7),
        (previous, next) {},
      );
      addTearDown(subscription.close);

      await _pumpUntil(() => loadCalls == 2);

      final firstSend = container
          .read(chatMessagesControllerProvider(7).notifier)
          .sendMessage('hello');
      await pumpEventQueue();

      expect(sendCalls, 1);
      expect(subscription.read().isSending, isTrue);

      final duplicateSend = await container
          .read(chatMessagesControllerProvider(7).notifier)
          .sendMessage('hello');

      expect(duplicateSend, isFalse);
      expect(sendCalls, 1);

      sendCompleter.complete();

      expect(await firstSend, isTrue);
      expect(subscription.read().isSending, isFalse);
      expect(subscription.read().messages, isEmpty);
    });

    test('live stream stops after dispose', () async {
      var liveCancelled = false;
      final repository = FakeChatMessagesRepository(
        onLoadMessages: ({required roomId, required userId}) async => [],
        onObserveMessages: ({required roomId}) {
          final liveMessages = StreamController<ChatMessage>(
            onCancel: () {
              liveCancelled = true;
            },
          );

          return ChatMessagesObservation(
            messages: liveMessages.stream,
            ready: Future<void>.value(),
          );
        },
      );
      final container = _buildContainer(repository: repository);
      final subscription = container.listen(
        chatMessagesControllerProvider(7),
        (previous, next) {},
      );

      await pumpEventQueue();
      subscription.close();
      container.dispose();

      await pumpEventQueue();
      expect(liveCancelled, isTrue);
    });

    test('maps live stream failures to non-blocking error state', () async {
      late StreamController<ChatMessage> liveMessages;
      final recoveryLoad = Completer<List<ChatMessage>>();
      var loadCalls = 0;
      final repository = FakeChatMessagesRepository(
        onLoadMessages: ({required roomId, required userId}) {
          loadCalls++;
          if (loadCalls < 3) {
            return Future.value([]);
          }

          return recoveryLoad.future;
        },
        onObserveMessages: ({required roomId}) {
          liveMessages = StreamController<ChatMessage>();
          return ChatMessagesObservation(
            messages: liveMessages.stream,
            ready: Future<void>.value(),
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

      await _pumpUntil(() => loadCalls == 2);

      liveMessages.addError(
        const ChatMessageFailureException(
          NetworkChatMessageFailure('Live connection closed.'),
        ),
      );
      await _pumpUntil(() => loadCalls == 3);

      final state = subscription.read();
      expect(state.status, ChatMessagesLoadStatus.ready);
      expect(state.errorMessage, 'Live connection closed.');

      recoveryLoad.complete([]);
      await pumpEventQueue();
      expect(subscription.read().errorMessage, isNull);
    });

    test('starts live stream before first load and catches up after ready',
        () async {
      final firstLoad = Completer<List<ChatMessage>>();
      final liveReady = Completer<void>();
      var loadCalls = 0;
      var observeCalls = 0;
      final repository = FakeChatMessagesRepository(
        onLoadMessages: ({required roomId, required userId}) {
          loadCalls++;
          if (loadCalls == 1) {
            return firstLoad.future;
          }

          return Future.value([sampleOwnMessage, sampleOtherMessage]);
        },
        onObserveMessages: ({required roomId}) {
          observeCalls++;
          return ChatMessagesObservation(
            messages: const Stream.empty(),
            ready: liveReady.future,
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

      expect(observeCalls, 1);
      expect(loadCalls, 1);

      liveReady.complete();
      await pumpEventQueue();
      expect(loadCalls, 1);

      firstLoad.complete([sampleOwnMessage]);
      await _pumpUntil(() => loadCalls == 2);

      final messages = subscription.read().messages;
      expect(messages, [sampleOwnMessage, sampleOtherMessage]);
    });

    test('live stream failure triggers REST catch-up', () async {
      late StreamController<ChatMessage> liveMessages;
      var loadCalls = 0;
      final repository = FakeChatMessagesRepository(
        onLoadMessages: ({required roomId, required userId}) async {
          loadCalls++;
          if (loadCalls < 3) {
            return [sampleOwnMessage];
          }

          return [sampleOwnMessage, sampleOtherMessage];
        },
        onObserveMessages: ({required roomId}) {
          liveMessages = StreamController<ChatMessage>();
          return ChatMessagesObservation(
            messages: liveMessages.stream,
            ready: Future<void>.value(),
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

      await _pumpUntil(() => loadCalls == 2);

      liveMessages.addError(
        const ChatMessageFailureException(
          NetworkChatMessageFailure('Live connection closed.'),
        ),
      );

      await _pumpUntil(() => loadCalls == 3);

      expect(
        subscription.read().messages,
        [sampleOwnMessage, sampleOtherMessage],
      );
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
}) {
  final effectiveSession = session ?? sampleSession;

  return ProviderContainer(
    overrides: [
      authSessionProvider.overrideWith(
        () => FakeAuthSessionController(effectiveSession),
      ),
      chatMessagesRepositoryProvider.overrideWith((ref) => repository),
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
    this.onObserveMessages,
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
  final ChatMessagesObservation Function({required int roomId})?
      onObserveMessages;

  @override
  Future<List<ChatMessage>> loadMessages({
    required int roomId,
    required int userId,
  }) {
    return onLoadMessages(roomId: roomId, userId: userId);
  }

  @override
  ChatMessagesObservation observeMessages({required int roomId}) {
    return onObserveMessages?.call(roomId: roomId) ??
        ChatMessagesObservation(
          messages: const Stream.empty(),
          ready: Future<void>.value(),
        );
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

Future<void> _pumpUntil(bool Function() condition) async {
  for (var attempt = 0; attempt < 20; attempt++) {
    if (condition()) {
      return;
    }

    await pumpEventQueue();
  }

  fail('Condition was not met before the event queue settled.');
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

const sampleOtherMessage = ChatMessage(
  id: 'message-2',
  roomId: 7,
  userId: 99,
  username: 'teammate',
  content: 'hi',
);
