import 'dart:async';
import 'dart:convert';

import 'package:frontend/features/chat_room/data/dto/error_response_dto.dart';
import 'package:frontend/features/chat_room/data/dto/message_response_dto.dart';
import 'package:frontend/features/chat_room/data/dto/send_message_request_dto.dart';
import 'package:http/http.dart' as http;

class ChatMessagesRemoteException implements Exception {
  const ChatMessagesRemoteException({
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

class ChatMessagesRemoteDatasource {
  const ChatMessagesRemoteDatasource({
    required http.Client client,
    required String baseUrl,
    this.timeout = const Duration(seconds: 10),
  })  : _client = client,
        _baseUrl = baseUrl;

  final http.Client _client;
  final String _baseUrl;
  final Duration timeout;

  Future<List<MessageResponseDto>> getRoomMessages({
    required int roomId,
    required int userId,
  }) async {
    try {
      final uri = Uri.parse(
        '$_baseUrl/api/v1/rooms/$roomId/messages',
      ).replace(queryParameters: {'userId': '$userId'});
      final response = await _client.get(
        uri,
        headers: const {'Accept': 'application/json'},
      ).timeout(timeout);

      if (response.statusCode == 200) {
        return _decodeJsonList(response.body)
            .map(MessageResponseDto.fromJson)
            .toList();
      }

      throw _mapErrorResponse(response);
    } on TimeoutException {
      throw const ChatMessagesRemoteException(
        message: 'Request timed out. Please try again.',
        isNetworkError: true,
      );
    } on http.ClientException {
      throw const ChatMessagesRemoteException(
        message:
            'Could not connect to the server. Check that the backend is running.',
        isNetworkError: true,
      );
    } on FormatException {
      throw const ChatMessagesRemoteException(
        message: 'Received an invalid response from the server.',
      );
    }
  }

  Future<void> sendMessage(SendMessageRequestDto request) async {
    try {
      final response = await _client
          .post(
            Uri.parse('$_baseUrl/api/v1/messages'),
            headers: const {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
            },
            body: jsonEncode(request.toJson()),
          )
          .timeout(timeout);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return;
      }

      throw _mapErrorResponse(response);
    } on TimeoutException {
      throw const ChatMessagesRemoteException(
        message: 'Request timed out. Please try again.',
        isNetworkError: true,
      );
    } on http.ClientException {
      throw const ChatMessagesRemoteException(
        message:
            'Could not connect to the server. Check that the backend is running.',
        isNetworkError: true,
      );
    } on FormatException {
      throw const ChatMessagesRemoteException(
        message: 'Received an invalid response from the server.',
      );
    }
  }

  ChatMessagesRemoteException _mapErrorResponse(http.Response response) {
    try {
      final error = ErrorResponseDto.fromJson(_decodeJsonMap(response.body));
      return ChatMessagesRemoteException(
        statusCode: response.statusCode,
        code: error.code,
        message: error.message,
      );
    } on FormatException {
      return ChatMessagesRemoteException(
        statusCode: response.statusCode,
        message: 'Request failed with status ${response.statusCode}.',
      );
    }
  }

  List<Map<String, dynamic>> _decodeJsonList(String body) {
    final decoded = jsonDecode(body);

    if (decoded is List) {
      return decoded.map((item) {
        if (item is Map<String, dynamic>) {
          return item;
        }

        if (item is Map) {
          return item.cast<String, dynamic>();
        }

        throw const FormatException('Expected a JSON object.');
      }).toList();
    }

    throw const FormatException('Expected a JSON array.');
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
