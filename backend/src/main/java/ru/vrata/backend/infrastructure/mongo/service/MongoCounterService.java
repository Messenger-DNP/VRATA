package ru.vrata.backend.infrastructure.mongo.service;

import org.bson.Document;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.data.mongodb.core.FindAndModifyOptions;
import org.springframework.data.mongodb.core.MongoTemplate;
import org.springframework.data.mongodb.core.query.Criteria;
import org.springframework.data.mongodb.core.query.Query;
import org.springframework.data.mongodb.core.query.Update;
import org.springframework.stereotype.Service;

@Service
@ConditionalOnProperty(name = "app.repository", havingValue = "mongo", matchIfMissing = true)
public class MongoCounterService {

    private final MongoTemplate mongoTemplate;

    public MongoCounterService(MongoTemplate mongoTemplate) {
        this.mongoTemplate = mongoTemplate;
    }

    public long nextUserId() {
        return nextSequence("users");
    }

    public long nextRoomId() {
        return nextSequence("rooms");
    }

    private long nextSequence(String counterId) {
        Query query = Query.query(Criteria.where("_id").is(counterId));
        Update update = new Update().inc("seq", 1);

        Document updated = mongoTemplate.findAndModify(
                query,
                update,
                FindAndModifyOptions.options().returnNew(true),
                Document.class,
                "counters"
        );

        if (updated == null || updated.get("seq") == null) {
            throw new IllegalStateException("Counter not found: " + counterId);
        }

        Object value = updated.get("seq");
        if (value instanceof Number number) {
            return number.longValue();
        }

        throw new IllegalStateException("Invalid counter value for: " + counterId);
    }
}