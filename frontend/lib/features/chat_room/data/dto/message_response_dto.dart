class MessageResponseDto {
  const MessageResponseDto({
    required this.id,
    required this.roomId,
    required this.userId,
    required this.username,
    required this.content,
  });

  factory MessageResponseDto.fromJson(Map<String, dynamic> json) {
    return MessageResponseDto(
      id: _readString(json, 'id'),
      roomId: _readInt(json, 'roomId'),
      userId: _readInt(json, 'userId'),
      username: _readString(json, 'username'),
      content: _readString(json, 'content'),
    );
  }

  final String id;
  final int roomId;
  final int userId;
  final String username;
  final String content;

  static int _readInt(Map<String, dynamic> json, String key) {
    final value = json[key];

    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    throw FormatException('Expected "$key" to be a number.');
  }

  static String _readString(Map<String, dynamic> json, String key) {
    final value = json[key];

    if (value is String) {
      return value;
    }

    throw FormatException('Expected "$key" to be a string.');
  }
}
