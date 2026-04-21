class CreateRoomRequestDto {
  const CreateRoomRequestDto({
    required this.userId,
    required this.name,
  });

  final int userId;
  final String name;

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'name': name,
    };
  }
}
