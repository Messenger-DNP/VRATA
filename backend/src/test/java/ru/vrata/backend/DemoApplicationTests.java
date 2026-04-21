package ru.vrata.backend;

import org.junit.jupiter.api.Test;
import org.springframework.boot.test.context.SpringBootTest;

@SpringBootTest(properties = {
		"app.message.encryption.key=MDEyMzQ1Njc4OWFiY2RlZg==",
		"app.kafka.chat-topic-pattern=^chat-room-[0-9]+$",
		"spring.kafka.listener.auto-startup=false"
})
class DemoApplicationTests {

	@Test
	void contextLoads() {
	}

}
