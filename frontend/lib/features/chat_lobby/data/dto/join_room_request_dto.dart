class JoinRoomRequestDto {
  const JoinRoomRequestDto({
    required this.userId,
    required this.inviteCode,
  });

  final int userId;
  final String inviteCode;

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'inviteCode': inviteCode,
    };
  }
}
