import 'dart:async';
import 'dart:convert';

import 'package:frontend/features/chat_room/data/dto/message_response_dto.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

typedef ChatMessagesSocketConnector = ChatMessagesSocket Function(Uri uri);

abstract interface class ChatMessagesSocket {
  Stream<dynamic> get stream;

  StreamSink<dynamic> get sink;

  Future<void> get ready;
}

class ChatMessagesRealtimeException implements Exception {
  const ChatMessagesRealtimeException({
    required this.message,
    this.isNetworkError = false,
  });

  final String message;
  final bool isNetworkError;
}

class ChatMessagesRealtimeObservation {
  const ChatMessagesRealtimeObservation({
    required this.messages,
    required this.ready,
  });

  final Stream<MessageResponseDto> messages;
  final Future<void> ready;
}

class ChatMessagesRealtimeDatasource {
  const ChatMessagesRealtimeDatasource({
    required String baseUrl,
    ChatMessagesSocketConnector connector = _connectWebSocket,
    this.timeout = const Duration(seconds: 10),
  })  : _baseUrl = baseUrl,
        _connector = connector;

  final String _baseUrl;
  final ChatMessagesSocketConnector _connector;
  final Duration timeout;

  ChatMessagesRealtimeObservation observeRoomMessages({required int roomId}) {
    final controller = StreamController<MessageResponseDto>();
    final ready = Completer<void>();
    final parser = _StompFrameParser();
    final subscriptionId = 'room-$roomId-messages';

    ChatMessagesSocket? socket;
    StreamSubscription<dynamic>? socketSubscription;
    Timer? connectedTimer;
    var isCancelled = false;
    var didSubscribe = false;

    void addError(ChatMessagesRealtimeException exception) {
      if (isCancelled || controller.isClosed) {
        return;
      }

      if (!ready.isCompleted) {
        ready.completeError(exception);
      }
      controller.addError(exception);
    }

    void completeReadyError(ChatMessagesRealtimeException exception) {
      if (!ready.isCompleted) {
        ready.completeError(exception);
      }
    }

    void sendFrame(String command, Map<String, String> headers) {
      socket?.sink.add(_encodeFrame(command, headers));
    }

    Future<void> disconnect() async {
      connectedTimer?.cancel();

      if (didSubscribe) {
        try {
          sendFrame('UNSUBSCRIBE', {'id': subscriptionId});
          sendFrame('DISCONNECT', {'receipt': 'disconnect-$subscriptionId'});
        } catch (_) {
          // The socket may already be closed by the remote endpoint.
        }
      }

      await socketSubscription?.cancel();

      try {
        await socket?.sink.close();
      } catch (_) {
        // Closing an already closed socket should not escape disposal.
      }
    }

    void handleFrame(_StompFrame frame) {
      switch (frame.command) {
        case 'CONNECTED':
          connectedTimer?.cancel();
          sendFrame('SUBSCRIBE', {
            'id': subscriptionId,
            'destination': '/topic/rooms/$roomId/messages',
            'ack': 'auto',
          });
          didSubscribe = true;
          if (!ready.isCompleted) {
            ready.complete();
          }
          break;
        case 'MESSAGE':
          try {
            final decoded = jsonDecode(frame.body);
            if (decoded is Map<String, dynamic>) {
              controller.add(MessageResponseDto.fromJson(decoded));
              return;
            }

            if (decoded is Map) {
              controller.add(
                MessageResponseDto.fromJson(decoded.cast<String, dynamic>()),
              );
              return;
            }

            throw const FormatException('Expected a JSON object.');
          } on FormatException {
            addError(
              const ChatMessagesRealtimeException(
                message: 'Received an invalid live message.',
              ),
            );
          }
          break;
        case 'ERROR':
          addError(
            ChatMessagesRealtimeException(
              message:
                  frame.headers['message'] ?? 'Live message connection failed.',
              isNetworkError: true,
            ),
          );
          unawaited(disconnect());
          break;
        case 'RECEIPT':
          break;
      }
    }

    Future<void> connect() async {
      try {
        socket = _connector(_webSocketUri());
        socketSubscription = socket!.stream.listen(
          (data) {
            try {
              for (final frame in parser.add(data)) {
                handleFrame(frame);
              }
            } on FormatException {
              addError(
                const ChatMessagesRealtimeException(
                  message: 'Received an invalid live message frame.',
                ),
              );
            }
          },
          onError: (Object _) {
            addError(
              const ChatMessagesRealtimeException(
                message: 'Live message connection failed.',
                isNetworkError: true,
              ),
            );
          },
          onDone: () {
            if (!isCancelled) {
              addError(
                const ChatMessagesRealtimeException(
                  message: 'Live message connection closed.',
                  isNetworkError: true,
                ),
              );
            }
          },
        );

        await socket!.ready.timeout(timeout);

        if (isCancelled) {
          return;
        }

        sendFrame('CONNECT', const {
          'accept-version': '1.2',
          'heart-beat': '0,0',
        });

        connectedTimer = Timer(timeout, () {
          addError(
            const ChatMessagesRealtimeException(
              message: 'Live message connection timed out.',
              isNetworkError: true,
            ),
          );
          unawaited(disconnect());
        });
      } on TimeoutException {
        addError(
          const ChatMessagesRealtimeException(
            message: 'Live message connection timed out.',
            isNetworkError: true,
          ),
        );
        await disconnect();
      } catch (_) {
        addError(
          const ChatMessagesRealtimeException(
            message:
                'Could not connect to live messages. Check that the backend is running.',
            isNetworkError: true,
          ),
        );
        await disconnect();
      }
    }

    controller.onListen = () => unawaited(connect());
    controller.onCancel = () {
      isCancelled = true;
      completeReadyError(
        const ChatMessagesRealtimeException(
          message: 'Live message connection cancelled.',
        ),
      );
      unawaited(disconnect());
    };

    return ChatMessagesRealtimeObservation(
      messages: controller.stream,
      ready: ready.future,
    );
  }

  Uri _webSocketUri() {
    final normalizedBaseUrl = _baseUrl.endsWith('/')
        ? _baseUrl.substring(0, _baseUrl.length - 1)
        : _baseUrl;
    final uri = Uri.parse('$normalizedBaseUrl/ws-stomp');

    return uri.replace(
      scheme: switch (uri.scheme) {
        'https' => 'wss',
        'wss' => 'wss',
        _ => 'ws',
      },
    );
  }
}

class _WebSocketChatMessagesSocket implements ChatMessagesSocket {
  const _WebSocketChatMessagesSocket(this._channel);

  final WebSocketChannel _channel;

  @override
  Stream<dynamic> get stream => _channel.stream;

  @override
  StreamSink<dynamic> get sink => _channel.sink;

  @override
  Future<void> get ready => _channel.ready;
}

ChatMessagesSocket _connectWebSocket(Uri uri) {
  return _WebSocketChatMessagesSocket(WebSocketChannel.connect(uri));
}

String _encodeFrame(String command, Map<String, String> headers) {
  final buffer = StringBuffer(command)..write('\n');

  for (final entry in headers.entries) {
    buffer
      ..write(entry.key)
      ..write(':')
      ..write(entry.value)
      ..write('\n');
  }

  return (buffer
        ..write('\n')
        ..write('\x00'))
      .toString();
}

class _StompFrameParser {
  String _buffer = '';

  List<_StompFrame> add(dynamic data) {
    final text = switch (data) {
      String value => value,
      List<int> value => utf8.decode(value),
      _ => throw const FormatException('Expected text WebSocket data.'),
    };

    _buffer += text;

    final frames = <_StompFrame>[];
    while (true) {
      final terminatorIndex = _buffer.indexOf('\x00');
      if (terminatorIndex == -1) {
        break;
      }

      final rawFrame = _buffer.substring(0, terminatorIndex);
      _buffer = _buffer.substring(terminatorIndex + 1);

      if (rawFrame.trim().isEmpty) {
        continue;
      }

      frames.add(_StompFrame.parse(rawFrame));
    }

    return frames;
  }
}

class _StompFrame {
  const _StompFrame({
    required this.command,
    required this.headers,
    required this.body,
  });

  factory _StompFrame.parse(String rawFrame) {
    var normalized = rawFrame.replaceAll('\r\n', '\n');
    while (normalized.startsWith('\n')) {
      normalized = normalized.substring(1);
    }

    final commandEndIndex = normalized.indexOf('\n');
    if (commandEndIndex == -1) {
      return _StompFrame(
        command: normalized.trim(),
        headers: const {},
        body: '',
      );
    }

    final command = normalized.substring(0, commandEndIndex).trim();
    final remainder = normalized.substring(commandEndIndex + 1);
    final headerEndIndex = remainder.indexOf('\n\n');
    final headerText = headerEndIndex == -1
        ? remainder
        : remainder.substring(0, headerEndIndex);
    final body =
        headerEndIndex == -1 ? '' : remainder.substring(headerEndIndex + 2);

    return _StompFrame(
      command: command,
      headers: _parseHeaders(headerText),
      body: body,
    );
  }

  final String command;
  final Map<String, String> headers;
  final String body;
}

Map<String, String> _parseHeaders(String headerText) {
  final headers = <String, String>{};

  for (final line in headerText.split('\n')) {
    if (line.isEmpty) {
      continue;
    }

    final separatorIndex = line.indexOf(':');
    if (separatorIndex <= 0) {
      continue;
    }

    headers[line.substring(0, separatorIndex)] =
        line.substring(separatorIndex + 1);
  }

  return headers;
}
