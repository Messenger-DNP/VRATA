package ru.vrata.backend;

import org.junit.jupiter.api.Test;
import org.springframework.boot.test.context.SpringBootTest;

@SpringBootTest(properties = "app.mongo.migrations.enabled=false")
class DemoApplicationTests {

	@Test
	void contextLoads() {
	}

}
