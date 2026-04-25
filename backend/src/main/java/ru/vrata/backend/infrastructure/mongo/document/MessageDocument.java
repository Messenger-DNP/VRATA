package ru.vrata.backend.infrastructure.mongo.document;

import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.mapping.Document;

import java.time.Instant;
import java.util.UUID;

// TODO (consumer): use this for storing messages in MongoDB
@Getter
@NoArgsConstructor
@AllArgsConstructor
@Document(collection = "messages")
public class MessageDocument {
    @Id
    private UUID id;
    private Long roomId;
    private Long userId;
    private String username;
    private String content;
    private Instant timestamp;
}
