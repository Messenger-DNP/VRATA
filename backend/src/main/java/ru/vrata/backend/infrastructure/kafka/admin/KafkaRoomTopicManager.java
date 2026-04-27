package ru.vrata.backend.infrastructure.kafka.admin;

import lombok.extern.slf4j.Slf4j;
import org.apache.kafka.clients.admin.AdminClient;
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
    private static final int DELETE_TOPIC_TIMEOUT_SECONDS = 5;

    private final ObjectProvider<KafkaAdmin> kafkaAdminProvider;

    public KafkaRoomTopicManager(ObjectProvider<KafkaAdmin> kafkaAdminProvider) {
        this.kafkaAdminProvider = kafkaAdminProvider;
    }

    @Override
    public void deleteRoomTopic(Long roomId) {
        if (roomId == null) {
            return;
        }

        KafkaAdmin kafkaAdmin = kafkaAdminProvider.getIfAvailable();
        if (kafkaAdmin == null) {
            log.debug("KafkaAdmin bean is not available, skipping room topic deletion");
            return;
        }

        String topic = "chat-room-" + roomId;
        try (AdminClient adminClient = AdminClient.create(kafkaAdmin.getConfigurationProperties())) {
            adminClient.deleteTopics(List.of(topic))
                    .all()
                    .get(DELETE_TOPIC_TIMEOUT_SECONDS, TimeUnit.SECONDS);
            log.info("Kafka topic deleted: {}", topic);
        } catch (ExecutionException exception) {
            if (exception.getCause() instanceof UnknownTopicOrPartitionException) {
                log.info("Kafka topic does not exist, skipping deletion: {}", topic);
                return;
            }

            log.warn("Failed to delete Kafka topic {}", topic, exception);
        } catch (InterruptedException exception) {
            Thread.currentThread().interrupt();
            log.warn("Interrupted while deleting Kafka topic {}", topic, exception);
        } catch (TimeoutException exception) {
            log.warn("Timeout while deleting Kafka topic {}", topic, exception);
        } catch (Exception exception) {
            log.warn("Unexpected error while deleting Kafka topic {}", topic, exception);
        }
    }
}
