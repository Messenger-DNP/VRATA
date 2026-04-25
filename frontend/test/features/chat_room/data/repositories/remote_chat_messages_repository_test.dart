import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/chat_room/data/datasources/chat_messages_remote_datasource.dart';
import 'package:frontend/features/chat_room/data/repositories/remote_chat_messages_repository.dart';
import 'package:frontend/features/chat_room/domain/entities/chat_message_failure.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('RemoteChatMessagesRepository', () {
    test('gets room messages with user id and maps response', () async {
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

      final messages = await repository.loadMessages(roomId: 7, userId: 42);

      expect(
        capturedUri.toString(),
        'http://localhost:8080/api/v1/rooms/7/messages?userId=42',
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
        () => repository.loadMessages(roomId: 7, userId: 42),
        throwsA(
          isA<ChatMessageFailureException>().having(
            (error) => error.failure,
            'failure',
            isA<NetworkChatMessageFailure>(),
          ),
        ),
      );
    });
  });
}

RemoteChatMessagesRepository _buildRepository(http.Client client) {
  return RemoteChatMessagesRepository(
    ChatMessagesRemoteDatasource(
      client: client,
      baseUrl: 'http://localhost:8080',
    ),
  );
}
