import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/features/auth/auth_session_provider.dart';
import 'package:frontend/features/chat_lobby/chat_lobby_providers.dart';
import 'package:frontend/features/chat_lobby/domain/entities/chat_lobby_failure.dart';
import 'package:frontend/features/chat_lobby/domain/validation/chat_lobby_form_validator.dart';
import 'package:frontend/features/chat_lobby/presentation/state/chat_lobby_submission_status.dart';
import 'package:frontend/features/chat_lobby/presentation/state/join_chat_state.dart';

final joinChatControllerProvider =
    AutoDisposeNotifierProvider<JoinChatController, JoinChatState>(
  JoinChatController.new,
);

class JoinChatController extends AutoDisposeNotifier<JoinChatState> {
  @override
  JoinChatState build() => const JoinChatState();

  Future<void> submit({required String inviteCode}) async {
    final inviteCodeError = _mapValidationError(
      ChatLobbyFormValidator.validateInviteCode(inviteCode),
    );

    if (inviteCodeError != null) {
      state = state.copyWith(
        status: ChatLobbySubmissionStatus.failure,
        inviteCodeError: inviteCodeError,
        submissionError: null,
        room: null,
      );
      return;
    }

    final session = ref.read(authSessionProvider);
    if (session == null) {
      state = const JoinChatState(
        status: ChatLobbySubmissionStatus.failure,
        submissionError: 'Please log in again to join a chat.',
      );
      return;
    }

    state = const JoinChatState(status: ChatLobbySubmissionStatus.loading);

    try {
      final room = await ref.read(joinChatUseCaseProvider).call(
            userId: session.userId,
            inviteCode: inviteCode,
          );

      state = JoinChatState(
        status: ChatLobbySubmissionStatus.success,
        room: room,
      );
    } on ChatLobbyFailureException catch (exception) {
      state = _mapFailureState(exception.failure);
    } catch (_) {
      state = const JoinChatState(
        status: ChatLobbySubmissionStatus.failure,
        submissionError: 'Something went wrong. Please try again.',
      );
    }
  }

  void onFormChanged() {
    if (!state.hasFeedback) {
      return;
    }

    state = const JoinChatState();
  }

  String? _mapValidationError(ChatLobbyValidationError? error) {
    switch (error) {
      case ChatLobbyValidationError.emptyInviteCode:
        return 'Please enter an invite code.';
      case ChatLobbyValidationError.inviteCodeInvalid:
        return 'Invite code must be 6 Latin letters.';
      case null:
      case ChatLobbyValidationError.emptyChatName:
      case ChatLobbyValidationError.chatNameTooShort:
      case ChatLobbyValidationError.chatNameTooLong:
        return null;
    }
  }

  JoinChatState _mapFailureState(ChatLobbyFailure failure) {
    if (failure is RoomNotFoundFailure) {
      return const JoinChatState(
        status: ChatLobbySubmissionStatus.failure,
        inviteCodeError: 'This code was not found. Check the spelling.',
      );
    }

    if (failure is InvalidCredentialsChatLobbyFailure) {
      return const JoinChatState(
        status: ChatLobbySubmissionStatus.failure,
        submissionError: 'Invalid username or password.',
      );
    }

    if (failure is ValidationChatLobbyFailure) {
      final message = _formatMessage(failure.message);

      if (_isInviteCodeMessage(message)) {
        return JoinChatState(
          status: ChatLobbySubmissionStatus.failure,
          inviteCodeError: message,
        );
      }

      return JoinChatState(
        status: ChatLobbySubmissionStatus.failure,
        submissionError: message,
      );
    }

    if (failure is NetworkChatLobbyFailure) {
      return JoinChatState(
        status: ChatLobbySubmissionStatus.failure,
        submissionError: failure.message,
      );
    }

    if (failure is ServerChatLobbyFailure) {
      return JoinChatState(
        status: ChatLobbySubmissionStatus.failure,
        submissionError: failure.message,
      );
    }

    if (failure is UnknownChatLobbyFailure) {
      return JoinChatState(
        status: ChatLobbySubmissionStatus.failure,
        submissionError: failure.message,
      );
    }

    return const JoinChatState(
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

  bool _isInviteCodeMessage(String message) {
    final lower = message.toLowerCase();
    return lower.contains('invite') || lower.contains('code');
  }
}
