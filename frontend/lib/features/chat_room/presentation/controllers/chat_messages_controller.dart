import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/features/auth/auth_session_provider.dart';
import 'package:frontend/features/chat_room/chat_room_providers.dart';
import 'package:frontend/features/chat_room/domain/entities/chat_message.dart';
import 'package:frontend/features/chat_room/domain/entities/chat_message_failure.dart';
import 'package:frontend/features/chat_room/presentation/state/chat_messages_state.dart';

final chatMessagesControllerProvider = AutoDisposeNotifierProviderFamily<
    ChatMessagesController, ChatMessagesState, int>(
  ChatMessagesController.new,
);

class ChatMessagesController
    extends AutoDisposeFamilyNotifier<ChatMessagesState, int> {
  static const int maxMessageLength = 2000;
  static const int _maxLiveReconnectAttempts = 3;
  static const Duration _liveReconnectDelay = Duration(seconds: 2);

  late int _roomId;
  StreamSubscription<ChatMessage>? _liveMessagesSubscription;
  Future<void>? _messagesRequest;
  Timer? _liveReconnectTimer;
  int _liveGeneration = 0;
  int _failedLiveGeneration = -1;
  int _liveReconnectAttempts = 0;
  bool _isDisposed = false;

  @override
  ChatMessagesState build(int roomId) {
    _roomId = roomId;
    ref.onDispose(() {
      _isDisposed = true;
      _liveReconnectTimer?.cancel();
      unawaited(_liveMessagesSubscription?.cancel());
    });

    unawaited(Future<void>.microtask(_open));
    return const ChatMessagesState();
  }

  Future<void> refreshMessages() {
    final activeRequest = _messagesRequest;
    if (activeRequest != null) {
      return activeRequest;
    }

    late final Future<void> request;
    request = _refreshMessagesInternal().whenComplete(() {
      if (identical(_messagesRequest, request)) {
        _messagesRequest = null;
      }
    });
    _messagesRequest = request;
    return request;
  }

  Future<bool> sendMessage(String rawContent) async {
    if (state.isSending) {
      return false;
    }

    final content = rawContent.trim();
    if (content.isEmpty) {
      state = state.copyWith(
        sendErrorMessage: 'Please enter a message.',
      );
      return false;
    }

    if (content.length > maxMessageLength) {
      state = state.copyWith(
        sendErrorMessage: 'Message must be 2000 characters or fewer.',
      );
      return false;
    }

    final session = ref.read(authSessionProvider);
    if (session == null) {
      state = state.copyWith(
        sendErrorMessage: 'Please log in again to send messages.',
      );
      return false;
    }

    state = state.copyWith(isSending: true, sendErrorMessage: null);

    try {
      await ref.read(sendChatMessageUseCaseProvider).call(
            roomId: _roomId,
            userId: session.userId,
            username: session.username,
            content: content,
          );

      if (_isDisposed) {
        return false;
      }

      state = state.copyWith(isSending: false, sendErrorMessage: null);
      return true;
    } on ChatMessageFailureException catch (exception) {
      if (!_isDisposed) {
        state = state.copyWith(
          isSending: false,
          sendErrorMessage: _messageForFailure(exception.failure),
        );
      }
      return false;
    } catch (_) {
      if (!_isDisposed) {
        state = state.copyWith(
          isSending: false,
          sendErrorMessage: 'Something went wrong. Please try again.',
        );
      }
      return false;
    }
  }

  Future<void> _open() async {
    if (_isDisposed || ref.read(authSessionProvider) == null) {
      await refreshMessages();
      return;
    }

    final liveReady = _startLiveMessages();
    final liveReadySucceeded =
        liveReady.then((_) => true).catchError((Object _) => false);

    await refreshMessages();

    if (_isDisposed) {
      return;
    }

    if (await liveReadySucceeded && !_isDisposed) {
      await refreshMessages();
    }
  }

  Future<void> _refreshMessagesInternal() async {
    final session = ref.read(authSessionProvider);
    if (session == null) {
      if (!_isDisposed) {
        state = state.copyWith(
          status: ChatMessagesLoadStatus.failure,
          errorMessage: 'Please log in again to view messages.',
        );
      }
      return;
    }

    if (state.messages.isEmpty && !state.isReady) {
      state = state.copyWith(
        status: ChatMessagesLoadStatus.loading,
        errorMessage: null,
      );
    }

    try {
      final receivedMessages = await ref.read(loadChatMessagesUseCaseProvider)(
        roomId: _roomId,
      );

      if (_isDisposed) {
        return;
      }

      state = state.copyWith(
        status: ChatMessagesLoadStatus.ready,
        messages: _mergeNewMessages(state.messages, receivedMessages),
        errorMessage: null,
      );
    } on ChatMessageFailureException catch (exception) {
      if (!_isDisposed) {
        state = _stateForLoadFailure(exception.failure);
      }
    } catch (_) {
      if (!_isDisposed) {
        state = _stateForLoadFailure(const UnknownChatMessageFailure());
      }
    }
  }

  Future<void> _startLiveMessages() {
    _liveReconnectTimer?.cancel();
    _liveReconnectTimer = null;
    final generation = ++_liveGeneration;
    unawaited(_liveMessagesSubscription?.cancel());
    final observation =
        ref.read(observeChatMessagesUseCaseProvider).call(roomId: _roomId);

    _liveMessagesSubscription = observation.messages.listen(
      (message) => _handleLiveMessage(message, generation),
      onError: (Object error) {
        _handleLiveError(error, generation);
      },
    );

    return observation.ready.then((_) {
      if (_isDisposed || generation != _liveGeneration) {
        return;
      }

      _failedLiveGeneration = -1;
      _liveReconnectAttempts = 0;
    }).catchError((Object error, StackTrace stackTrace) {
      _handleLiveError(error, generation);
      Error.throwWithStackTrace(error, stackTrace);
    });
  }

  void _handleLiveMessage(ChatMessage message, int generation) {
    if (_isDisposed ||
        generation != _liveGeneration ||
        message.roomId != _roomId) {
      return;
    }

    final messages = _mergeNewMessages(state.messages, [message]);
    if (identical(messages, state.messages)) {
      return;
    }

    state = state.copyWith(
      status: ChatMessagesLoadStatus.ready,
      messages: messages,
      errorMessage: null,
    );
  }

  void _handleLiveError(Object error, int generation) {
    if (_isDisposed ||
        generation != _liveGeneration ||
        _failedLiveGeneration == generation) {
      return;
    }

    _failedLiveGeneration = generation;
    final failure = error is ChatMessageFailureException
        ? error.failure
        : const UnknownChatMessageFailure();
    state = _stateForLiveFailure(failure);
    unawaited(refreshMessages());
    _scheduleLiveReconnect();
  }

  void _scheduleLiveReconnect() {
    if (_isDisposed ||
        _liveReconnectTimer?.isActive == true ||
        _liveReconnectAttempts >= _maxLiveReconnectAttempts) {
      return;
    }

    _liveReconnectAttempts++;
    _liveReconnectTimer = Timer(_liveReconnectDelay, () {
      if (_isDisposed || ref.read(authSessionProvider) == null) {
        return;
      }

      final liveReady = _startLiveMessages();
      unawaited(liveReady.then((_) => refreshMessages()).catchError((_) {}));
    });
  }

  ChatMessagesState _stateForLoadFailure(ChatMessageFailure failure) {
    final message = _messageForFailure(failure);

    if (state.messages.isEmpty) {
      return state.copyWith(
        status: ChatMessagesLoadStatus.failure,
        errorMessage: message,
      );
    }

    return state.copyWith(
      status: ChatMessagesLoadStatus.ready,
      errorMessage: message,
    );
  }

  ChatMessagesState _stateForLiveFailure(ChatMessageFailure failure) {
    if (state.isInitialLoading || state.isInitialFailure) {
      return _stateForLoadFailure(failure);
    }

    return state.copyWith(
      status: ChatMessagesLoadStatus.ready,
      errorMessage: _messageForFailure(failure),
    );
  }

  String _messageForFailure(ChatMessageFailure failure) {
    if (failure is UnauthorizedChatMessageFailure) {
      return 'Please log in again to continue.';
    }

    if (failure is RoomNotFoundChatMessageFailure) {
      return 'This chat room was not found.';
    }

    if (failure is ValidationChatMessageFailure) {
      return _formatMessage(failure.message);
    }

    if (failure is NetworkChatMessageFailure) {
      return failure.message;
    }

    if (failure is ServerChatMessageFailure) {
      return failure.message;
    }

    if (failure is UnknownChatMessageFailure) {
      return failure.message;
    }

    return 'Something went wrong. Please try again.';
  }

  String _formatMessage(String message) {
    if (message.isEmpty) {
      return 'Something went wrong. Please try again.';
    }

    final normalized = '${message[0].toUpperCase()}${message.substring(1)}';

    if (normalized.endsWith('.')) {
      return normalized;
    }

    return '$normalized.';
  }

  List<ChatMessage> _mergeNewMessages(
    List<ChatMessage> currentMessages,
    List<ChatMessage> receivedMessages,
  ) {
    final seenMessageIds = <String>{};
    final remainingCurrentCounts = <String, int>{};
    for (final message in currentMessages) {
      if (message.id.isNotEmpty) {
        seenMessageIds.add(message.id);
      }

      final key = _messageMergeKey(message);
      remainingCurrentCounts[key] = (remainingCurrentCounts[key] ?? 0) + 1;
    }

    final newMessages = <ChatMessage>[];
    for (final message in receivedMessages) {
      if (message.id.isNotEmpty && seenMessageIds.contains(message.id)) {
        continue;
      }

      if (message.id.isEmpty) {
        final key = _messageMergeKey(message);
        final remainingCount = remainingCurrentCounts[key] ?? 0;

        if (remainingCount > 0) {
          remainingCurrentCounts[key] = remainingCount - 1;
          continue;
        }
      }

      newMessages.add(message);
      if (message.id.isNotEmpty) {
        seenMessageIds.add(message.id);
      }
    }

    if (newMessages.isEmpty) {
      return currentMessages;
    }

    return [...currentMessages, ...newMessages];
  }

  String _messageMergeKey(ChatMessage message) {
    return [
      message.roomId,
      message.userId,
      message.username,
      message.content,
    ].join('\u{1f}');
  }
}
