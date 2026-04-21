import 'package:frontend/features/chat_lobby/data/datasources/chat_lobby_remote_datasource.dart';
import 'package:frontend/features/chat_lobby/data/dto/create_room_request_dto.dart';
import 'package:frontend/features/chat_lobby/data/dto/join_room_request_dto.dart';
import 'package:frontend/features/chat_lobby/data/mappers/chat_room_mapper.dart';
import 'package:frontend/features/chat_lobby/domain/entities/chat_lobby_failure.dart';
import 'package:frontend/features/chat_lobby/domain/entities/chat_room.dart';
import 'package:frontend/features/chat_lobby/domain/repositories/chat_lobby_repository.dart';

class RemoteChatLobbyRepository implements ChatLobbyRepository {
  const RemoteChatLobbyRepository(this._datasource);

  final ChatLobbyRemoteDatasource _datasource;

  @override
  Future<ChatRoom> createChat({
    required int userId,
    required String name,
  }) async {
    try {
      final response = await _datasource.createRoom(
        CreateRoomRequestDto(userId: userId, name: name),
      );

      return response.toDomain();
    } on ChatLobbyRemoteException catch (exception) {
      throw ChatLobbyFailureException(_mapFailure(exception));
    }
  }

  @override
  Future<ChatRoom> joinChat({
    required int userId,
    required String inviteCode,
  }) async {
    try {
      final response = await _datasource.joinRoom(
        JoinRoomRequestDto(userId: userId, inviteCode: inviteCode),
      );

      return response.toDomain();
    } on ChatLobbyRemoteException catch (exception) {
      throw ChatLobbyFailureException(_mapFailure(exception));
    }
  }

  ChatLobbyFailure _mapFailure(ChatLobbyRemoteException exception) {
    if (exception.isNetworkError) {
      return NetworkChatLobbyFailure(exception.message);
    }

    switch (exception.code) {
      case 'INVALID_CREDENTIALS':
        return const InvalidCredentialsChatLobbyFailure();
      case 'ROOM_NOT_FOUND':
        return const RoomNotFoundFailure();
      case 'VALIDATION_ERROR':
        return ValidationChatLobbyFailure(exception.message);
    }

    switch (exception.statusCode) {
      case 400:
        return ValidationChatLobbyFailure(exception.message);
      case 401:
        return const InvalidCredentialsChatLobbyFailure();
      case 404:
        return const RoomNotFoundFailure();
    }

    if (exception.message.isNotEmpty) {
      return ServerChatLobbyFailure(exception.message);
    }

    return const UnknownChatLobbyFailure();
  }
}
