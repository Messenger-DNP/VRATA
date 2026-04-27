import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/chat_lobby/data/datasources/chat_lobby_remote_datasource.dart';
import 'package:frontend/features/chat_lobby/data/repositories/remote_chat_lobby_repository.dart';
import 'package:frontend/features/chat_lobby/domain/entities/chat_lobby_failure.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('RemoteChatLobbyRepository', () {
    test('posts create room request and maps room response', () async {
      late Uri capturedUri;
      late String capturedBody;

      final repository = _buildRepository(
        MockClient((request) async {
          capturedUri = request.url;
          capturedBody = request.body;

          return http.Response(
            jsonEncode({
              'id': 7,
              'name': 'Project Mars',
              'inviteCode': 'abcdef',
            }),
            201,
          );
        }),
      );

      final room = await repository.createChat(
        userId: 42,
        name: 'Project Mars',
      );

      expect(capturedUri.toString(), 'http://localhost:8080/api/v1/rooms');
      expect(
        jsonDecode(capturedBody),
        {
          'userId': 42,
          'name': 'Project Mars',
        },
      );
      expect(room.id, 7);
      expect(room.name, 'Project Mars');
      expect(room.inviteCode, 'abcdef');
    });

    test('posts join room request and maps room response', () async {
      late Uri capturedUri;
      late String capturedBody;

      final repository = _buildRepository(
        MockClient((request) async {
          capturedUri = request.url;
          capturedBody = request.body;

          return http.Response(
            jsonEncode({
              'id': 7,
              'name': 'Project Mars',
              'inviteCode': 'abcdef',
            }),
            200,
          );
        }),
      );

      final room = await repository.joinChat(
        userId: 42,
        inviteCode: 'AbCdEf',
      );

      expect(
        capturedUri.toString(),
        'http://localhost:8080/api/v1/rooms/join',
      );
      expect(
        jsonDecode(capturedBody),
        {
          'userId': 42,
          'inviteCode': 'AbCdEf',
        },
      );
      expect(room.id, 7);
      expect(room.inviteCode, 'abcdef');
    });

    test('posts leave room request', () async {
      late Uri capturedUri;
      late String capturedBody;

      final repository = _buildRepository(
        MockClient((request) async {
          capturedUri = request.url;
          capturedBody = request.body;
          return http.Response('', 200);
        }),
      );

      await repository.leaveChat(userId: 42);

      expect(
        capturedUri.toString(),
        'http://localhost:8080/api/v1/rooms/leave',
      );
      expect(
        jsonDecode(capturedBody),
        {
          'userId': 42,
        },
      );
    });

    test('maps room not found from backend', () async {
      final repository = _buildRepository(
        MockClient((request) async {
          return http.Response(
            jsonEncode({
              'code': 'ROOM_NOT_FOUND',
              'message': 'Room not found by invite code',
              'timestamp': '2026-04-13T12:00:00Z',
            }),
            404,
          );
        }),
      );

      expect(
        () => repository.joinChat(userId: 42, inviteCode: 'abcdef'),
        throwsA(
          isA<ChatLobbyFailureException>().having(
            (error) => error.failure,
            'failure',
            isA<RoomNotFoundFailure>(),
          ),
        ),
      );
    });

    test('maps invalid credentials backend error', () async {
      final repository = _buildRepository(
        MockClient((request) async {
          return http.Response(
            jsonEncode({
              'code': 'INVALID_CREDENTIALS',
              'message': 'Invalid username or password',
              'timestamp': '2026-04-13T12:00:00Z',
            }),
            401,
          );
        }),
      );

      expect(
        () => repository.createChat(userId: 42, name: 'Project Mars'),
        throwsA(
          isA<ChatLobbyFailureException>().having(
            (error) => error.failure,
            'failure',
            isA<InvalidCredentialsChatLobbyFailure>(),
          ),
        ),
      );
    });

    test('maps validation errors with message', () async {
      final repository = _buildRepository(
        MockClient((request) async {
          return http.Response(
            jsonEncode({
              'code': 'VALIDATION_ERROR',
              'message': 'name length must be at most 100 characters',
              'timestamp': '2026-04-13T12:00:00Z',
            }),
            400,
          );
        }),
      );

      expect(
        () => repository.createChat(userId: 42, name: 'Project Mars'),
        throwsA(
          isA<ChatLobbyFailureException>().having(
            (error) => error.failure,
            'failure',
            isA<ValidationChatLobbyFailure>().having(
              (failure) => failure.message,
              'message',
              'name length must be at most 100 characters',
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
        () => repository.joinChat(userId: 42, inviteCode: 'abcdef'),
        throwsA(
          isA<ChatLobbyFailureException>().having(
            (error) => error.failure,
            'failure',
            isA<NetworkChatLobbyFailure>(),
          ),
        ),
      );
    });
  });
}

RemoteChatLobbyRepository _buildRepository(http.Client client) {
  return RemoteChatLobbyRepository(
    ChatLobbyRemoteDatasource(
      client: client,
      baseUrl: 'http://localhost:8080',
    ),
  );
}
