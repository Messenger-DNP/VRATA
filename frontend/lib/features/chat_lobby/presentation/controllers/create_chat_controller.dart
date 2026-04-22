import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/features/auth/auth_session_provider.dart';
import 'package:frontend/features/chat_lobby/chat_lobby_providers.dart';
import 'package:frontend/features/chat_lobby/domain/entities/chat_lobby_failure.dart';
import 'package:frontend/features/chat_lobby/domain/validation/chat_lobby_form_validator.dart';
import 'package:frontend/features/chat_lobby/presentation/state/chat_lobby_submission_status.dart';
import 'package:frontend/features/chat_lobby/presentation/state/create_chat_state.dart';

final createChatControllerProvider =
    AutoDisposeNotifierProvider<CreateChatController, CreateChatState>(
      CreateChatController.new,
    );

class CreateChatController extends AutoDisposeNotifier<CreateChatState> {
  @override
  CreateChatState build() => const CreateChatState();

  Future<void> submit({required String name}) async {
    if (state.isLoading) {
      return;
    }

    final nameError = _mapValidationError(
      ChatLobbyFormValidator.validateChatName(name),
    );

    if (nameError != null) {
      state = state.copyWith(
        status: ChatLobbySubmissionStatus.failure,
        nameError: nameError,
        submissionError: null,
        room: null,
      );
      return;
    }

    final session = ref.read(authSessionProvider);
    if (session == null) {
      state = const CreateChatState(
        status: ChatLobbySubmissionStatus.failure,
        submissionError: 'Please log in again to create a chat.',
      );
      return;
    }

    state = const CreateChatState(status: ChatLobbySubmissionStatus.loading);

    try {
      final room = await ref
          .read(createChatUseCaseProvider)
          .call(userId: session.userId, name: name);

      state = CreateChatState(
        status: ChatLobbySubmissionStatus.success,
        room: room,
      );
    } on ChatLobbyFailureException catch (exception) {
      state = _mapFailureState(exception.failure);
    } catch (_) {
      state = const CreateChatState(
        status: ChatLobbySubmissionStatus.failure,
        submissionError: 'Something went wrong. Please try again.',
      );
    }
  }

  void onFormChanged() {
    if (!state.hasFeedback) {
      return;
    }

    state = const CreateChatState();
  }

  String? _mapValidationError(ChatLobbyValidationError? error) {
    switch (error) {
      case ChatLobbyValidationError.emptyChatName:
        return 'Please enter a chat name.';
      case ChatLobbyValidationError.chatNameTooShort:
        return 'Chat name must be at least 1 characters.';
      case ChatLobbyValidationError.chatNameTooLong:
        return 'Chat name must be 50 characters or fewer.';
      case null:
      case ChatLobbyValidationError.emptyInviteCode:
      case ChatLobbyValidationError.inviteCodeInvalid:
        return null;
    }
  }

  CreateChatState _mapFailureState(ChatLobbyFailure failure) {
    if (failure is InvalidCredentialsChatLobbyFailure) {
      return const CreateChatState(
        status: ChatLobbySubmissionStatus.failure,
        submissionError: 'Invalid username or password.',
      );
    }

    if (failure is ValidationChatLobbyFailure) {
      final message = _formatMessage(failure.message);

      if (_isNameMessage(message)) {
        return CreateChatState(
          status: ChatLobbySubmissionStatus.failure,
          nameError: message,
        );
      }

      return CreateChatState(
        status: ChatLobbySubmissionStatus.failure,
        submissionError: message,
      );
    }

    if (failure is NetworkChatLobbyFailure) {
      return CreateChatState(
        status: ChatLobbySubmissionStatus.failure,
        submissionError: failure.message,
      );
    }

    if (failure is ServerChatLobbyFailure) {
      return CreateChatState(
        status: ChatLobbySubmissionStatus.failure,
        submissionError: failure.message,
      );
    }

    if (failure is UnknownChatLobbyFailure) {
      return CreateChatState(
        status: ChatLobbySubmissionStatus.failure,
        submissionError: failure.message,
      );
    }

    return const CreateChatState(
      status: ChatLobbySubmissionStatus.failure,
      submissionError: 'Something went wrong. Please try again.',
    );
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

  bool _isNameMessage(String message) {
    final lower = message.toLowerCase();
    return lower.contains('name') || lower.contains('room');
  }
}
