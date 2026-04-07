package ru.vrata.backend.domain.repository;

import ru.vrata.backend.domain.model.ChatRoom;

import java.util.Optional;

public interface ChatRoomRepository {
    Optional<ChatRoom> findById(Long id);

    Optional<ChatRoom> findByInviteCode(String inviteCode);

    ChatRoom save(ChatRoom chatRoom);
    // TODO (logic): add methods for creating and joining room
}
