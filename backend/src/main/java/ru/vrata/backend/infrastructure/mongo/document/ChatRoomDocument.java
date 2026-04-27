package ru.vrata.backend.infrastructure.mongo.document;

import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.mapping.Document;

import java.util.HashSet;
import java.util.Set;

@Getter
@NoArgsConstructor
@AllArgsConstructor
@Document(collection = "chatrooms")
public class ChatRoomDocument {
    @Id
    private Long roomId;
    private String name;
    private String inviteCode;
    private Set<Long> memberIds = new HashSet<>();
}