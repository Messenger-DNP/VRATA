package ru.vrata.backend.infrastructure.mongo.migration;

import org.springframework.data.domain.Sort;
import org.springframework.data.mongodb.core.MongoTemplate;
import org.springframework.data.mongodb.core.index.Index;
import org.springframework.data.mongodb.core.query.Criteria;
import org.springframework.data.mongodb.core.query.Query;
import org.springframework.data.mongodb.core.query.Update;
import org.springframework.stereotype.Component;

@Component
public class V003AddMessageTimestampMigration implements MongoMigration {

    @Override
    public String id() {
        return "V003_ADD_MESSAGE_TIMESTAMP";
    }

    @Override
    public void execute(MongoTemplate mongoTemplate) {
        Query missingTimestampQuery = Query.query(
                new Criteria().orOperator(
                        Criteria.where("timestamp").exists(false),
                        Criteria.where("timestamp").is(null)
                )
        );

        mongoTemplate.updateMulti(
                missingTimestampQuery,
                new Update().currentDate("timestamp"),
                "messages"
        );

        mongoTemplate.indexOps("messages")
                .ensureIndex(
                        new Index()
                                .on("roomId", Sort.Direction.ASC)
                                .on("timestamp", Sort.Direction.ASC)
                );
    }
}
