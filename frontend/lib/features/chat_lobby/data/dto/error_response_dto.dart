class ErrorResponseDto {
  const ErrorResponseDto({
    required this.code,
    required this.message,
  });

  factory ErrorResponseDto.fromJson(Map<String, dynamic> json) {
    return ErrorResponseDto(
      code: _readString(json, 'code'),
      message: _readString(json, 'message'),
    );
  }

  final String code;
  final String message;

  static String _readString(Map<String, dynamic> json, String key) {
    final value = json[key];

    if (value is String) {
      return value;
    }

    throw FormatException('Expected "$key" to be a string.');
  }
}
