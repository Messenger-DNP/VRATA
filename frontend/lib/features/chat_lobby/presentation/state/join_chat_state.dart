import 'package:frontend/features/chat_lobby/domain/entities/chat_room.dart';
import 'package:frontend/features/chat_lobby/presentation/state/chat_lobby_submission_status.dart';

const _sentinel = Object();

class JoinChatState {
  const JoinChatState({
    this.status = ChatLobbySubmissionStatus.idle,
    this.inviteCodeError,
    this.submissionError,
    this.room,
  });

  final ChatLobbySubmissionStatus status;
  final String? inviteCodeError;
  final String? submissionError;
  final ChatRoom? room;

  bool get isLoading => status == ChatLobbySubmissionStatus.loading;
  bool get isSuccess => status == ChatLobbySubmissionStatus.success;
  bool get hasFeedback =>
      status != ChatLobbySubmissionStatus.idle ||
      inviteCodeError != null ||
      submissionError != null ||
      room != null;

  JoinChatState copyWith({
    ChatLobbySubmissionStatus? status,
    Object? inviteCodeError = _sentinel,
    Object? submissionError = _sentinel,
    Object? room = _sentinel,
  }) {
    return JoinChatState(
      status: status ?? this.status,
      inviteCodeError: inviteCodeError == _sentinel
          ? this.inviteCodeError
          : inviteCodeError as String?,
      submissionError: submissionError == _sentinel
          ? this.submissionError
          : submissionError as String?,
      room: room == _sentinel ? this.room : room as ChatRoom?,
    );
  }
}
