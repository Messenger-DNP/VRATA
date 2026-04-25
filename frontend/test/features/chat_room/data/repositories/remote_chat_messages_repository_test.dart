import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/chat_room/data/datasources/chat_messages_remote_datasource.dart';
import 'package:frontend/features/chat_room/data/datasources/chat_messages_realtime_datasource.dart';
import 'package:frontend/features/chat_room/data/repositories/remote_chat_messages_repository.dart';
import 'package:frontend/features/chat_room/domain/entities/chat_message.dart';
import 'package:frontend/features/chat_room/domain/entities/chat_message_failure.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('RemoteChatMessagesRepository', () {
    test('gets room messages without user id query and maps response',
        () async {
      late Uri capturedUri;

      final repository = _buildRepository(
        MockClient((request) async {
          capturedUri = request.url;

          return http.Response(
            jsonEncode([
              {
                'id': 'message-1',
                'roomId': 7,
                'userId': 42,
                'username': 'tester',
                'content': 'hello',
              },
              {
                'id': 'message-2',
                'roomId': 7,
                'userId': 99,
                'username': 'teammate',
                'content': 'hi',
              },
            ]),
            200,
          );
        }),
      );

      final messages = await repository.loadMessages(roomId: 7);

      expect(
        capturedUri.toString(),
        'http://localhost:8080/api/v1/rooms/7/messages',
      );
      expect(messages, hasLength(2));
      expect(messages.first.id, 'message-1');
      expect(messages.first.content, 'hello');
      expect(messages.last.username, 'teammate');
    });

    test('posts send message request with required body', () async {
      late Uri capturedUri;
      late String capturedBody;

      final repository = _buildRepository(
        MockClient((request) async {
          capturedUri = request.url;
          capturedBody = request.body;

          return http.Response('', 202);
        }),
      );

      await repository.sendMessage(
        roomId: 7,
        userId: 42,
        username: 'tester',
        content: 'hello',
      );

      expect(capturedUri.toString(), 'http://localhost:8080/api/v1/messages');
      expect(
        jsonDecode(capturedBody),
        {
          'roomId': 7,
          'userId': 42,
          'username': 'tester',
          'content': 'hello',
        },
      );
    });

    test('maps validation errors with message', () async {
      final repository = _buildRepository(
        MockClient((request) async {
          return http.Response(
            jsonEncode({
              'code': 'VALIDATION_ERROR',
              'message': 'content is required',
              'timestamp': '2026-04-24T12:00:00Z',
            }),
            400,
          );
        }),
      );

      expect(
        () => repository.sendMessage(
          roomId: 7,
          userId: 42,
          username: 'tester',
          content: '',
        ),
        throwsA(
          isA<ChatMessageFailureException>().having(
            (error) => error.failure,
            'failure',
            isA<ValidationChatMessageFailure>().having(
              (failure) => failure.message,
              'message',
              'content is required',
            ),
          ),
        ),
      );
    });

    test('maps network errors explicitly', () async {
      final repository = _buildRepository(
        MockClient((request) async {
          throw http.ClientException('Connection failed');
        }),
      );

      expect(
        () => repository.loadMessages(roomId: 7),
        throwsA(
          isA<ChatMessageFailureException>().having(
            (error) => error.failure,
            'failure',
            isA<NetworkChatMessageFailure>(),
          ),
        ),
      );
    });

    test('observes realtime messages and maps them to domain', () async {
      final socket = FakeChatMessagesSocket();
      final repository = _buildRepository(
        MockClient((_) async => http.Response('[]', 200)),
        realtimeDatasource: ChatMessagesRealtimeDatasource(
          baseUrl: 'http://localhost:8080',
          connector: (_) => socket,
        ),
      );
      final messages = <ChatMessage>[];
      final observation = repository.observeMessages(roomId: 7);
      final subscription = observation.messages.listen(
        messages.add,
      );

      await _pumpUntil(
        () => socket.sentFrames.any((frame) => frame.startsWith('CONNECT\n')),
      );
      socket.addServerFrame('CONNECTED\nversion:1.2\n\n\x00');
      await _pumpUntil(
        () => socket.sentFrames.any((frame) => frame.startsWith('SUBSCRIBE\n')),
      );
      await observation.ready;
      socket.addServerFrame(
        'MESSAGE\n'
        'destination:/topic/rooms/7/messages\n'
        '\n'
        '{"id":"message-1","roomId":7,"userId":42,'
        '"username":"tester","content":"hello"}'
        '\x00',
      );
      await _pumpUntil(() => messages.length == 1);

      expect(messages, hasLength(1));
      expect(messages.single.id, 'message-1');
      expect(messages.single.content, 'hello');
      await pumpEventQueue();
      await subscription.cancel();
    });

    test('maps realtime connection errors explicitly', () async {
      final socket = FakeChatMessagesSocket();
      final repository = _buildRepository(
        MockClient((_) async => http.Response('[]', 200)),
        realtimeDatasource: ChatMessagesRealtimeDatasource(
          baseUrl: 'http://localhost:8080',
          connector: (_) => socket,
        ),
      );
      final errors = <Object>[];
      final observation = repository.observeMessages(roomId: 7);
      final subscription = observation.messages.listen(
        (_) {},
        onError: errors.add,
      );
      final readyError = expectLater(
        observation.ready,
        throwsA(isA<ChatMessageFailureException>()),
      );

      await _pumpUntil(
        () => socket.sentFrames.any((frame) => frame.startsWith('CONNECT\n')),
      );
      socket.addServerFrame('ERROR\nmessage:backend unavailable\n\n\x00');
      await _pumpUntil(() => errors.isNotEmpty);

      expect(
        errors.single,
        isA<ChatMessageFailureException>().having(
          (error) => error.failure,
          'failure',
          isA<NetworkChatMessageFailure>().having(
            (failure) => failure.message,
            'message',
            'backend unavailable',
          ),
        ),
      );
      await readyError;
      await pumpEventQueue();
      await subscription.cancel();
    });
  });
}

RemoteChatMessagesRepository _buildRepository(
  http.Client client, {
  ChatMessagesRealtimeDatasource? realtimeDatasource,
}) {
  return RemoteChatMessagesRepository(
    ChatMessagesRemoteDatasource(
      client: client,
      baseUrl: 'http://localhost:8080',
    ),
    realtimeDatasource ??
        ChatMessagesRealtimeDatasource(
          baseUrl: 'http://localhost:8080',
          connector: (_) => FakeChatMessagesSocket(),
        ),
  );
}

class FakeChatMessagesSocket implements ChatMessagesSocket {
  FakeChatMessagesSocket() {
    _ready.complete();
  }

  final _serverMessages = StreamController<dynamic>();
  final _ready = Completer<void>();
  final sentFrames = <String>[];
  late final _sink = _RecordingSink(sentFrames);

  @override
  Stream<dynamic> get stream => _serverMessages.stream;

  @override
  StreamSink<dynamic> get sink => _sink;

  @override
  Future<void> get ready => _ready.future;

  void addServerFrame(String frame) {
    _serverMessages.add(frame);
  }
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

class _RecordingSink implements StreamSink<dynamic> {
  _RecordingSink(this.sentFrames);

  final List<String> sentFrames;
  final _done = Completer<void>();

  @override
  void add(dynamic event) {
    sentFrames.add(event as String);
  }

  @override
  void addError(Object error, [StackTrace? stackTrace]) {}

  @override
  Future<void> addStream(Stream<dynamic> stream) async {
    await for (final event in stream) {
      add(event);
    }
  }

  @override
  Future<void> close() async {
    if (!_done.isCompleted) {
      _done.complete();
    }
  }

  @override
  Future<void> get done => _done.future;
}
