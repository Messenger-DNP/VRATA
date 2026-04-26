import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/chat_room/data/datasources/chat_messages_realtime_datasource.dart';

void main() {
  group('ChatMessagesRealtimeDatasource', () {
    test('connects to STOMP endpoint and subscribes after CONNECTED', () async {
      late Uri capturedUri;
      final socket = FakeChatMessagesSocket();
      final datasource = ChatMessagesRealtimeDatasource(
        baseUrl: 'http://localhost:8080',
        connector: (uri) {
          capturedUri = uri;
          return socket;
        },
      );
      final messages = <String>[];
      final observation = datasource.observeRoomMessages(roomId: 7);
      var isReady = false;
      final ready = observation.ready.then((_) {
        isReady = true;
      });
      final subscription = observation.messages.listen(
        (message) => messages.add(message.content),
      );
      addTearDown(subscription.cancel);

      await pumpEventQueue();

      expect(capturedUri.toString(), 'ws://localhost:8080/ws-stomp');
      expect(socket.sentFrames, hasLength(1));
      expect(socket.sentFrames.single, startsWith('CONNECT\n'));
      expect(isReady, isFalse);

      socket.addServerFrame('CONNECTED\nversion:1.2\n\n\x00');
      await pumpEventQueue();
      await ready;

      expect(socket.sentFrames, hasLength(2));
      expect(socket.sentFrames.last, startsWith('SUBSCRIBE\n'));
      expect(isReady, isTrue);
      expect(
        socket.sentFrames.last,
        contains('destination:/topic/rooms/7/messages\n'),
      );

      socket.addServerFrame(
        'MESSAGE\n'
        'destination:/topic/rooms/7/messages\n'
        '\n'
        '{"id":"message-1","roomId":7,"userId":42,'
        '"username":"tester","content":"hello"}'
        '\x00',
      );
      await pumpEventQueue();

      expect(messages, ['hello']);
    });

    test('unsubscribes and disconnects when cancelled', () async {
      final socket = FakeChatMessagesSocket();
      final datasource = ChatMessagesRealtimeDatasource(
        baseUrl: 'http://localhost:8080',
        connector: (_) => socket,
      );
      final observation = datasource.observeRoomMessages(roomId: 7);
      final subscription = observation.messages.listen(
        (_) {},
      );

      await pumpEventQueue();
      socket.addServerFrame('CONNECTED\nversion:1.2\n\n\x00');
      await pumpEventQueue();

      await subscription.cancel();

      expect(
        socket.sentFrames,
        contains(startsWith('UNSUBSCRIBE\n')),
      );
      expect(
        socket.sentFrames,
        contains(startsWith('DISCONNECT\n')),
      );
      expect(socket.isClosed, isTrue);
    });

    test('emits a graceful error for STOMP ERROR frames', () async {
      final socket = FakeChatMessagesSocket();
      final datasource = ChatMessagesRealtimeDatasource(
        baseUrl: 'http://localhost:8080',
        connector: (_) => socket,
      );
      final errors = <Object>[];
      final observation = datasource.observeRoomMessages(roomId: 7);
      final readyError = expectLater(
        observation.ready,
        throwsA(isA<ChatMessagesRealtimeException>()),
      );
      final subscription = observation.messages.listen(
        (_) {},
        onError: errors.add,
      );
      addTearDown(subscription.cancel);

      await pumpEventQueue();
      socket.addServerFrame('ERROR\nmessage:backend unavailable\n\n\x00');
      await pumpEventQueue();

      expect(
        errors.single,
        isA<ChatMessagesRealtimeException>().having(
          (error) => error.message,
          'message',
          'backend unavailable',
        ),
      );
      await readyError;
    });
  });
}

class FakeChatMessagesSocket implements ChatMessagesSocket {
  FakeChatMessagesSocket() {
    _ready.complete();
  }

  final _serverMessages = StreamController<dynamic>();
  final _ready = Completer<void>();
  final sentFrames = <String>[];
  late final _sink = _RecordingSink(sentFrames);

  bool get isClosed => _sink.isClosed;

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

class _RecordingSink implements StreamSink<dynamic> {
  _RecordingSink(this.sentFrames);

  final List<String> sentFrames;
  final _done = Completer<void>();
  var isClosed = false;

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
    isClosed = true;
    if (!_done.isCompleted) {
      _done.complete();
    }
  }

  @override
  Future<void> get done => _done.future;
}
