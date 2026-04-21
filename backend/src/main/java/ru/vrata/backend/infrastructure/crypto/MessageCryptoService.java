package ru.vrata.backend.infrastructure.crypto;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import javax.crypto.Cipher;
import javax.crypto.spec.GCMParameterSpec;
import javax.crypto.spec.SecretKeySpec;
import java.nio.charset.StandardCharsets;
import java.security.GeneralSecurityException;
import java.security.SecureRandom;
import java.util.Base64;

@Component
public class MessageCryptoService {
    private static final String CIPHER_ALGORITHM = "AES/GCM/NoPadding";
    private static final String KEY_ALGORITHM = "AES";
    private static final int GCM_TAG_LENGTH_BITS = 128;
    private static final int IV_LENGTH_BYTES = 12;
    private static final String ENVELOPE_PREFIX = "enc:v1";

    private final SecretKeySpec secretKey;
    private final SecureRandom secureRandom = new SecureRandom();

    public MessageCryptoService(@Value("${app.message.encryption.key:}") String base64Key) {
        this.secretKey = new SecretKeySpec(parseAndValidateKey(base64Key), KEY_ALGORITHM);
    }

    public String encrypt(String plaintext) {
        if (plaintext == null || plaintext.isBlank()) {
            throw new IllegalArgumentException("plaintext must not be blank");
        }

        byte[] iv = new byte[IV_LENGTH_BYTES];
        secureRandom.nextBytes(iv);

        try {
            Cipher cipher = Cipher.getInstance(CIPHER_ALGORITHM);
            cipher.init(Cipher.ENCRYPT_MODE, secretKey, new GCMParameterSpec(GCM_TAG_LENGTH_BITS, iv));
            byte[] cipherBytes = cipher.doFinal(plaintext.getBytes(StandardCharsets.UTF_8));

            String ivBase64 = Base64.getEncoder().encodeToString(iv);
            String cipherBase64 = Base64.getEncoder().encodeToString(cipherBytes);
            return ENVELOPE_PREFIX + ":" + ivBase64 + ":" + cipherBase64;
        } catch (GeneralSecurityException exception) {
            throw new IllegalStateException("Failed to encrypt message content", exception);
        }
    }

    public String decrypt(String envelope) {
        if (envelope == null || envelope.isBlank()) {
            throw new IllegalArgumentException("encrypted envelope must not be blank");
        }

        String[] parts = envelope.split(":", 4);
        if (parts.length != 4 || !"enc".equals(parts[0]) || !"v1".equals(parts[1])) {
            throw new IllegalStateException("Encrypted envelope has invalid format");
        }

        byte[] iv;
        byte[] cipherBytes;
        try {
            iv = Base64.getDecoder().decode(parts[2]);
            cipherBytes = Base64.getDecoder().decode(parts[3]);
        } catch (IllegalArgumentException exception) {
            throw new IllegalStateException("Encrypted envelope contains invalid base64", exception);
        }

        if (iv.length != IV_LENGTH_BYTES) {
            throw new IllegalStateException("Encrypted envelope IV must be 12 bytes");
        }

        try {
            Cipher cipher = Cipher.getInstance(CIPHER_ALGORITHM);
            cipher.init(Cipher.DECRYPT_MODE, secretKey, new GCMParameterSpec(GCM_TAG_LENGTH_BITS, iv));
            byte[] plaintextBytes = cipher.doFinal(cipherBytes);
            return new String(plaintextBytes, StandardCharsets.UTF_8);
        } catch (GeneralSecurityException exception) {
            throw new IllegalStateException("Failed to decrypt message content", exception);
        }
    }

    private byte[] parseAndValidateKey(String base64Key) {
        if (base64Key == null || base64Key.isBlank()) {
            throw new IllegalStateException("APP_MESSAGE_ENCRYPTION_KEY must be set");
        }

        byte[] decoded;
        try {
            decoded = Base64.getDecoder().decode(base64Key.trim());
        } catch (IllegalArgumentException exception) {
            throw new IllegalStateException("APP_MESSAGE_ENCRYPTION_KEY must be valid base64", exception);
        }

        if (decoded.length != 16 && decoded.length != 24 && decoded.length != 32) {
            throw new IllegalStateException("APP_MESSAGE_ENCRYPTION_KEY must decode to 16, 24, or 32 bytes");
        }
        return decoded;
    }
}
