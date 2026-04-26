import 'package:frontend/features/chat_room/domain/entities/chat_message.dart';

enum ChatMessagesLoadStatus { loading, ready, failure }

class ChatMessagesState {
  const ChatMessagesState({
    this.status = ChatMessagesLoadStatus.loading,
    this.messages = const [],
    this.errorMessage,
    this.sendErrorMessage,
    this.isSending = false,
  });

  static const Object _unset = Object();

  final ChatMessagesLoadStatus status;
  final List<ChatMessage> messages;
  final String? errorMessage;
  final String? sendErrorMessage;
  final bool isSending;

  bool get isInitialLoading =>
      status == ChatMessagesLoadStatus.loading && messages.isEmpty;

  bool get isInitialFailure =>
      status == ChatMessagesLoadStatus.failure && messages.isEmpty;

  bool get isReady => status == ChatMessagesLoadStatus.ready;

  bool get isEmpty => isReady && messages.isEmpty;

  ChatMessagesState copyWith({
    ChatMessagesLoadStatus? status,
    List<ChatMessage>? messages,
    Object? errorMessage = _unset,
    Object? sendErrorMessage = _unset,
    bool? isSending,
  }) {
    return ChatMessagesState(
      status: status ?? this.status,
      messages: messages ?? this.messages,
      errorMessage: identical(errorMessage, _unset)
          ? this.errorMessage
          : errorMessage as String?,
      sendErrorMessage: identical(sendErrorMessage, _unset)
          ? this.sendErrorMessage
          : sendErrorMessage as String?,
      isSending: isSending ?? this.isSending,
    );
  }
}
