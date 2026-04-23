package ru.vrata.backend.infrastructure.mongo.config;

import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.data.mongodb.core.MongoTemplate;
import org.springframework.data.mongodb.core.query.Query;
import org.springframework.stereotype.Component;
import ru.vrata.backend.infrastructure.mongo.document.MongoMigrationRecord;
import ru.vrata.backend.infrastructure.mongo.migration.MongoMigration;

import java.time.Instant;
import java.util.Comparator;
import java.util.List;

@Component
public class MongoMigrationRunner implements ApplicationRunner {
    private final MongoTemplate mongoTemplate;
    private final List<MongoMigration> migrations;

    public MongoMigrationRunner(MongoTemplate mongoTemplate, List<MongoMigration> migrations) {
        this.mongoTemplate = mongoTemplate;
        this.migrations = migrations;
    }

    @Override
    public void run(ApplicationArguments args) {
        ensureMigrationCollectionExist();

        migrations.stream()
                .sorted(Comparator.comparing(MongoMigration::id))
                .forEach(this::applyIfNeeded);
    }

    private void ensureMigrationCollectionExist() {
        if (!mongoTemplate.collectionExists(MongoMigrationRecord.class)) {
            mongoTemplate.createCollection(MongoMigrationRecord.class);
        }
    }

    private void applyIfNeeded(MongoMigration migration) {
        boolean applied = mongoTemplate.exists(Query.query(org.springframework.data.mongodb.core.query.Criteria.where("_id").is(migration.id())),
                MongoMigrationRecord.class
        );
        if (applied) {
            return;
        }

        migration.execute(mongoTemplate);

        mongoTemplate.save(new MongoMigrationRecord(
                migration.id(),
                Instant.now()
        ));
    }
}



