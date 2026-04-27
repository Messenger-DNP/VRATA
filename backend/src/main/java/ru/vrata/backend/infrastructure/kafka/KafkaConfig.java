package ru.vrata.backend.infrastructure.kafka;

import com.fasterxml.jackson.core.JsonGenerator;
import com.fasterxml.jackson.core.JsonParser;
import com.fasterxml.jackson.databind.DeserializationContext;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.SerializerProvider;
import com.fasterxml.jackson.databind.module.SimpleModule;
import org.apache.kafka.clients.CommonClientConfigs;
import org.apache.kafka.clients.consumer.ConsumerConfig;
import org.apache.kafka.clients.producer.ProducerConfig;
import org.apache.kafka.common.config.SaslConfigs;
import org.apache.kafka.common.config.SslConfigs;
import org.apache.kafka.common.serialization.StringDeserializer;
import org.apache.kafka.common.serialization.StringSerializer;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.kafka.config.ConcurrentKafkaListenerContainerFactory;
import org.springframework.kafka.core.ConsumerFactory;
import org.springframework.kafka.core.DefaultKafkaConsumerFactory;
import org.springframework.kafka.core.DefaultKafkaProducerFactory;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.kafka.core.ProducerFactory;
import org.springframework.kafka.support.serializer.JsonDeserializer;
import org.springframework.kafka.support.serializer.JsonSerializer;

import java.io.IOException;
import java.time.Instant;
import java.util.HashMap;
import java.util.Map;

@Configuration
public class KafkaConfig {
    @Bean
    public ProducerFactory<String, KafkaMessage> producerFactory(
            @Value("${spring.kafka.bootstrap-servers}") String bootstrapServers,
            @Value("${spring.kafka.properties.security.protocol:${spring.kafka.security.protocol:}}") String securityProtocol,
            @Value("${spring.kafka.properties.sasl.mechanism:${spring.kafka.sasl.mechanism:}}") String saslMechanism,
            @Value("${spring.kafka.properties.sasl.jaas.config:${spring.kafka.sasl.jaas.config:}}") String saslJaasConfig,
            @Value("${spring.kafka.properties.ssl.truststore.location:${spring.kafka.ssl.trust-store-location:}}") String trustStoreLocation,
            @Value("${spring.kafka.properties.ssl.truststore.password:${spring.kafka.ssl.trust-store-password:}}") String trustStorePassword,
            @Value("${spring.kafka.properties.ssl.truststore.type:${spring.kafka.ssl.trust-store-type:}}") String trustStoreType,
            @Value("${spring.kafka.properties.ssl.truststore.certificates:}") String trustStoreCertificates
    ) {
        ObjectMapper objectMapper = kafkaObjectMapper();
        Map<String, Object> config = new HashMap<>();
        config.put(ProducerConfig.BOOTSTRAP_SERVERS_CONFIG, bootstrapServers);
        config.put(ProducerConfig.KEY_SERIALIZER_CLASS_CONFIG, StringSerializer.class);
        config.put(ProducerConfig.VALUE_SERIALIZER_CLASS_CONFIG, JsonSerializer.class);
        applySecurityConfig(
                config,
                securityProtocol,
                saslMechanism,
                saslJaasConfig,
                trustStoreLocation,
                trustStorePassword,
                trustStoreType,
                trustStoreCertificates
        );
        return new DefaultKafkaProducerFactory<>(
                config,
                new StringSerializer(),
                new JsonSerializer<>(objectMapper.copy())
        );
    }

    @Bean
    public KafkaTemplate<String, KafkaMessage> kafkaTemplate(ProducerFactory<String, KafkaMessage> producerFactory) {
        return new KafkaTemplate<>(producerFactory);
    }

    @Bean
    public ConsumerFactory<String, KafkaMessage> consumerFactory(
            @Value("${spring.kafka.bootstrap-servers}") String bootstrapServers,
            @Value("${spring.kafka.consumer.auto-offset-reset:earliest}") String autoOffsetReset,
            @Value("${spring.kafka.consumer.properties.metadata.max.age.ms:5000}") Integer metadataMaxAgeMs,
            @Value("${spring.kafka.properties.security.protocol:${spring.kafka.security.protocol:}}") String securityProtocol,
            @Value("${spring.kafka.properties.sasl.mechanism:${spring.kafka.sasl.mechanism:}}") String saslMechanism,
            @Value("${spring.kafka.properties.sasl.jaas.config:${spring.kafka.sasl.jaas.config:}}") String saslJaasConfig,
            @Value("${spring.kafka.properties.ssl.truststore.location:${spring.kafka.ssl.trust-store-location:}}") String trustStoreLocation,
            @Value("${spring.kafka.properties.ssl.truststore.password:${spring.kafka.ssl.trust-store-password:}}") String trustStorePassword,
            @Value("${spring.kafka.properties.ssl.truststore.type:${spring.kafka.ssl.trust-store-type:}}") String trustStoreType,
            @Value("${spring.kafka.properties.ssl.truststore.certificates:}") String trustStoreCertificates
    ) {
        ObjectMapper objectMapper = kafkaObjectMapper();
        Map<String, Object> config = new HashMap<>();
        config.put(ConsumerConfig.BOOTSTRAP_SERVERS_CONFIG, bootstrapServers);
        config.put(ConsumerConfig.KEY_DESERIALIZER_CLASS_CONFIG, StringDeserializer.class);
        config.put(ConsumerConfig.VALUE_DESERIALIZER_CLASS_CONFIG, JsonDeserializer.class);
        config.put(ConsumerConfig.AUTO_OFFSET_RESET_CONFIG, autoOffsetReset);
        config.put(ConsumerConfig.METADATA_MAX_AGE_CONFIG, metadataMaxAgeMs);
        config.put(JsonDeserializer.TRUSTED_PACKAGES, "ru.vrata.backend.infrastructure.kafka");
        config.put(JsonDeserializer.VALUE_DEFAULT_TYPE, KafkaMessage.class);
        applySecurityConfig(
                config,
                securityProtocol,
                saslMechanism,
                saslJaasConfig,
                trustStoreLocation,
                trustStorePassword,
                trustStoreType,
                trustStoreCertificates
        );
        return new DefaultKafkaConsumerFactory<>(
                config,
                new StringDeserializer(),
                new JsonDeserializer<>(KafkaMessage.class, objectMapper.copy(), false)
        );
    }

    private ObjectMapper kafkaObjectMapper() {
        SimpleModule instantModule = new SimpleModule();
        instantModule.addSerializer(Instant.class, new com.fasterxml.jackson.databind.JsonSerializer<>() {
            @Override
            public void serialize(Instant value, JsonGenerator gen, SerializerProvider serializers) throws IOException {
                gen.writeString(value.toString());
            }
        });
        instantModule.addDeserializer(Instant.class, new com.fasterxml.jackson.databind.JsonDeserializer<>() {
            @Override
            public Instant deserialize(JsonParser p, DeserializationContext ctxt) throws IOException {
                String raw = p.getValueAsString();
                if (raw == null || raw.isBlank()) {
                    return null;
                }
                return Instant.parse(raw);
            }
        });
        return new ObjectMapper().registerModule(instantModule);
    }

    private void applySecurityConfig(
            Map<String, Object> config,
            String securityProtocol,
            String saslMechanism,
            String saslJaasConfig,
            String trustStoreLocation,
            String trustStorePassword,
            String trustStoreType,
            String trustStoreCertificates
    ) {
        putIfPresent(config, CommonClientConfigs.SECURITY_PROTOCOL_CONFIG, securityProtocol);
        putIfPresent(config, SaslConfigs.SASL_MECHANISM, saslMechanism);
        putIfPresent(config, SaslConfigs.SASL_JAAS_CONFIG, saslJaasConfig);
        putIfPresent(config, SslConfigs.SSL_TRUSTSTORE_LOCATION_CONFIG, trustStoreLocation);
        putIfPresent(config, SslConfigs.SSL_TRUSTSTORE_PASSWORD_CONFIG, trustStorePassword);
        putIfPresent(config, SslConfigs.SSL_TRUSTSTORE_TYPE_CONFIG, trustStoreType);
        putIfPresent(config, SslConfigs.SSL_TRUSTSTORE_CERTIFICATES_CONFIG, trustStoreCertificates);
    }

    private void putIfPresent(Map<String, Object> config, String key, String value) {
        if (value != null && !value.isBlank()) {
            config.put(key, value);
        }
    }

    @Bean
    public ConcurrentKafkaListenerContainerFactory<String, KafkaMessage> kafkaListenerContainerFactory(
            ConsumerFactory<String, KafkaMessage> consumerFactory
    ) {
        ConcurrentKafkaListenerContainerFactory<String, KafkaMessage> factory =
                new ConcurrentKafkaListenerContainerFactory<>();
        factory.setConsumerFactory(consumerFactory);
        return factory;
    }
}
