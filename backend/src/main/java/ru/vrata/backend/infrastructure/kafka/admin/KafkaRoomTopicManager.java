package ru.vrata.backend.infrastructure.kafka.admin;

import lombok.extern.slf4j.Slf4j;
import org.apache.kafka.clients.admin.AdminClient;
import org.apache.kafka.clients.admin.NewTopic;
import org.apache.kafka.common.errors.TopicExistsException;
import org.apache.kafka.common.errors.UnknownTopicOrPartitionException;
import org.springframework.beans.factory.ObjectProvider;
import org.springframework.kafka.core.KafkaAdmin;
import org.springframework.stereotype.Component;
import ru.vrata.backend.domain.service.RoomTopicManager;

import java.util.List;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.TimeoutException;

@Slf4j
@Component
public class KafkaRoomTopicManager implements RoomTopicManager {
    private static final int ROOM_TOPIC_PARTITIONS = 1;
    private static final short ROOM_TOPIC_REPLICATION_FACTOR = 2;
    private static final int CREATE_TOPIC_TIMEOUT_SECONDS = 30;
    private static final int DELETE_TOPIC_TIMEOUT_SECONDS = 30;
    private static final int DELETE_TOPIC_MAX_ATTEMPTS = 3;

    private final ObjectProvider<KafkaAdmin> kafkaAdminProvider;

    public KafkaRoomTopicManager(ObjectProvider<KafkaAdmin> kafkaAdminProvider) {
        this.kafkaAdminProvider = kafkaAdminProvider;
    }

    @Override
    public void createRoomTopic(Long roomId) {
        if (roomId == null) {
            return;
        }

        KafkaAdmin kafkaAdmin = kafkaAdminProvider.getIfAvailable();
        if (kafkaAdmin == null) {
            throw new IllegalStateException("KafkaAdmin bean is not available, cannot create room topic");
        }

        String topic = topicName(roomId);
        try (AdminClient adminClient = AdminClient.create(kafkaAdmin.getConfigurationProperties())) {
            NewTopic newTopic = new NewTopic(
                    topic,
                    ROOM_TOPIC_PARTITIONS,
                    ROOM_TOPIC_REPLICATION_FACTOR
            );
            adminClient.createTopics(List.of(newTopic))
                    .all()
                    .get(CREATE_TOPIC_TIMEOUT_SECONDS, TimeUnit.SECONDS);
            log.info("Kafka topic created: {}", topic);
        } catch (ExecutionException exception) {
            if (exception.getCause() instanceof TopicExistsException) {
                log.info("Kafka topic already exists, skipping creation: {}", topic);
                return;
            }
            throw new IllegalStateException("Failed to create Kafka topic " + topic, exception);
        } catch (InterruptedException exception) {
            Thread.currentThread().interrupt();
            throw new IllegalStateException("Interrupted while creating Kafka topic " + topic, exception);
        } catch (TimeoutException exception) {
            throw new IllegalStateException("Timeout while creating Kafka topic " + topic, exception);
        } catch (Exception exception) {
            throw new IllegalStateException("Unexpected error while creating Kafka topic " + topic, exception);
        }
    }

    @Override
    public void deleteRoomTopic(Long roomId) {
        if (roomId == null) {
            return;
        }

        KafkaAdmin kafkaAdmin = kafkaAdminProvider.getIfAvailable();
        if (kafkaAdmin == null) {
            log.warn("KafkaAdmin bean is not available, skipping room topic deletion");
            return;
        }

        String topic = topicName(roomId);
        for (int attempt = 1; attempt <= DELETE_TOPIC_MAX_ATTEMPTS; attempt++) {
            try (AdminClient adminClient = AdminClient.create(kafkaAdmin.getConfigurationProperties())) {
                adminClient.deleteTopics(List.of(topic))
                        .all()
                        .get(DELETE_TOPIC_TIMEOUT_SECONDS, TimeUnit.SECONDS);
                log.info("Kafka topic deleted: {}", topic);
                return;
            } catch (ExecutionException exception) {
                if (exception.getCause() instanceof UnknownTopicOrPartitionException) {
                    log.info("Kafka topic does not exist, skipping deletion: {}", topic);
                    return;
                }

                if (attempt == DELETE_TOPIC_MAX_ATTEMPTS) {
                    log.warn("Failed to delete Kafka topic {} after {} attempts", topic, attempt, exception);
                    return;
                }
                log.warn(
                        "Failed to delete Kafka topic {} on attempt {} of {}, retrying",
                        topic,
                        attempt,
                        DELETE_TOPIC_MAX_ATTEMPTS,
                        exception
                );
            } catch (InterruptedException exception) {
                Thread.currentThread().interrupt();
                log.warn("Interrupted while deleting Kafka topic {}", topic, exception);
                return;
            } catch (TimeoutException exception) {
                if (attempt == DELETE_TOPIC_MAX_ATTEMPTS) {
                    log.warn("Timeout while deleting Kafka topic {} after {} attempts", topic, attempt, exception);
                    return;
                }
                log.warn(
                        "Timeout while deleting Kafka topic {} on attempt {} of {}, retrying",
                        topic,
                        attempt,
                        DELETE_TOPIC_MAX_ATTEMPTS,
                        exception
                );
            } catch (Exception exception) {
                if (attempt == DELETE_TOPIC_MAX_ATTEMPTS) {
                    log.warn("Unexpected error while deleting Kafka topic {} after {} attempts", topic, attempt, exception);
                    return;
                }
                log.warn(
                        "Unexpected error while deleting Kafka topic {} on attempt {} of {}, retrying",
                        topic,
                        attempt,
                        DELETE_TOPIC_MAX_ATTEMPTS,
                        exception
                );
            }
        }
    }

    private String topicName(Long roomId) {
        return "chat-room-" + roomId;
    }
}
