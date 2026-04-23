package ru.vrata.backend.infrastructure.mongo.migration;

import org.springframework.data.domain.Sort;
import org.springframework.data.mongodb.core.MongoTemplate;
import org.springframework.data.mongodb.core.index.Index;
import org.springframework.stereotype.Component;

@Component
public class V001CreateBaseIndexesMigration implements MongoMigration {

    @Override
    public String id() {
        return "V001_CREATE_BASE_INDEXES";
    }

    @Override
    public void execute(MongoTemplate mongoTemplate) {
        createCollectionIfMissing(mongoTemplate, "users");
        createCollectionIfMissing(mongoTemplate, "chatrooms");
        createCollectionIfMissing(mongoTemplate, "messages");

        mongoTemplate.indexOps("users")
                .ensureIndex(new Index().on("userId", Sort.Direction.ASC).unique());

        mongoTemplate.indexOps("users")
                .ensureIndex(new Index().on("username", Sort.Direction.ASC).unique());

        mongoTemplate.indexOps("chatrooms")
                .ensureIndex(new Index().on("roomId", Sort.Direction.ASC).unique());

        mongoTemplate.indexOps("chatrooms")
                .ensureIndex(new Index().on("inviteCode", Sort.Direction.ASC).unique());

        mongoTemplate.indexOps("messages")
                .ensureIndex(new Index().on("userId", Sort.Direction.ASC));

        mongoTemplate.indexOps("messages")
                .ensureIndex(new Index().on("roomId", Sort.Direction.ASC));
    }

    private void createCollectionIfMissing(MongoTemplate mongoTemplate, String collectionName) {
        if (!mongoTemplate.collectionExists(collectionName)) {
            mongoTemplate.createCollection(collectionName);
        }
    }
}
