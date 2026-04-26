package ru.vrata.backend.infrastructure.mongo.repository;

import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.data.domain.Sort;
import org.springframework.data.mongodb.core.MongoTemplate;
import org.springframework.data.mongodb.core.query.Criteria;
import org.springframework.data.mongodb.core.query.Query;
import org.springframework.stereotype.Repository;
import ru.vrata.backend.domain.model.Message;
import ru.vrata.backend.domain.repository.RoomMessageRepository;
import ru.vrata.backend.infrastructure.kafka.KafkaMessage;
import ru.vrata.backend.infrastructure.mongo.document.MessageDocument;

import java.util.List;

@Repository
@ConditionalOnProperty(name = "app.repository", havingValue = "mongo", matchIfMissing = true)
public class MongoRoomMessageRepository implements RoomMessageRepository {

    private final MongoTemplate mongoTemplate;

    public MongoRoomMessageRepository(MongoTemplate mongoTemplate) {
        this.mongoTemplate = mongoTemplate;
    }

    @Override
    public void saveForRoom(Long roomId, KafkaMessage message) {
        Message domainMessage = Message.from(message);
        MessageDocument document = toDocument(domainMessage);
        mongoTemplate.save(document);
    }

    @Override
    public List<KafkaMessage> findByRoomId(Long roomId) {
        Query query = Query.query(Criteria.where("roomId").is(roomId))
                .with(Sort.by(Sort.Direction.ASC, "timestamp"));

        return mongoTemplate.find(query, MessageDocument.class)
                .stream()
                .map(this::toKafkaMessage)
                .toList();
    }

    private MessageDocument toDocument(Message message) {
        return new MessageDocument(
                message.id(),
                message.roomId(),
                message.userId(),
                message.username(),
                message.content(),
                message.timestamp()
        );
    }

    private KafkaMessage toKafkaMessage(MessageDocument document) {
        return new KafkaMessage(
                document.getId().toString(),
                document.getRoomId(),
                document.getUserId(),
                document.getUsername(),
                document.getContent(),
                document.getTimestamp()
        );
    }
}