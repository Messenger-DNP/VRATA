package ru.vrata.backend.infrastructure.mongo.document;

import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.mapping.Document;

@Getter
@NoArgsConstructor
@AllArgsConstructor
@Document(collection = "users")
public class UserDocument {
    @Id
    private Long userId;
    private String username;
    private String password;
}
