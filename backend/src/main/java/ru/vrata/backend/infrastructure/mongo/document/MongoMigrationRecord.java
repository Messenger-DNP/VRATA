package ru.vrata.backend.infrastructure.mongo.document;

import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.mapping.Document;

import java.time.Instant;

@Document(collection = "schema_migrations")
public record MongoMigrationRecord(
        @Id String id,
        Instant appliedAt
) {
}
