package ru.vrata.backend.infrastructure.mongo.repository;

import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.data.mongodb.core.MongoTemplate;
import org.springframework.data.mongodb.core.query.Criteria;
import org.springframework.data.mongodb.core.query.Query;
import org.springframework.stereotype.Repository;
import ru.vrata.backend.domain.model.User;
import ru.vrata.backend.domain.repository.UserRepository;
import ru.vrata.backend.infrastructure.mongo.document.UserDocument;

import java.util.Optional;

@Repository
@ConditionalOnProperty(name = "app.repository", havingValue = "mongo", matchIfMissing = true)
public class MongoUserRepository implements UserRepository {
    private final MongoTemplate mongoTemplate;

    public MongoUserRepository(MongoTemplate mongoTemplate) {
        this.mongoTemplate = mongoTemplate;
    }

    @Override
    public Optional<User> findById(Long id) {
        UserDocument document = mongoTemplate.findById(id, UserDocument.class);
        return Optional.ofNullable(toDomain(document));
    }

    @Override
    public Optional<User> findByUsername(String username) {
        Query query = Query.query(Criteria.where("username").is(username));
        UserDocument doc = mongoTemplate.findOne(query, UserDocument.class);
        return Optional.ofNullable(toDomain(doc));
    }

    @Override
    public User create(User user) {
        UserDocument document = toDocument(user);
        mongoTemplate.save(document);
        return user;
    }

    private User toDomain(UserDocument document) {
        if (document == null) return null;
        return new User(
                document.getUserId(),
                document.getUsername(),
                document.getPassword()
        );
    }

    private UserDocument toDocument(User user) {
        return new UserDocument(
                user.id(),
                user.username(),
                user.password()
        );
    }
}
