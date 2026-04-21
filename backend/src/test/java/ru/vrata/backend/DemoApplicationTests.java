package ru.vrata.backend;

import org.junit.jupiter.api.Test;
import org.springframework.boot.test.context.SpringBootTest;

@SpringBootTest(properties = {
		"app.message.encryption.key=MDEyMzQ1Njc4OWFiY2RlZg=="
})
class DemoApplicationTests {

	@Test
	void contextLoads() {
	}

}
