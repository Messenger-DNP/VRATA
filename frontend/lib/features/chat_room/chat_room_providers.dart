import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/network/api_config.dart';
import 'package:frontend/features/chat_room/data/datasources/chat_messages_remote_datasource.dart';
import 'package:frontend/features/chat_room/data/repositories/remote_chat_messages_repository.dart';
import 'package:frontend/features/chat_room/domain/repositories/chat_messages_repository.dart';
import 'package:frontend/features/chat_room/domain/usecases/load_chat_messages_use_case.dart';
import 'package:frontend/features/chat_room/domain/usecases/send_chat_message_use_case.dart';
import 'package:http/http.dart' as http;

final chatRoomApiBaseUrlProvider = Provider<String>((ref) => ApiConfig.baseUrl);

final chatRoomHttpClientProvider = Provider<http.Client>((ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return client;
});

final chatMessagesPollingIntervalProvider = Provider<Duration>(
  (ref) => const Duration(milliseconds: 1500),
);

final chatMessagesRemoteDatasourceProvider =
    Provider<ChatMessagesRemoteDatasource>(
  (ref) => ChatMessagesRemoteDatasource(
    client: ref.watch(chatRoomHttpClientProvider),
    baseUrl: ref.watch(chatRoomApiBaseUrlProvider),
  ),
);

final chatMessagesRepositoryProvider = Provider<ChatMessagesRepository>(
  (ref) => RemoteChatMessagesRepository(
    ref.watch(chatMessagesRemoteDatasourceProvider),
  ),
);

final loadChatMessagesUseCaseProvider = Provider<LoadChatMessagesUseCase>(
  (ref) => LoadChatMessagesUseCase(ref.watch(chatMessagesRepositoryProvider)),
);

final sendChatMessageUseCaseProvider = Provider<SendChatMessageUseCase>(
  (ref) => SendChatMessageUseCase(ref.watch(chatMessagesRepositoryProvider)),
);
