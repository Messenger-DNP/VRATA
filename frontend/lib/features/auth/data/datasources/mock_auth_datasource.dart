import 'dart:async';

import 'package:frontend/features/auth/data/dto/auth_response_dto.dart';
import 'package:frontend/features/auth/data/dto/login_request_dto.dart';
import 'package:frontend/features/auth/data/dto/register_request_dto.dart';

enum MockAuthErrorCode {
  invalidCredentials,
  userAlreadyExists,
}

class MockAuthException implements Exception {
  const MockAuthException(this.code);

  final MockAuthErrorCode code;
}

class MockAuthDatasource {
  MockAuthDatasource({
    this.latency = const Duration(milliseconds: 650),
  });

  final Duration latency;
  final Map<String, _StoredUserRecord> _usersByUsername = {};
  int _nextUserId = 1;

  Future<AuthResponseDto> login(LoginRequestDto request) async {
    await Future<void>.delayed(latency);

    final username = request.username.trim();
    final user = _usersByUsername[username];

    if (user == null || user.password != request.password) {
      throw const MockAuthException(MockAuthErrorCode.invalidCredentials);
    }

    return _createSession(userId: user.userId, username: user.username);
  }

  Future<AuthResponseDto> register(RegisterRequestDto request) async {
    await Future<void>.delayed(latency);

    final username = request.username.trim();

    if (_usersByUsername.containsKey(username)) {
      throw const MockAuthException(MockAuthErrorCode.userAlreadyExists);
    }

    final user = _StoredUserRecord(
      userId: _nextUserId++,
      username: username,
      password: request.password,
    );

    _usersByUsername[username] = user;

    return _createSession(userId: user.userId, username: user.username);
  }

  AuthResponseDto _createSession({
    required int userId,
    required String username,
  }) {
    final now = DateTime.now().toUtc();

    return AuthResponseDto(
      userId: userId,
      username: username,
      tokenType: 'Bearer',
      accessToken: 'mock-token-$userId-${now.microsecondsSinceEpoch}',
      expiresAt: now.add(const Duration(hours: 12)),
    );
  }
}

class _StoredUserRecord {
  const _StoredUserRecord({
    required this.userId,
    required this.username,
    required this.password,
  });

  final int userId;
  final String username;
  final String password;
}
