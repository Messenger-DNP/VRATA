import 'package:frontend/features/chat_room/data/datasources/chat_messages_remote_datasource.dart';
import 'package:frontend/features/chat_room/data/datasources/chat_messages_realtime_datasource.dart';
import 'package:frontend/features/chat_room/data/dto/send_message_request_dto.dart';
import 'package:frontend/features/chat_room/data/mappers/chat_message_mapper.dart';
import 'package:frontend/features/chat_room/domain/entities/chat_message.dart';
import 'package:frontend/features/chat_room/domain/entities/chat_message_failure.dart';
import 'package:frontend/features/chat_room/domain/entities/chat_messages_observation.dart';
import 'package:frontend/features/chat_room/domain/repositories/chat_messages_repository.dart';

class RemoteChatMessagesRepository implements ChatMessagesRepository {
  const RemoteChatMessagesRepository(
    this._remoteDatasource,
    this._realtimeDatasource,
  );

  final ChatMessagesRemoteDatasource _remoteDatasource;
  final ChatMessagesRealtimeDatasource _realtimeDatasource;

  @override
  Future<List<ChatMessage>> loadMessages({
    required int roomId,
  }) async {
    try {
      final response = await _remoteDatasource.getRoomMessages(
        roomId: roomId,
      );

      return response.map((message) => message.toDomain()).toList();
    } on ChatMessagesRemoteException catch (exception) {
      throw ChatMessageFailureException(_mapFailure(exception));
    }
  }

  @override
  ChatMessagesObservation observeMessages({required int roomId}) {
    final observation = _realtimeDatasource.observeRoomMessages(roomId: roomId);
    final messages = observation.messages
        .map((message) => message.toDomain())
        .handleError((Object error) {
      if (error is ChatMessagesRealtimeException) {
        throw ChatMessageFailureException(_mapRealtimeFailure(error));
      }

      if (error is FormatException) {
        throw const ChatMessageFailureException(
          UnknownChatMessageFailure('Received an invalid live message.'),
        );
      }

      throw error;
    });

    return ChatMessagesObservation(
      messages: messages,
      ready: observation.ready.catchError((Object error) {
        if (error is ChatMessagesRealtimeException) {
          throw ChatMessageFailureException(_mapRealtimeFailure(error));
        }

        throw error;
      }),
    );
  }

  @override
  Future<void> sendMessage({
    required int roomId,
    required int userId,
    required String username,
    required String content,
  }) async {
    try {
      await _remoteDatasource.sendMessage(
        SendMessageRequestDto(
          roomId: roomId,
          userId: userId,
          username: username,
          content: content,
        ),
      );
    } on ChatMessagesRemoteException catch (exception) {
      throw ChatMessageFailureException(_mapFailure(exception));
    }
  }

  ChatMessageFailure _mapFailure(ChatMessagesRemoteException exception) {
    if (exception.isNetworkError) {
      return NetworkChatMessageFailure(exception.message);
    }

    switch (exception.code) {
      case 'INVALID_CREDENTIALS':
        return const UnauthorizedChatMessageFailure();
      case 'ROOM_NOT_FOUND':
        return const RoomNotFoundChatMessageFailure();
      case 'VALIDATION_ERROR':
        return ValidationChatMessageFailure(exception.message);
    }

    switch (exception.statusCode) {
      case 400:
        return ValidationChatMessageFailure(exception.message);
      case 401:
      case 403:
        return const UnauthorizedChatMessageFailure();
      case 404:
        return const RoomNotFoundChatMessageFailure();
    }

    if (exception.message.isNotEmpty) {
      return ServerChatMessageFailure(exception.message);
    }

    return const UnknownChatMessageFailure();
  }

  ChatMessageFailure _mapRealtimeFailure(
    ChatMessagesRealtimeException exception,
  ) {
    if (exception.isNetworkError) {
      return NetworkChatMessageFailure(exception.message);
    }

    if (exception.message.isNotEmpty) {
      return ServerChatMessageFailure(exception.message);
    }

    return const UnknownChatMessageFailure();
  }
}
