package ru.vrata.backend.api.config;

import org.junit.jupiter.api.Test;
import org.springframework.http.HttpMethod;
import org.springframework.web.cors.CorsConfiguration;
import org.springframework.web.servlet.config.annotation.CorsRegistry;

import java.util.Map;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.junit.jupiter.api.Assertions.assertTrue;

class CorsConfigTest {
    @Test
    void preflightShouldAllowLocalFlutterWebOrigin() throws Exception {
        CorsConfiguration configuration = getConfiguration();

        assertNotNull(configuration);
        assertEquals(
                "http://localhost:58911",
                configuration.checkOrigin("http://localhost:58911")
        );
        assertTrue(
                configuration.checkHttpMethod(HttpMethod.POST).stream()
                        .map(HttpMethod::name)
                        .anyMatch("POST"::equals)
        );
    }

    @Test
    void preflightShouldRejectUnknownOrigin() {
        CorsConfiguration configuration = getConfiguration();

        assertNotNull(configuration);
        assertNull(configuration.checkOrigin("https://example.com"));
    }

    private CorsConfiguration getConfiguration() {
        TestCorsRegistry registry = new TestCorsRegistry();
        new CorsConfig("http://localhost:*,http://127.0.0.1:*").addCorsMappings(registry);
        return registry.configurations().get("/api/**");
    }

    private static final class TestCorsRegistry extends CorsRegistry {
        private Map<String, CorsConfiguration> configurations() {
            return getCorsConfigurations();
        }
    }
}
