import 'dart:async';
import 'dart:convert';

import 'package:frontend/features/auth/data/dto/auth_response_dto.dart';
import 'package:frontend/features/auth/data/dto/error_response_dto.dart';
import 'package:frontend/features/auth/data/dto/login_request_dto.dart';
import 'package:frontend/features/auth/data/dto/register_request_dto.dart';
import 'package:http/http.dart' as http;

class AuthRemoteException implements Exception {
  const AuthRemoteException({
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

class AuthRemoteDatasource {
  const AuthRemoteDatasource({
    required http.Client client,
    required String baseUrl,
    this.timeout = const Duration(seconds: 10),
  })  : _client = client,
        _baseUrl = baseUrl;

  final http.Client _client;
  final String _baseUrl;
  final Duration timeout;

  Future<AuthResponseDto> login(LoginRequestDto request) {
    return _post('/api/v1/auth/login', request.toJson());
  }

  Future<AuthResponseDto> register(RegisterRequestDto request) {
    return _post('/api/v1/auth/register', request.toJson());
  }

  Future<AuthResponseDto> _post(
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
        return AuthResponseDto.fromJson(_decodeJsonMap(response.body));
      }

      throw _mapErrorResponse(response);
    } on TimeoutException {
      throw const AuthRemoteException(
        message: 'Request timed out. Please try again.',
        isNetworkError: true,
      );
    } on http.ClientException {
      throw const AuthRemoteException(
        message:
            'Could not connect to the server. Check that the backend is running.',
        isNetworkError: true,
      );
    } on FormatException {
      throw const AuthRemoteException(
        message: 'Received an invalid response from the server.',
      );
    }
  }

  AuthRemoteException _mapErrorResponse(http.Response response) {
    try {
      final error = ErrorResponseDto.fromJson(_decodeJsonMap(response.body));
      return AuthRemoteException(
        statusCode: response.statusCode,
        code: error.code,
        message: error.message,
      );
    } on FormatException {
      return AuthRemoteException(
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
