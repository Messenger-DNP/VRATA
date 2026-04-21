class RoomResponseDto {
  const RoomResponseDto({
    required this.id,
    required this.name,
    required this.inviteCode,
  });

  factory RoomResponseDto.fromJson(Map<String, dynamic> json) {
    return RoomResponseDto(
      id: _readInt(json, 'id'),
      name: _readString(json, 'name'),
      inviteCode: _readString(json, 'inviteCode'),
    );
  }

  final int id;
  final String name;
  final String inviteCode;

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
