class SendMessageRequestDto {
  const SendMessageRequestDto({
    required this.roomId,
    required this.userId,
    required this.username,
    required this.content,
  });

  final int roomId;
  final int userId;
  final String username;
  final String content;

  Map<String, dynamic> toJson() {
    return {
      'roomId': roomId,
      'userId': userId,
      'username': username,
      'content': content,
    };
  }
}
