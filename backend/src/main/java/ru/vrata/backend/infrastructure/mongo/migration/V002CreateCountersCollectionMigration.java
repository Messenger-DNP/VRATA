package ru.vrata.backend.infrastructure.mongo.migration;

import org.bson.Document;
import org.springframework.data.mongodb.core.MongoTemplate;
import org.springframework.stereotype.Component;

@Component
public class V002CreateCountersCollectionMigration implements MongoMigration {

    @Override
    public String id() {
        return "V002_CREATE_COUNTERS_COLLECTION";
    }

    @Override
    public void execute(MongoTemplate mongoTemplate) {
        if (!mongoTemplate.collectionExists("counters")) {
            mongoTemplate.createCollection("counters");
        }

        insertCounterIfMissing(mongoTemplate, "users");
        insertCounterIfMissing(mongoTemplate, "rooms");
    }

    private void insertCounterIfMissing(MongoTemplate mongoTemplate, String counterId) {
        boolean exists = mongoTemplate.exists(
                org.springframework.data.mongodb.core.query.Query.query(
                        org.springframework.data.mongodb.core.query.Criteria.where("_id").is(counterId)
                ),
                "counters"
        );

        if (exists) {
            return;
        }

        Document counterDocument = new Document();
        counterDocument.put("_id", counterId);
        counterDocument.put("seq", 0L);

        mongoTemplate.getCollection("counters").insertOne(counterDocument);
    }
}
