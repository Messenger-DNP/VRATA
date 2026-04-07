package ru.vrata.backend.domain.repository.inmemory;

import org.springframework.stereotype.Repository;
import ru.vrata.backend.domain.model.ChatRoom;
import ru.vrata.backend.domain.repository.ChatRoomRepository;

import java.util.Map;
import java.util.Optional;
import java.util.concurrent.ConcurrentHashMap;

@Repository
public class InMemoryChatRoomRepository implements ChatRoomRepository {
    private final Map<Long, ChatRoom> roomsById = new ConcurrentHashMap<>();
    private final Map<String, ChatRoom> roomsByInviteCode = new ConcurrentHashMap<>();

    @Override
    public Optional<ChatRoom> findById(Long id) {
        return Optional.ofNullable(roomsById.get(id));
    }

    @Override
    public Optional<ChatRoom> findByInviteCode(String inviteCode) {
        return Optional.ofNullable(roomsByInviteCode.get(inviteCode));
    }

    @Override
    public ChatRoom save(ChatRoom chatRoom) {
        roomsById.put(chatRoom.id(), chatRoom);
        roomsByInviteCode.put(chatRoom.inviteCode(), chatRoom);
        return chatRoom;
    }
}
