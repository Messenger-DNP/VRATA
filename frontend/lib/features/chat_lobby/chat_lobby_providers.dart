import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/network/api_config.dart';
import 'package:frontend/features/chat_lobby/data/datasources/chat_lobby_remote_datasource.dart';
import 'package:frontend/features/chat_lobby/data/repositories/remote_chat_lobby_repository.dart';
import 'package:frontend/features/chat_lobby/domain/repositories/chat_lobby_repository.dart';
import 'package:frontend/features/chat_lobby/domain/usecases/create_chat_use_case.dart';
import 'package:frontend/features/chat_lobby/domain/usecases/join_chat_use_case.dart';
import 'package:http/http.dart' as http;

final chatLobbyApiBaseUrlProvider =
    Provider<String>((ref) => ApiConfig.baseUrl);

final chatLobbyHttpClientProvider = Provider<http.Client>((ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return client;
});

final chatLobbyRemoteDatasourceProvider = Provider<ChatLobbyRemoteDatasource>(
  (ref) => ChatLobbyRemoteDatasource(
    client: ref.watch(chatLobbyHttpClientProvider),
    baseUrl: ref.watch(chatLobbyApiBaseUrlProvider),
  ),
);

final chatLobbyRepositoryProvider = Provider<ChatLobbyRepository>(
  (ref) => RemoteChatLobbyRepository(
    ref.watch(chatLobbyRemoteDatasourceProvider),
  ),
);

final createChatUseCaseProvider = Provider<CreateChatUseCase>(
  (ref) => CreateChatUseCase(ref.watch(chatLobbyRepositoryProvider)),
);

final joinChatUseCaseProvider = Provider<JoinChatUseCase>(
  (ref) => JoinChatUseCase(ref.watch(chatLobbyRepositoryProvider)),
);
