import 'dart:async';
import 'dart:convert';

import 'package:frontend/features/chat_lobby/data/dto/create_room_request_dto.dart';
import 'package:frontend/features/chat_lobby/data/dto/error_response_dto.dart';
import 'package:frontend/features/chat_lobby/data/dto/join_room_request_dto.dart';
import 'package:frontend/features/chat_lobby/data/dto/leave_room_request_dto.dart';
import 'package:frontend/features/chat_lobby/data/dto/room_response_dto.dart';
import 'package:http/http.dart' as http;

class ChatLobbyRemoteException implements Exception {
  const ChatLobbyRemoteException({
    this.statusCode,
    this.code,
    required this.message,
    this.isNetworkError = false,
  });

  final int? statusCode;
  final String? code;
  final String message;
  final bool isNetworkError;
}

class ChatLobbyRemoteDatasource {
  const ChatLobbyRemoteDatasource({
    required http.Client client,
    required String baseUrl,
    this.timeout = const Duration(seconds: 10),
  })  : _client = client,
        _baseUrl = baseUrl;

  final http.Client _client;
  final String _baseUrl;
  final Duration timeout;

  Future<RoomResponseDto> createRoom(CreateRoomRequestDto request) {
    return _post('/api/v1/rooms', request.toJson());
  }

  Future<RoomResponseDto> joinRoom(JoinRoomRequestDto request) {
    return _post('/api/v1/rooms/join', request.toJson());
  }

  Future<void> leaveRoom(LeaveRoomRequestDto request) {
    return _postVoid('/api/v1/rooms/leave', request.toJson());
  }

  Future<RoomResponseDto> _post(
    String path,
    Map<String, dynamic> body,
  ) async {
    try {
      final response = await _client
          .post(
            Uri.parse('$_baseUrl$path'),
            headers: const {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
            },
            body: jsonEncode(body),
          )
          .timeout(timeout);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return RoomResponseDto.fromJson(_decodeJsonMap(response.body));
      }

      throw _mapErrorResponse(response);
    } on TimeoutException {
      throw const ChatLobbyRemoteException(
        message: 'Request timed out. Please try again.',
        isNetworkError: true,
      );
    } on http.ClientException {
      throw const ChatLobbyRemoteException(
        message:
            'Could not connect to the server. Check that the backend is running.',
        isNetworkError: true,
      );
    } on FormatException {
      throw const ChatLobbyRemoteException(
        message: 'Received an invalid response from the server.',
      );
    }
  }

  Future<void> _postVoid(
    String path,
    Map<String, dynamic> body,
  ) async {
    try {
      final response = await _client
          .post(
            Uri.parse('$_baseUrl$path'),
            headers: const {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
            },
            body: jsonEncode(body),
          )
          .timeout(timeout);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return;
      }

      throw _mapErrorResponse(response);
    } on TimeoutException {
      throw const ChatLobbyRemoteException(
        message: 'Request timed out. Please try again.',
        isNetworkError: true,
      );
    } on http.ClientException {
      throw const ChatLobbyRemoteException(
        message:
            'Could not connect to the server. Check that the backend is running.',
        isNetworkError: true,
      );
    } on FormatException {
      throw const ChatLobbyRemoteException(
        message: 'Received an invalid response from the server.',
      );
    }
  }

  ChatLobbyRemoteException _mapErrorResponse(http.Response response) {
    try {
      final error = ErrorResponseDto.fromJson(_decodeJsonMap(response.body));
      return ChatLobbyRemoteException(
        statusCode: response.statusCode,
        code: error.code,
        message: error.message,
      );
    } on FormatException {
      return ChatLobbyRemoteException(
        statusCode: response.statusCode,
        message: 'Request failed with status ${response.statusCode}.',
      );
    }
  }

  Map<String, dynamic> _decodeJsonMap(String body) {
    final decoded = jsonDecode(body);

    if (decoded is Map<String, dynamic>) {
      return decoded;
    }

    if (decoded is Map) {
      return decoded.cast<String, dynamic>();
    }

    throw const FormatException('Expected a JSON object.');
  }
}
