package ru.vrata.backend.domain.repository.inmemory;

import org.springframework.stereotype.Repository;
import ru.vrata.backend.domain.model.ChatRoom;
import ru.vrata.backend.domain.repository.ChatRoomRepository;

import java.util.Collections;
import java.util.HashSet;
import java.util.Map;
import java.util.Optional;
import java.util.Set;
import java.util.concurrent.ConcurrentHashMap;

@Repository
public class InMemoryChatRoomRepository implements ChatRoomRepository {
    private final Map<Long, ChatRoom> roomsById = new ConcurrentHashMap<>();
    private final Map<String, ChatRoom> roomsByInviteCode = new ConcurrentHashMap<>();
    private final Map<Long, Set<Long>> membersByRoomId = new ConcurrentHashMap<>();
    private final Map<Long, Long> roomIdByUserId = new ConcurrentHashMap<>();

    @Override
    public Optional<ChatRoom> findById(Long id) {
        return Optional.ofNullable(roomsById.get(id));
    }

    @Override
    public Optional<ChatRoom> findByInviteCode(String inviteCode) {
        try {
            String normalizedCode = ChatRoom.normalizeInviteCode(inviteCode);
            return Optional.ofNullable(roomsByInviteCode.get(normalizedCode));
        } catch (IllegalArgumentException exception) {
            return Optional.empty();
        }
    }

    @Override
    public Optional<ChatRoom> findByUserId(Long userId) {
        Long roomId = roomIdByUserId.get(userId);
        if (roomId == null) {
            return Optional.empty();
        }
        return Optional.ofNullable(roomsById.get(roomId));
    }

    @Override
    public boolean isUserInRoom(Long roomId, Long userId) {
        return roomId.equals(roomIdByUserId.get(userId));
    }

    @Override
    public Set<Long> findMemberIdsByRoomId(Long roomId) {
        return Set.copyOf(membersByRoomId.getOrDefault(roomId, Collections.emptySet()));
    }

    @Override
    public synchronized void addMember(Long roomId, Long userId) {
        requireRoomExists(roomId);

        Long previousRoomId = roomIdByUserId.put(userId, roomId);
        if (previousRoomId != null && !previousRoomId.equals(roomId)) {
            membersByRoomId.computeIfAbsent(previousRoomId, id -> new HashSet<>()).remove(userId);
        }

        membersByRoomId.computeIfAbsent(roomId, id -> new HashSet<>()).add(userId);
    }

    @Override
    public synchronized void removeMember(Long roomId, Long userId) {
        Set<Long> members = membersByRoomId.computeIfAbsent(roomId, id -> new HashSet<>());
        members.remove(userId);
        roomIdByUserId.remove(userId, roomId);
    }

    @Override
    public boolean hasMembers(Long roomId) {
        return !membersByRoomId.getOrDefault(roomId, Collections.emptySet()).isEmpty();
    }

    @Override
    public synchronized void deleteRoom(Long roomId) {
        ChatRoom room = roomsById.remove(roomId);
        if (room != null) {
            roomsByInviteCode.remove(room.inviteCode());
        }

        Set<Long> members = membersByRoomId.remove(roomId);
        if (members != null) {
            for (Long memberId : members) {
                roomIdByUserId.remove(memberId, roomId);
            }
        }
    }

    @Override
    public ChatRoom create(ChatRoom chatRoom) {
        roomsById.put(chatRoom.id(), chatRoom);
        roomsByInviteCode.put(chatRoom.inviteCode(), chatRoom);
        membersByRoomId.computeIfAbsent(chatRoom.id(), id -> new HashSet<>());
        return chatRoom;
    }

    private void requireRoomExists(Long roomId) {
        if (!roomsById.containsKey(roomId)) {
            throw new IllegalArgumentException("Room not found");
        }
    }
}
