package ru.vrata.backend.domain.repository;

import ru.vrata.backend.domain.model.ChatRoom;

import java.util.Optional;

public interface ChatRoomRepository {
    Optional<ChatRoom> findById(Long id);

    Optional<ChatRoom> findByInviteCode(String inviteCode);

    Optional<ChatRoom> findByUserId(Long userId);

    boolean isUserInRoom(Long roomId, Long userId);

    void addMember(Long roomId, Long userId);

    void removeMember(Long roomId, Long userId);

    boolean hasMembers(Long roomId);

    void deleteRoom(Long roomId);

    ChatRoom create(ChatRoom chatRoom);
}
