import 'package:frontend/features/chat_room/domain/entities/chat_message.dart';

class ChatMessagesObservation {
  const ChatMessagesObservation({
    required this.messages,
    required this.ready,
  });

  final Stream<ChatMessage> messages;
  final Future<void> ready;
}
