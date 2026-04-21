class ChatRoom {
  const ChatRoom({
    required this.id,
    required this.name,
    required this.inviteCode,
  });

  final int id;
  final String name;
  final String inviteCode;
}
