class ErrorResponseDto {
  const ErrorResponseDto({
    required this.code,
    required this.message,
    required this.timestamp,
  });

  final String code;
  final String message;
  final DateTime timestamp;

  factory ErrorResponseDto.fromJson(Map<String, dynamic> json) {
    return ErrorResponseDto(
      code: json['code'] as String,
      message: json['message'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }
}
