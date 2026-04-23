package ru.vrata.backend.infrastructure.mongo.migration;

import org.springframework.data.mongodb.core.MongoTemplate;

public interface MongoMigration {
    String id();

    void execute(MongoTemplate mongoTemplate);
}