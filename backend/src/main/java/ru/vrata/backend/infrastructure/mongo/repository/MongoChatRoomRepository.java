package ru.vrata.backend.infrastructure.mongo.repository;

import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.data.mongodb.core.MongoTemplate;
import org.springframework.data.mongodb.core.query.Criteria;
import org.springframework.data.mongodb.core.query.Query;
import org.springframework.stereotype.Repository;
import ru.vrata.backend.domain.model.ChatRoom;
import ru.vrata.backend.domain.repository.ChatRoomRepository;
import ru.vrata.backend.infrastructure.mongo.document.ChatRoomDocument;

import java.util.HashSet;
import java.util.Optional;
import java.util.Set;

@Repository
@ConditionalOnProperty(name = "app.repository", havingValue = "mongo", matchIfMissing = true)
public class MongoChatRoomRepository implements ChatRoomRepository {

    private final MongoTemplate mongoTemplate;

    public MongoChatRoomRepository(MongoTemplate mongoTemplate) {
        this.mongoTemplate = mongoTemplate;
    }

    @Override
    public Optional<ChatRoom> findById(Long id) {
        ChatRoomDocument document = mongoTemplate.findById(id, ChatRoomDocument.class);
        return Optional.ofNullable(toDomain(document));
    }

    @Override
    public Optional<ChatRoom> findByInviteCode(String inviteCode) {
        try {
            String normalizedCode = ChatRoom.normalizeInviteCode(inviteCode);
            Query query = Query.query(Criteria.where("inviteCode").is(normalizedCode));
            ChatRoomDocument document = mongoTemplate.findOne(query, ChatRoomDocument.class);
            return Optional.ofNullable(toDomain(document));
        } catch (IllegalArgumentException exception) {
            return Optional.empty();
        }
    }

    @Override
    public Optional<ChatRoom> findByUserId(Long userId) {
        Query query = Query.query(Criteria.where("memberIds").is(userId));
        ChatRoomDocument document = mongoTemplate.findOne(query, ChatRoomDocument.class);
        return Optional.ofNullable(toDomain(document));
    }

    @Override
    public boolean isUserInRoom(Long roomId, Long userId) {
        ChatRoomDocument document = mongoTemplate.findById(roomId, ChatRoomDocument.class);
        return document != null
                && document.getMemberIds() != null
                && document.getMemberIds().contains(userId);
    }

    @Override
    public Set<Long> findMemberIdsByRoomId(Long roomId) {
        ChatRoomDocument document = mongoTemplate.findById(roomId, ChatRoomDocument.class);
        if (document == null || document.getMemberIds() == null) {
            return Set.of();
        }
        return Set.copyOf(document.getMemberIds());
    }

    @Override
    public synchronized void addMember(Long roomId, Long userId) {
        ChatRoomDocument document = mongoTemplate.findById(roomId, ChatRoomDocument.class);
        if (document == null) {
            throw new IllegalArgumentException("Room not found");
        }

        removeUserFromCurrentRoomIfNeeded(userId, roomId);

        Set<Long> memberIds = new HashSet<>(document.getMemberIds() == null ? Set.of() : document.getMemberIds());
        memberIds.add(userId);

        mongoTemplate.save(new ChatRoomDocument(
                document.getRoomId(),
                document.getName(),
                document.getInviteCode(),
                memberIds
        ));
    }

    @Override
    public synchronized void removeMember(Long roomId, Long userId) {
        ChatRoomDocument document = mongoTemplate.findById(roomId, ChatRoomDocument.class);
        if (document == null) {
            return;
        }

        Set<Long> memberIds = new HashSet<>(document.getMemberIds() == null ? Set.of() : document.getMemberIds());
        memberIds.remove(userId);

        mongoTemplate.save(new ChatRoomDocument(
                document.getRoomId(),
                document.getName(),
                document.getInviteCode(),
                memberIds
        ));
    }

    @Override
    public boolean hasMembers(Long roomId) {
        ChatRoomDocument document = mongoTemplate.findById(roomId, ChatRoomDocument.class);
        return document != null
                && document.getMemberIds() != null
                && !document.getMemberIds().isEmpty();
    }

    @Override
    public synchronized void deleteRoom(Long roomId) {
        Query query = Query.query(Criteria.where("_id").is(roomId));
        mongoTemplate.remove(query, ChatRoomDocument.class);
    }

    @Override
    public ChatRoom create(ChatRoom chatRoom) {
        ChatRoomDocument document = new ChatRoomDocument(
                chatRoom.id(),
                chatRoom.name(),
                chatRoom.inviteCode(),
                new HashSet<>()
        );
        mongoTemplate.save(document);
        return chatRoom;
    }

    private void removeUserFromCurrentRoomIfNeeded(Long userId, Long targetRoomId) {
        Optional<ChatRoom> currentRoomOptional = findByUserId(userId);
        if (currentRoomOptional.isEmpty()) {
            return;
        }

        Long currentRoomId = currentRoomOptional.get().id();
        if (currentRoomId.equals(targetRoomId)) {
            return;
        }

        ChatRoomDocument currentDocument = mongoTemplate.findById(currentRoomId, ChatRoomDocument.class);
        if (currentDocument == null) {
            return;
        }

        Set<Long> currentMembers = new HashSet<>(
                currentDocument.getMemberIds() == null ? Set.of() : currentDocument.getMemberIds()
        );
        currentMembers.remove(userId);

        mongoTemplate.save(new ChatRoomDocument(
                currentDocument.getRoomId(),
                currentDocument.getName(),
                currentDocument.getInviteCode(),
                currentMembers
        ));
    }

    private ChatRoom toDomain(ChatRoomDocument document) {
        if (document == null) {
            return null;
        }
        return new ChatRoom(
                document.getRoomId(),
                document.getName(),
                document.getInviteCode()
        );
    }
}