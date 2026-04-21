package ru.vrata.backend.infrastructure.crypto;

import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

class MessageCryptoServiceTest {
    private static final String TEST_BASE64_KEY = "MDEyMzQ1Njc4OWFiY2RlZg==";

    @Test
    void encryptAndDecryptShouldReturnOriginalPlaintext() {
        MessageCryptoService service = new MessageCryptoService(TEST_BASE64_KEY);

        String encrypted = service.encrypt("hello-world");
        String decrypted = service.decrypt(encrypted);

        assertNotEquals("hello-world", encrypted);
        assertTrue(encrypted.startsWith("enc:v1:"));
        assertEquals("hello-world", decrypted);
    }

    @Test
    void decryptShouldThrowForMalformedEnvelope() {
        MessageCryptoService service = new MessageCryptoService(TEST_BASE64_KEY);

        assertThrows(IllegalStateException.class, () -> service.decrypt("enc:v1:broken"));
    }

    @Test
    void constructorShouldThrowForInvalidKeyBase64() {
        assertThrows(IllegalStateException.class, () -> new MessageCryptoService("not-base64"));
    }

    @Test
    void constructorShouldThrowForInvalidKeyLength() {
        String oneByteBase64 = "AA==";
        assertThrows(IllegalStateException.class, () -> new MessageCryptoService(oneByteBase64));
    }
}
