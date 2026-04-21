import 'package:frontend/features/chat_lobby/domain/entities/chat_room.dart';
import 'package:frontend/features/chat_lobby/presentation/state/chat_lobby_submission_status.dart';

const _sentinel = Object();

class CreateChatState {
  const CreateChatState({
    this.status = ChatLobbySubmissionStatus.idle,
    this.nameError,
    this.submissionError,
    this.room,
  });

  final ChatLobbySubmissionStatus status;
  final String? nameError;
  final String? submissionError;
  final ChatRoom? room;

  bool get isLoading => status == ChatLobbySubmissionStatus.loading;
  bool get isSuccess => status == ChatLobbySubmissionStatus.success;
  bool get hasFeedback =>
      status != ChatLobbySubmissionStatus.idle ||
      nameError != null ||
      submissionError != null ||
      room != null;

  CreateChatState copyWith({
    ChatLobbySubmissionStatus? status,
    Object? nameError = _sentinel,
    Object? submissionError = _sentinel,
    Object? room = _sentinel,
  }) {
    return CreateChatState(
      status: status ?? this.status,
      nameError: nameError == _sentinel ? this.nameError : nameError as String?,
      submissionError: submissionError == _sentinel
          ? this.submissionError
          : submissionError as String?,
      room: room == _sentinel ? this.room : room as ChatRoom?,
    );
  }
}
