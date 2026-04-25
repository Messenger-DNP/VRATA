class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.roomId,
    required this.userId,
    required this.username,
    required this.content,
  });

  final String id;
  final int roomId;
  final int userId;
  final String username;
  final String content;
}
